import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({TokenStorage? storage}) : _storage = storage ?? TokenStorage();

  final TokenStorage _storage;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final baseValue = apiBaseUrl();
    final base = baseValue.endsWith('/')
        ? baseValue.substring(0, baseValue.length - 1)
        : baseValue;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    try {
      final body = jsonDecode(res.body);
      throw ApiException(
        body['message']?.toString() ?? 'HTTP ${res.statusCode}',
        statusCode: res.statusCode,
      );
    } catch (_) {
      throw ApiException(
        'HTTP ${res.statusCode}: ${res.body}',
        statusCode: res.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await http.get(_uri(path, query), headers: await _headers());
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await http.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    final res = await http.delete(_uri(path), headers: await _headers());
    _throwIfError(res);
  }
}

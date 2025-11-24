import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? responseBody;
  ApiException(this.message, {this.statusCode, this.responseBody});
  @override
  String toString() => message;
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

  String _friendlyMessage(int status) {
    if (status == 400) return 'Thông tin gửi lên chưa đúng. Vui lòng kiểm tra lại.';
    if (status == 401) return 'Sai thông tin đăng nhập hoặc phiên đã hết hạn. Vui lòng đăng nhập lại.';
    if (status == 403) return 'Bạn chưa có quyền thực hiện thao tác này.';
    if (status == 404) return 'Không tìm thấy dữ liệu phù hợp.';
    if (status == 409) return 'Dữ liệu đã tồn tại hoặc bị trùng lặp. Vui lòng kiểm tra lại.';
    if (status == 429) return 'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.';
    if (status >= 500) return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  void _throwIfError(http.Response res, {bool includeResponseBody = false}) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    try {
      final body = jsonDecode(res.body);
      final msg = (body is Map && body['message'] is String && (body['message'] as String).trim().isNotEmpty)
          ? (() {
              final m = body['message'] as String;
              final s = (body['suggestion'] is String) ? (body['suggestion'] as String) : '';
              return s.isNotEmpty ? '$m ${s}' : m;
            })()
          : _friendlyMessage(res.statusCode);
      throw ApiException(
        msg,
        statusCode: res.statusCode,
        responseBody: includeResponseBody && body is Map ? Map<String, dynamic>.from(body) : null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(_friendlyMessage(res.statusCode), statusCode: res.statusCode);
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
      Map<String, dynamic>? query,
    }) async {
    try {
      final res = await http.get(_uri(path, query), headers: await _headers());
      _throwIfError(res);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        throw e;
      }
      throw ApiException('Rất tiếc, không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.');
    }
    }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool includeErrorResponse = false,
  }) async {
    try {
      final res = await http.post(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body ?? {}),
      );
      _throwIfError(res, includeResponseBody: includeErrorResponse);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        throw e;
      }
      throw ApiException('Rất tiếc, không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.');
    }
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
      Map<String, dynamic>? body,
    }) async {
    try {
      final res = await http.put(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body ?? {}),
      );
      _throwIfError(res);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) {
        throw e;
      }
      throw ApiException('Rất tiếc, không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.');
    }
    }

  Future<void> delete(String path) async {
    try {
      final res = await http.delete(_uri(path), headers: await _headers());
      _throwIfError(res);
    } catch (e) {
      if (e is ApiException) {
        throw e;
      }
      throw ApiException('Rất tiếc, không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.');
    }
  }
}

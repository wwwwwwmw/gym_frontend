import 'package:gym_frontend/core/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'attendance_model.dart';

class AttendanceService {
  final ApiClient api;
  AttendanceService(this.api);

  Future<(List<AttendanceModel>, Map<String, dynamic>)> list({
    String? memberId,
    String? status,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await api.getJson(
      '/api/attendance',
      query: {
        if (memberId != null) 'memberId': memberId,
        if (status != null) 'status': status,
        if (date != null) 'date': date,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final list = (res['attendance'] as List<dynamic>)
        .map((e) => AttendanceModel.fromJson(e))
        .toList();
    return (list, Map<String, dynamic>.from(res['pagination'] ?? {}));
  }

  Future<AttendanceOverview> overviewToday() async {
    final res = await api.getJson('/api/attendance/overview');
    return AttendanceOverview.fromJson(res);
  }

  Future<Map<String, dynamic>> today() async {
    final res = await api.getJson('/api/attendance/today');
    return Map<String, dynamic>.from(res);
  }

  /// ✅ Check-in theo memberId (giữ nguyên)
  Future<AttendanceModel> checkIn(String memberId, {String? note}) async {
    final res = await api.postJson(
      '/api/attendance/checkin',
      body: {
        'memberId': memberId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return AttendanceModel.fromJson(res['attendance']);
  }

  /// ✅ Check-in bằng mã / email / SĐT / id
  /// Gọi tới BE: POST /api/attendance/checkin-by-code
  Future<AttendanceModel> checkInByCode(
    String identifier, {
    String? note,
  }) async {
    final res = await api.postJson(
      '/api/attendance/checkin-by-code',
      body: {
        'identifier': identifier,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return AttendanceModel.fromJson(res['attendance']);
  }

  Future<AttendanceModel> checkOut(String memberId, {String? note}) async {
    final res = await api.postJson(
      '/api/attendance/checkout',
      body: {
        'memberId': memberId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return AttendanceModel.fromJson(res['attendance']);
  }

  /// ✅ Check-in bằng QR: token (JWT) + memberIdentifier (id/email/phone)
  /// Nếu `endpoint` là URL đầy đủ trong QR -> gọi trực tiếp; nếu không -> gọi theo base API.
  Future<AttendanceModel> qrCheckIn({
    required String token,
    required String memberIdentifier,
    String? note,
    String? endpoint,
  }) async {
    if (endpoint != null &&
        (endpoint.startsWith('http://') || endpoint.startsWith('https://'))) {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'memberIdentifier': memberIdentifier,
          if (note != null && note.isNotEmpty) 'note': note,
        }),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
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
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return AttendanceModel.fromJson(json['attendance']);
    }

    final json = await api.postJson(
      '/api/attendance/qr-checkin',
      body: {
        'token': token,
        'memberIdentifier': memberIdentifier,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return AttendanceModel.fromJson(json['attendance']);
  }
}

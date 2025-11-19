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

  /// ✅ Check-in theo memberId (giữ nguyên - dùng cho Admin/PT)
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

  /// ✅ Check-in bằng mã / email / SĐT (giữ nguyên - dùng cho Admin/PT)
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

  /// ✅ QUAN TRỌNG: Hàm này dùng cho Màn hình quét QR của App
  /// Chỉ cần gửi 'token' (mã QR), không cần memberIdentifier
  Future<AttendanceModel> checkInWithQr(String qrToken) async {
    final res = await api.postJson(
      '/api/attendance/qr-checkin', // Route khớp với Backend
      body: {
        'token': qrToken, // Gửi token quét được lên server
      },
    );

    // Server trả về: { message: "...", attendance: {...} }
    if (res['attendance'] == null) {
      throw Exception(res['message'] ?? 'Lỗi không xác định từ server');
    }

    return AttendanceModel.fromJson(res['attendance']);
  }

  // Hàm cũ (giữ lại để tránh lỗi các file khác nếu có dùng, nhưng set optional)
  Future<AttendanceModel> qrCheckIn({
    required String token,
    String? memberIdentifier,
    String? note,
    String? endpoint,
  }) async {
    // Nếu có endpoint riêng (ít dùng)
    if (endpoint != null && endpoint.startsWith('http')) {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          if (memberIdentifier != null) 'memberIdentifier': memberIdentifier,
          if (note != null) 'note': note,
        }),
      );
      if (res.statusCode >= 300) throw ApiException('HTTP ${res.statusCode}');
      final json = jsonDecode(res.body);
      return AttendanceModel.fromJson(json['attendance']);
    }

    // Gọi hàm chuẩn
    return checkInWithQr(token);
  }
}

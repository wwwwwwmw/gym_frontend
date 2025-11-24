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

  /// ✅ CẬP NHẬT QUAN TRỌNG: Trả về Map<String, dynamic> thay vì AttendanceModel
  /// Để lấy được cả 'message', 'type' và 'workoutSummary' từ server
  Future<Map<String, dynamic>> checkInWithQr(String qrToken) async {
    final res = await api.postJson(
      '/api/attendance/qr-checkin',
      body: {
        'token': qrToken,
      },
    );
    // Trả về nguyên gốc response để UI tự xử lý hiển thị
    return res;
  }

  // Hàm cũ (giữ lại để tương thích ngược nếu cần, nhưng ít dùng)
  Future<AttendanceModel> qrCheckIn({
    required String token,
    String? memberIdentifier,
    String? note,
    String? endpoint,
  }) async {
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
      if (res.statusCode >= 300) {
        String msg;
        if (res.statusCode == 400) {
          msg = 'Yêu cầu không hợp lệ';
        } else if (res.statusCode == 401) {
          msg = 'Sai thông tin đăng nhập hoặc phiên đã hết hạn';
        } else if (res.statusCode == 403) {
          msg = 'Bạn không có quyền truy cập';
        } else if (res.statusCode == 404) {
          msg = 'Không tìm thấy dữ liệu';
        } else if (res.statusCode == 429) {
          msg = 'Bạn thao tác quá nhanh. Vui lòng thử lại sau.';
        } else if (res.statusCode >= 500) {
          msg = 'Máy chủ gặp sự cố, vui lòng thử lại.';
        } else {
          msg = 'Có lỗi xảy ra, vui lòng thử lại.';
        }
        throw ApiException(msg, statusCode: res.statusCode);
      }
      final json = jsonDecode(res.body);
      return AttendanceModel.fromJson(json['attendance']);
    }
    
    // Gọi hàm chuẩn và map về Model (chỉ dùng khi cần Model)
    final data = await checkInWithQr(token);
    return AttendanceModel.fromJson(data['attendance']);
  }
}
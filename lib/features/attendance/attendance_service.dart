import 'package:gym_frontend/core/api_client.dart';
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
}

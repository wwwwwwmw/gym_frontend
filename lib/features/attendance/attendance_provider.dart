import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'attendance_model.dart';
import 'attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final _api = ApiClient();
  late final AttendanceService _service = AttendanceService(_api);

  bool loading = false;
  String? error;
  List<AttendanceModel> items = [];
  Map<String, dynamic> pagination = {};
  AttendanceOverview? overview;

  Future<void> fetch({
    String? memberId,
    String? status,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final (list, pg) = await _service.list(
        memberId: memberId,
        status: status,
        date: date,
        page: page,
        limit: limit,
      );
      items = list;
      pagination = pg;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOverview() async {
    try {
      overview = await _service.overviewToday();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> checkIn(String memberId, {String? note}) async {
    try {
      await _service.checkIn(memberId, note: note);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkOut(String memberId, {String? note}) async {
    try {
      await _service.checkOut(memberId, note: note);
      return true;
    } catch (_) {
      return false;
    }
  }
}

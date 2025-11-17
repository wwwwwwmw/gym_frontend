import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'attendance_model.dart';
import 'attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final _api = ApiClient();
  late final AttendanceService _service = AttendanceService(_api);

  bool loading = false;

  /// Lỗi chung (dùng cho màn list / overview)
  String? error;

  /// Lỗi chi tiết của lần thao tác gần nhất (check-in / check-out)
  String? lastErrorMessage;

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

  // ================== ACTIONS ==================

  /// Check-in theo memberId (id trong hệ thống)
  Future<bool> checkIn(String memberId, {String? note}) async {
    try {
      error = null;
      lastErrorMessage = null;
      notifyListeners();

      await _service.checkIn(memberId, note: note);
      return true;
    } catch (e) {
      final msg = _extractErrorMessage(e);
      error = msg;
      lastErrorMessage = msg;
      notifyListeners();
      return false;
    }
  }

  /// Check-in bằng mã / SĐT / email / id tuỳ backend support
  Future<bool> checkInByCode(String identifier, {String? note}) async {
    try {
      error = null;
      lastErrorMessage = null;
      notifyListeners();

      await _service.checkInByCode(identifier, note: note);
      return true;
    } catch (e) {
      final msg = _extractErrorMessage(e);
      error = msg;
      lastErrorMessage = msg;
      notifyListeners();
      return false;
    }
  }

  /// Check-out theo memberId
  Future<bool> checkOut(String memberId, {String? note}) async {
    try {
      error = null;
      lastErrorMessage = null;
      notifyListeners();

      await _service.checkOut(memberId, note: note);
      return true;
    } catch (e) {
      final msg = _extractErrorMessage(e);
      error = msg;
      lastErrorMessage = msg;
      notifyListeners();
      return false;
    }
  }

  // ================== HELPER ==================

  /// Cố gắng lấy message từ response backend, nếu không được thì fallback e.toString()
  String _extractErrorMessage(Object e) {
    try {
      final dynamic ex =
          e; // dùng dynamic để không cần import Dio / ApiException
      final data = ex.response?.data;

      if (data is Map) {
        if (data['message'] is String) return data['message'] as String;
        if (data['error'] is String) return data['error'] as String;
      }
    } catch (_) {
      // ignore parse error
    }
    return e.toString();
  }
}

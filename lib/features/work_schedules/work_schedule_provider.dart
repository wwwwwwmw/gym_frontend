import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'work_schedule_model.dart';
import 'work_schedule_service.dart';

class WorkScheduleProvider extends ChangeNotifier {
  WorkScheduleProvider() : _service = WorkScheduleService(ApiClient());
  final WorkScheduleService _service;

  bool isLoading = false;
  String? error;
  List<WorkScheduleModel> items = [];
  Pagination? pagination;

  // Getter for backward compatibility
  List<WorkScheduleModel> get schedules => items;

  Future<void> fetchMy({
    String? date,
    String? status,
    String? shiftType,
    int page = 1,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final (list, pg) = await _service.listMy(
        date: date,
        status: status,
        shiftType: shiftType,
        page: page,
      );
      items = list;
      pagination = pg;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWorkShift(DateTime date, String shiftType) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _service.registerWorkShift(date, shiftType);
      // Refresh the list after successful registration
      await fetchMy();
    } catch (e) {
      error = e.toString();
      rethrow; // Re-throw to handle in UI
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWorkSchedule(String scheduleId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _service.deleteWorkSchedule(scheduleId);
      // Refresh the list after successful deletion
      await fetchMy();
    } catch (e) {
      error = e.toString();
      rethrow; // Re-throw to handle in UI
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

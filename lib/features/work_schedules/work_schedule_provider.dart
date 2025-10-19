import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'work_schedule_model.dart';
import 'work_schedule_service.dart';

class WorkScheduleProvider extends ChangeNotifier {
  WorkScheduleProvider() : _service = WorkScheduleService(ApiClient());
  final WorkScheduleService _service;

  bool loading = false;
  String? error;
  List<WorkScheduleModel> items = [];
  Pagination? pagination;

  Future<void> fetchMy({
    String? date,
    String? status,
    String? shiftType,
    int page = 1,
  }) async {
    loading = true;
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
      loading = false;
      notifyListeners();
    }
  }
}

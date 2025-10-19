import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'employee_model.dart';
import 'employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  EmployeeProvider() : _service = EmployeeService(ApiClient());
  final EmployeeService _service;

  bool loading = false;
  String? error;
  List<EmployeeModel> items = [];
  Pagination? pagination;

  Future<void> fetch({
    String? search,
    String? status,
    String? position,
    int page = 1,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final (list, pg) = await _service.list(
        search: search,
        status: status,
        position: position,
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

  Future<bool> createOrUpdate({
    String? id,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (id == null) {
        await _service.create(data);
      } else {
        await _service.update(id, data);
      }
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _service.remove(id);
      items.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

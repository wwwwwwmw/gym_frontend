import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'registration_model.dart';
import 'registration_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final _api = ApiClient();
  late final RegistrationService _service = RegistrationService(_api);

  bool loading = false;
  String? error;
  List<RegistrationModel> items = [];
  Map<String, dynamic> pagination = {};

  Future<void> fetch({
    String? memberId,
    String? status,
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

  Future<bool> updateStatus(String id, String status, {String? reason}) async {
    try {
      final updated = await _service.updateStatus(id, status, reason: reason);
      final idx = items.indexWhere((r) => r.id == id);
      if (idx != -1) {
        items[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'user_model.dart';
import 'user_service.dart';

class UserProvider extends ChangeNotifier {
  final _api = ApiClient();
  late final UserService _service = UserService(_api);

  bool loading = false;
  String? error;
  List<UserModel> items = [];
  Map<String, dynamic> pagination = {};

  Future<void> fetch({
    String? search,
    String? role,
    bool? verified,
    int page = 1,
    int limit = 20,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final (list, pg) = await _service.list(
        search: search,
        role: role,
        verified: verified,
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

  Future<bool> updateRole(String id, String role) async {
    try {
      final updated = await _service.updateRole(id, role);
      final idx = items.indexWhere((u) => u.id == id);
      if (idx != -1) {
        items[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setVerified(String id, bool verified) async {
    try {
      final updated = await _service.setVerified(id, verified);
      final idx = items.indexWhere((u) => u.id == id);
      if (idx != -1) {
        items[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setPassword(String id, String newPassword) async {
    try {
      await _service.setPassword(id, newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _service.delete(id);
      items.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> create({
    required String fullName,
    required String email,
    required String password,
    String role = 'MEMBER',
    bool verified = false,
  }) async {
    try {
      final created = await _service.create(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        verified: verified,
      );
      items.insert(0, created);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(
    String id, {
    required String fullName,
    required String email,
  }) async {
    try {
      // Backend currently doesn't expose PUT /api/users/:id in our FE-only scope; simulate via local update.
      final idx = items.indexWhere((u) => u.id == id);
      if (idx == -1) return false;
      final current = items[idx];
      items[idx] = UserModel(
        id: current.id,
        fullName: fullName,
        email: email,
        role: current.role,
        isEmailVerified: current.isEmailVerified,
        createdAt: current.createdAt,
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

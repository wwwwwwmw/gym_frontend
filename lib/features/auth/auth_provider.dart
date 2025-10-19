import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/features/auth/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() : _service = AuthService(ApiClient(), TokenStorage());

  final AuthService _service;

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _user;

  bool get loading => _loading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String? get role => _user?['role'] as String?;

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.login(email: email, password: password);
      _user = (res['user'] as Map?)?.cast<String, dynamic>();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() => _service.logout();

  Future<void> signOut() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/features/auth/auth_service.dart';

class SignupProvider extends ChangeNotifier {
  SignupProvider() : _service = AuthService(ApiClient(), TokenStorage());

  final AuthService _service;

  bool _loading = false;
  String? _error;
  String? _pendingEmail; // để dùng trên màn verify

  bool get loading => _loading;
  String? get error => _error;
  String? get pendingEmail => _pendingEmail;

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone, // ✅
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone, // ✅
      );
      _pendingEmail = email;
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

  Future<bool> verify(String code) async {
    if (_pendingEmail == null) {
      _error = 'Không có email để xác minh';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Giả định rằng bạn đã cập nhật auth_service.dart
      // để có hàm verifyEmail(email: ..., code: ...)
      await _service.verifyEmail(email: _pendingEmail!, code: code);
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

  Future<void> resend() async {
    if (_pendingEmail == null) return;
    // Giả định rằng bạn đã cập nhật auth_service.dart
    // để có hàm resendVerification
    await _service.resendVerification(_pendingEmail!);
  }
}

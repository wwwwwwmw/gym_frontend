import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/features/auth/auth_service.dart';

class SignupProvider extends ChangeNotifier {
  SignupProvider() : _service = AuthService(ApiClient(), TokenStorage());
  final AuthService _service;

  bool loading = false;
  String? error;
  String? pendingEmail; // để dùng trên màn verify

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      pendingEmail = email;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> verify(String code) async {
    if (pendingEmail == null) {
      error = 'Không có email để xác minh';
      notifyListeners();
      return false;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _service.verifyEmail(email: pendingEmail!, code: code);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> resend() async {
    if (pendingEmail == null) return;
    await _service.resendVerification(pendingEmail!);
  }
}

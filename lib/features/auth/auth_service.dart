import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';

class AuthService {
  AuthService(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  // ========== REGISTER ==========
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    await _api.postJson(
      '/api/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      },
    );
  }

  // ========== LOGIN ==========
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.postJson(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    final access = res['accessToken'] as String?;
    final refresh = res['refreshToken'] as String?;
    if (access == null || refresh == null) {
      throw ApiException('Không nhận được token đăng nhập. Vui lòng thử lại.');
    }

    await _storage.saveTokens(access: access, refresh: refresh);
    return res;
  }

  // ========== EMAIL VERIFICATION ==========
  Future<void> resendVerification(String email) async {
    await _api.postJson(
      '/api/auth/resend-verification',
      body: {'email': email},
    );
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _api.postJson(
      '/api/auth/verify-email',
      body: {'email': email, 'code': code},
    );
  }

  // ========== FORGOT PASSWORD ==========
  /// B1: Gửi email để nhận mã OTP
  Future<void> requestPasswordReset(String email) async {
    await _api.postJson(
      '/api/auth/forgot-password',
      body: {'email': email},
    );
  }

  /// B2: Gửi email + mã OTP + mật khẩu mới
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.postJson(
      '/api/auth/reset-password',
      body: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }

  // ========== LOGOUT ==========
  Future<void> logout() async {
    await _storage.clear();
  }
}

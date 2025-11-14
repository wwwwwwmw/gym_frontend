import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';

class AuthService {
  AuthService(this._api, this._storage);
  final ApiClient _api;
  final TokenStorage _storage;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone, // ✅ THÊM DÒNG NÀY
  }) async {
    await _api.postJson(
      '/api/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone, // ✅ THÊM DÒNG NÀY
      },
    );
  }

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
      throw ApiException('Thiếu token trong phản hồi đăng nhập');
    }
    await _storage.saveTokens(access: access, refresh: refresh);
    return res;
  }

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

  Future<void> logout() async {
    await _storage.clear();
  }
}
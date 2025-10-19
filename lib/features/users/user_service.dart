import 'package:gym_frontend/core/api_client.dart';
import 'user_model.dart';

class UserService {
  final ApiClient api;
  UserService(this.api);

  Future<(List<UserModel>, Map<String, dynamic>)> list({
    String? search,
    String? role,
    bool? verified,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await api.getJson(
      '/api/users',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null) 'role': role,
        if (verified != null) 'verified': verified.toString(),
        'page': '$page',
        'limit': '$limit',
      },
    );
    final list = (res['users'] as List<dynamic>)
        .map((e) => UserModel.fromJson(e))
        .toList();
    return (list, Map<String, dynamic>.from(res['pagination'] ?? {}));
  }

  Future<UserModel> getById(String id) async {
    final res = await api.getJson('/api/users/$id');
    return UserModel.fromJson(res);
  }

  Future<UserModel> create({
    required String fullName,
    required String email,
    required String password,
    String role = 'MEMBER',
    bool verified = false,
  }) async {
    final res = await api.postJson(
      '/api/users',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
        'verified': verified,
      },
    );
    return UserModel.fromJson(res['user']);
  }

  Future<UserModel> update(String id, {String? fullName, String? email}) async {
    final res = await api.putJson(
      '/api/users/$id',
      body: {
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
      },
    );
    return UserModel.fromJson(res['user']);
  }

  Future<UserModel> updateRole(String id, String role) async {
    final res = await api.putJson('/api/users/$id/role', body: {'role': role});
    return UserModel.fromJson(res['user']);
  }

  Future<void> setPassword(String id, String newPassword) async {
    await api.putJson(
      '/api/users/$id/password',
      body: {'newPassword': newPassword},
    );
  }

  Future<UserModel> setVerified(String id, bool verified) async {
    final res = await api.putJson(
      '/api/users/$id/verified',
      body: {'verified': verified},
    );
    return UserModel.fromJson(res['user']);
  }

  Future<void> delete(String id) async {
    await api.delete('/api/users/$id');
  }
}

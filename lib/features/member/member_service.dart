import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/member/member_model.dart';

class MemberService {
  final ApiClient _api;

  MemberService(this._api);

  /// Lấy thông tin profile của member hiện tại
  Future<MemberModel> getMyProfile() async {
    final res = await _api.getJson('/api/members/profile');
    return MemberModel.fromMap(res['member'] as Map<String, dynamic>);
  }

  /// Cập nhật profile của member hiện tại
  Future<MemberModel> updateMyProfile(Map<String, dynamic> data) async {
    final res = await _api.putJson('/api/members/profile', body: data);
    return MemberModel.fromMap(res['member'] as Map<String, dynamic>);
  }

  /// Đổi mật khẩu
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _api.putJson(
      '/api/members/change-password',
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  /// Lấy thông tin member theo ID (cho trainer/admin)
  Future<MemberModel> getMemberById(String id) async {
    final res = await _api.getJson('/api/members/$id');
    return MemberModel.fromMap(res['member'] as Map<String, dynamic>);
  }

  /// Lấy danh sách members (cho trainer/admin)
  Future<List<MemberModel>> listMembers({
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final res = await _api.getJson('/api/members', query: query);
    final members = res['members'] as List? ?? [];
    return members
        .map((e) => MemberModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

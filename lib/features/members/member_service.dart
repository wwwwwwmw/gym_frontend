import 'package:gym_frontend/core/api_client.dart';
import 'member_model.dart';

class MemberService {
  MemberService(this._api);
  final ApiClient _api;

  Future<(List<MemberModel>, Pagination)> list({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '/api/members',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final members = ((res['members'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(MemberModel.fromMap)
        .toList();
    final p = res['pagination'] as Map<String, dynamic>?;
    final pg = Pagination(
      page: (p?['page'] ?? 1) as int,
      limit: (p?['limit'] ?? limit) as int,
      total: (p?['total'] ?? members.length) as int,
      pages: (p?['pages'] ?? 1) as int,
    );
    return (members, pg);
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;
  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });
}

import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/packages/package_model.dart';

class PackageService {
  PackageService(this._api);
  final ApiClient _api;

  Future<(List<PackageModel>, Pagination)> list({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '/api/packages',
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(PackageModel.fromMap)
        .toList();
    final p = res['pagination'] as Map<String, dynamic>?;
    final pg = Pagination(
      page: (p?['currentPage'] ?? 1) as int,
      limit: (p?['itemsPerPage'] ?? limit) as int,
      total: (p?['totalItems'] ?? items.length) as int,
      pages: (p?['totalPages'] ?? 1) as int,
    );
    return (items, pg);
  }

  Future<PackageModel> create(Map<String, dynamic> data) async {
    final res = await _api.postJson('/api/packages', body: data);
    return PackageModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  Future<PackageModel> update(String id, Map<String, dynamic> data) async {
    final res = await _api.putJson('/api/packages/$id', body: data);
    return PackageModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await _api.delete('/api/packages/$id');
  }

  Future<PackageModel> getById(String id) async {
    final res = await _api.getJson('/api/packages/$id');
    return PackageModel.fromMap(res['data'] as Map<String, dynamic>);
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

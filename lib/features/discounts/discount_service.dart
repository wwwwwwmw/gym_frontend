import 'package:gym_frontend/core/api_client.dart';
import 'discount_model.dart';

class DiscountService {
  DiscountService(this._api);
  final ApiClient _api;

  Future<(List<DiscountModel>, Pagination)> list({
    String? status,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '/api/discounts',
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(DiscountModel.fromMap)
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

  Future<DiscountModel> create(Map<String, dynamic> data) async {
    final res = await _api.postJson('/api/discounts', body: data);
    return DiscountModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  Future<DiscountModel> update(String id, Map<String, dynamic> data) async {
    final res = await _api.putJson('/api/discounts/$id', body: data);
    return DiscountModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await _api.delete('/api/discounts/$id');
  }

  // Public endpoint: active discounts (no role required)
  Future<List<DiscountModel>> listActivePublic() async {
    final res = await _api.getJson('/api/discounts/public/active');
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(DiscountModel.fromMap)
        .toList();
    return items;
  }

  // Public endpoint: package-specific active discounts (no role required)
  Future<List<DiscountModel>> listActiveForPackage(String? packageId) async {
    final res = await _api.getJson(
      '/api/discounts/public/package-discounts',
      query: packageId != null ? {'packageId': packageId} : {},
    );
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(DiscountModel.fromMap)
        .toList();
    return items;
  }

  // --- THÊM HÀM NÀY ---
  Future<DiscountModel> validate(String code, String packageId) async {
    final res = await _api.postJson(
      '/api/discounts/validate',
      body: {'code': code, 'packageId': packageId},
    );
    return DiscountModel.fromMap(res['data']);
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

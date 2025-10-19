import 'package:gym_frontend/core/api_client.dart';
import 'employee_model.dart';

class EmployeeService {
  EmployeeService(this._api);
  final ApiClient _api;

  Future<(List<EmployeeModel>, Pagination)> list({
    String? search,
    String? status,
    String? position,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '/api/employees',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (position != null && position.isNotEmpty) 'position': position,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(EmployeeModel.fromMap)
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

  Future<EmployeeModel> create(Map<String, dynamic> data) async {
    final res = await _api.postJson('/api/employees', body: data);
    return EmployeeModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  Future<EmployeeModel> update(String id, Map<String, dynamic> data) async {
    final res = await _api.putJson('/api/employees/$id', body: data);
    return EmployeeModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await _api.delete('/api/employees/$id');
  }

  // Member-accessible trainers list
  Future<List<EmployeeModel>> listActiveTrainers() async {
    final res = await _api.getJson('/api/employees/trainers/active');
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(EmployeeModel.fromMap)
        .toList();
    return items;
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

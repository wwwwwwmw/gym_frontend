import 'package:gym_frontend/core/api_client.dart';
import 'work_schedule_model.dart';

class WorkScheduleService {
  WorkScheduleService(this._api);
  final ApiClient _api;

  Future<(List<WorkScheduleModel>, Pagination)> listMy({
    String? date,
    String? status,
    String? shiftType,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '/api/work-schedules/my',
      query: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (status != null && status.isNotEmpty) 'status': status,
        if (shiftType != null && shiftType.isNotEmpty) 'shiftType': shiftType,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(WorkScheduleModel.fromMap)
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

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
    try {
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

      // Check if response is successful
      if (res['success'] == false) {
        throw Exception(res['message']?.toString() ?? 'Không thể tải lịch làm việc');
      }

      // Parse data array
      final dataList = res['data'];
      List<WorkScheduleModel> items = [];
      
      if (dataList is List) {
        items = dataList
            .whereType<Map<String, dynamic>>()
            .map((item) {
              try {
                return WorkScheduleModel.fromMap(item);
              } catch (e) {
                // Log error but continue processing other items
                print('Error parsing work schedule item: $e');
                return null;
              }
            })
            .whereType<WorkScheduleModel>()
            .toList();
      }

      // Parse pagination
      final p = res['pagination'] as Map<String, dynamic>?;
      final pg = Pagination(
        page: p != null 
            ? (p['currentPage'] is int 
                ? p['currentPage'] as int 
                : int.tryParse(p['currentPage']?.toString() ?? '1') ?? 1)
            : page,
        limit: p != null
            ? (p['itemsPerPage'] is int
                ? p['itemsPerPage'] as int
                : int.tryParse(p['itemsPerPage']?.toString() ?? '$limit') ?? limit)
            : limit,
        total: p != null
            ? (p['totalItems'] is int
                ? p['totalItems'] as int
                : int.tryParse(p['totalItems']?.toString() ?? '${items.length}') ?? items.length)
            : items.length,
        pages: p != null
            ? (p['totalPages'] is int
                ? p['totalPages'] as int
                : int.tryParse(p['totalPages']?.toString() ?? '1') ?? 1)
            : 1,
      );

      return (items, pg);
    } catch (e) {
      // Re-throw with more context if needed
      if (e.toString().contains('401') || e.toString().contains('403')) {
        throw Exception('Bạn chưa có quyền xem lịch làm việc này');
      }
      rethrow;
    }
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

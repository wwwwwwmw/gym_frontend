import 'package:gym_frontend/core/api_client.dart';
import 'member_schedule_model.dart';

class MemberScheduleService {
  final ApiClient _api;
  MemberScheduleService(this._api);

  Future<List<MemberScheduleItem>> getSchedule({
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _api.getJson(
      '/api/work-schedules/member/me',
      query: {'from': from.toIso8601String(), 'to': to.toIso8601String()},
    );

    final raw = res['data'] as List? ?? const [];
    return raw
        .map(
          (e) =>
              MemberScheduleItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}

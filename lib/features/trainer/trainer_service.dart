import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/trainer/trainer_model.dart';

class TrainerService {
  final ApiClient _api;

  TrainerService(this._api);

  /// Lấy danh sách trainers đang hoạt động
  Future<List<TrainerModel>> getActiveTrainers() async {
    final Map<String, dynamic> res = await _api.getJson(
      '/api/employees/trainers/active',
    );
    final dynamic raw = res['trainers'] ?? res['data'] ?? res['employees'];
    final List<dynamic> trainers = raw is List ? raw : const [];
    return trainers
        .whereType<Map>()
        .map((e) => TrainerModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}

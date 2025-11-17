import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/trainer/trainer_model.dart';

class TrainerService {
  final ApiClient _api;

  TrainerService(this._api);

  /// Lấy danh sách trainers đang hoạt động
  Future<List<TrainerModel>> getActiveTrainers() async {
    final res = await _api.getJson('/api/employees/trainers/active');
    final trainers =
        res['trainers'] as List? ?? res['employees'] as List? ?? [];
    return trainers
        .map((e) => TrainerModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

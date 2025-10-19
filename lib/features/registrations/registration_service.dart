import 'package:gym_frontend/core/api_client.dart';
import 'registration_model.dart';

class RegistrationService {
  final ApiClient api;
  RegistrationService(this.api);

  Future<(List<RegistrationModel>, Map<String, dynamic>)> list({
    String? memberId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final q = {
      if (memberId != null) 'memberId': memberId,
      if (status != null) 'status': status,
      'page': '$page',
      'limit': '$limit',
    };
    final res = await api.getJson('/api/registrations', query: q);
    final list = (res['registrations'] as List<dynamic>)
        .map((e) => RegistrationModel.fromJson(e))
        .toList();
    return (list, Map<String, dynamic>.from(res['pagination'] ?? {}));
  }

  Future<RegistrationModel> getById(String id) async {
    final res = await api.getJson('/api/registrations/$id');
    return RegistrationModel.fromJson(res);
  }

  Future<RegistrationModel> updateStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    final res = await api.putJson(
      '/api/registrations/$id/status',
      body: {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return RegistrationModel.fromJson(res['registration']);
  }

  // Member self-service endpoints
  Future<RegistrationModel> createSelf({
    required String packageId,
    String? discountId,
    String? trainerId,
    String paymentMethod = 'cash',
    bool prebook = false,
  }) async {
    final res = await api.postJson(
      '/api/registrations/me',
      body: {
        'packageId': packageId,
        if (discountId != null) 'discountId': discountId,
        if (trainerId != null) 'trainerId': trainerId,
        'paymentMethod': paymentMethod,
        if (prebook) 'prebook': true,
      },
    );
    return RegistrationModel.fromJson(res['registration']);
  }

  Future<(List<RegistrationModel>, Map<String, dynamic>)> listSelf({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await api.getJson(
      '/api/registrations/me',
      query: {
        if (status != null) 'status': status,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final list = (res['registrations'] as List<dynamic>)
        .map((e) => RegistrationModel.fromJson(e))
        .toList();
    return (list, Map<String, dynamic>.from(res['pagination'] ?? {}));
  }

  Future<List<RegistrationModel>> getSelfActive() async {
    final res = await api.getJson('/api/registrations/me/active');
    final list = (res['activePackages'] as List<dynamic>)
        .map((e) => RegistrationModel.fromJson(e))
        .toList();
    return list;
  }

  Future<List<Map<String, dynamic>>> listChangeRequests(
    String registrationId,
  ) async {
    final res = await api.getJson(
      '/api/registrations/$registrationId/change-requests',
    );
    final list = (res['requests'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return list;
  }

  Future<Map<String, dynamic>> createChangeRequest(
    String registrationId, {
    DateTime? from,
    required DateTime to,
    String? reason,
  }) async {
    final body = {
      if (from != null) 'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    final res = await api.postJson(
      '/api/registrations/$registrationId/change-requests',
      body: body,
    );
    return Map<String, dynamic>.from(res['request'] as Map);
  }

  Future<RegistrationModel> updateSelfStartDate(String id, DateTime start) async {
    final res = await api.putJson(
      '/api/registrations/me/$id/start-date',
      body: { 'startDate': start.toIso8601String() },
    );
    return RegistrationModel.fromJson(res['registration']);
  }

  // Trainer: list my students (registrations assigned to me)
  Future<(List<RegistrationModel>, Map<String, dynamic>)> listMineAsTrainer({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await api.getJson(
      '/api/registrations/trainer/me',
      query: {
        if (status != null) 'status': status,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final list = (res['registrations'] as List<dynamic>)
        .map((e) => RegistrationModel.fromJson(e))
        .toList();
    return (list, Map<String, dynamic>.from(res['pagination'] ?? {}));
  }
}

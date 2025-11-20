import 'package:gym_frontend/core/api_client.dart';
import 'campaign_model.dart';

class CampaignService {
  CampaignService(this._api);
  final ApiClient _api;

  Future<(List<CampaignModel>, Pagination)> list({
    String? status,
    String? type,
    String? targetAudience,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '/api/campaigns',
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
        if (targetAudience != null && targetAudience.isNotEmpty) 'targetAudience': targetAudience,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(CampaignModel.fromMap)
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

  Future<CampaignModel> create(Map<String, dynamic> data) async {
    final res = await _api.postJson('/api/campaigns', body: data);
    return CampaignModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  Future<CampaignModel> update(String id, Map<String, dynamic> data) async {
    final res = await _api.putJson('/api/campaigns/$id', body: data);
    return CampaignModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await _api.delete('/api/campaigns/$id');
  }

  Future<CampaignModel> getById(String id) async {
    final res = await _api.getJson('/api/campaigns/$id');
    return CampaignModel.fromMap(res['data'] as Map<String, dynamic>);
  }

  // Public endpoints
  Future<List<CampaignModel>> listActive({String? targetAudience}) async {
    final res = await _api.getJson(
      '/api/campaigns/active',
      query: {
        if (targetAudience != null && targetAudience.isNotEmpty) 'targetAudience': targetAudience,
      },
    );
    final items = ((res['data'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(CampaignModel.fromMap)
        .toList();
    return items;
  }

  // Campaign discount management
  Future<CampaignModel> addDiscount(String campaignId, String discountId) async {
    final res = await _api.postJson('/api/campaigns/$campaignId/discounts/$discountId', body: {});
    if (res is Map<String, dynamic> && res.containsKey('data')) {
      return CampaignModel.fromMap(res['data'] as Map<String, dynamic>);
    } else if (res is Map<String, dynamic>) {
      return CampaignModel.fromMap(res);
    } else {
      throw Exception('Invalid response format');
    }
  }

  Future<CampaignModel> removeDiscount(String campaignId, String discountId) async {
    // Delete method returns void, so we need to get the campaign separately
    await _api.delete('/api/campaigns/$campaignId/discounts/$discountId');
    
    // Get the updated campaign
    final updatedCampaign = await getById(campaignId);
    return updatedCampaign;
  }

  // Campaign status management
  Future<CampaignModel> updateStatus(String id, String status) async {
    final res = await _api.putJson('/api/campaigns/$id/status', body: {'status': status});
    if (res is Map<String, dynamic> && res.containsKey('data')) {
      return CampaignModel.fromMap(res['data'] as Map<String, dynamic>);
    } else if (res is Map<String, dynamic>) {
      return CampaignModel.fromMap(res);
    } else {
      throw Exception('Invalid response format');
    }
  }

  // Statistics
  Future<CampaignStatistics> getStatistics() async {
    final res = await _api.getJson('/api/campaigns/statistics');
    return CampaignStatistics.fromMap(res['data'] as Map<String, dynamic>);
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

class CampaignStatistics {
  final List<StatusCount> byStatus;
  final int totalActive;
  final int expiringSoon;
  final int totalActiveDiscounts;

  CampaignStatistics({
    required this.byStatus,
    required this.totalActive,
    required this.expiringSoon,
    required this.totalActiveDiscounts,
  });

  factory CampaignStatistics.fromMap(Map<String, dynamic> m) => CampaignStatistics(
    byStatus: ((m['byStatus'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(StatusCount.fromMap)
        .toList(),
    totalActive: (m['totalActive'] ?? 0) as int,
    expiringSoon: (m['expiringSoon'] ?? 0) as int,
    totalActiveDiscounts: (m['totalActiveDiscounts'] ?? 0) as int,
  );
}

class StatusCount {
  final String status;
  final int count;
  final int totalUsage;

  StatusCount({
    required this.status,
    required this.count,
    required this.totalUsage,
  });

  factory StatusCount.fromMap(Map<String, dynamic> m) => StatusCount(
    status: (m['_id'] ?? '') as String,
    count: (m['count'] ?? 0) as int,
    totalUsage: (m['totalUsage'] ?? 0) as int,
  );
}
import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/campaigns/campaign_model.dart';
import 'discount_model.dart';
import 'discount_service.dart';

// Import CampaignService với alias để tránh conflict
import 'package:gym_frontend/features/campaigns/campaign_service.dart' as campaign;

// Export Pagination từ discount_service
export 'discount_service.dart' show Pagination;

class DiscountProvider extends ChangeNotifier {
  DiscountProvider() 
      : _discountService = DiscountService(ApiClient()),
        _campaignService = campaign.CampaignService(ApiClient());
  
  final DiscountService _discountService;
  final campaign.CampaignService _campaignService;

  bool loading = false;
  String? error;
  List<DiscountModel> items = [];
  List<DiscountModel> activeDiscounts = [];
  List<CampaignModel> activeCampaigns = [];
  Pagination? pagination;

  // User-specific discounts
  List<DiscountModel> userApplicableDiscounts = [];
  List<CampaignModel> userApplicableCampaigns = [];

  Future<void> fetch({String? status, String? type, int page = 1}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final (list, pg) = await _discountService.list(
        status: status,
        type: type,
        page: page,
      );
      items = list;
      pagination = pg;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrUpdate({
    String? id,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (id == null) {
        await _discountService.create(data);
      } else {
        await _discountService.update(id, data);
      }
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _discountService.remove(id);
      items.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchActiveDiscounts() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final discounts = await _discountService.listActivePublic();
      activeDiscounts = discounts.where((d) => d.isAvailable).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActiveCampaigns() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final campaigns = await _campaignService.listActive();
      activeCampaigns = campaigns.where((c) => c.isAvailable).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveDiscounts() async {
    await Future.wait([
      fetchActiveDiscounts(),
      fetchActiveCampaigns(),
    ]);
  }

  Future<void> fetchUserApplicableDiscounts(String userId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // Get auto-apply discounts for user
      final autoApplyDiscounts = activeDiscounts.where((d) => d.isAutoApply).toList();
      
      // Get campaigns for user
      final userCampaigns = await _campaignService.listActive(
        targetAudience: _getUserTargetAudience(userId),
      );
      
      userApplicableDiscounts = autoApplyDiscounts;
      userApplicableCampaigns = userCampaigns.where((c) => c.isAvailable).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<DiscountModel?> validateDiscountCode(String code) async {
    try {
      // First check in active discounts
      final discount = activeDiscounts.firstWhere(
        (d) => d.code.toUpperCase() == code.toUpperCase() && d.isAvailable,
        orElse: () => throw Exception('Mã khuyến mãi không tồn tại hoặc đã hết hạn'),
      );
      
      return discount;
    } catch (e) {
      // If not found in discounts, check campaigns
      try {
        // Find discount in campaigns
        for (final campaign in activeCampaigns) {
          // This would require additional API call to get campaign discounts
          // For now, throw the original error
        }
        throw Exception('Mã khuyến mãi không hợp lệ hoặc đã hết hạn');
      } catch (_) {
        rethrow;
      }
    }
  }

  String _getUserTargetAudience(String userId) {
    // This would need user profile data to determine target audience
    // For now, return 'all' as default
    return 'all';
  }

  // Get best available discount for a package
  DiscountModel? getBestDiscountForPackage(String packageId, {String? userId}) {
    final applicableDiscounts = activeDiscounts.where((discount) {
      return discount.isAvailable &&
             (discount.applicablePackageIds.isEmpty || 
              discount.applicablePackageIds.contains(packageId));
    }).toList();

    if (applicableDiscounts.isEmpty) return null;

    // Sort by priority (higher priority first) and then by value
    applicableDiscounts.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return b.value.compareTo(a.value);
    });

    return applicableDiscounts.first;
  }

  // Clear selections
  void clearSelections() {
    userApplicableDiscounts.clear();
    userApplicableCampaigns.clear();
    notifyListeners();
  }
}

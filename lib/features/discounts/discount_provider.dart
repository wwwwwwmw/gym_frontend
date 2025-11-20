import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'discount_model.dart';
import 'discount_service.dart';

// Export Pagination từ discount_service
export 'discount_service.dart' show Pagination;

class DiscountProvider extends ChangeNotifier {
  DiscountProvider() : _discountService = DiscountService(ApiClient());

  final DiscountService _discountService;

  bool loading = false;
  String? error;
  List<DiscountModel> items = [];
  List<DiscountModel> activeDiscounts = [];
  Pagination? pagination;

  // User-specific discounts
  List<DiscountModel> userApplicableDiscounts = [];

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

  Future<void> fetchActiveDiscountsForPackage(String? packageId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // Thử lấy mã cho gói cụ thể trước
      final packageDiscounts = await _discountService.listActiveForPackage(
        packageId,
      );
      final availablePackageDiscounts = packageDiscounts
          .where((d) => d.isAvailable)
          .toList();

      if (availablePackageDiscounts.isEmpty) {
        // Nếu không có mã nào cho gói cụ thể, lấy tất cả mã đang hoạt động
        final allDiscounts = await _discountService.listActivePublic();
        activeDiscounts = allDiscounts.where((d) => d.isAvailable).toList();
      } else {
        activeDiscounts = availablePackageDiscounts;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveDiscounts() async {
    await fetchActiveDiscounts();
  }

  Future<void> fetchUserApplicableDiscounts(String userId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // Get auto-apply discounts for user
      final autoApplyDiscounts = activeDiscounts
          .where((d) => d.isAutoApply)
          .toList();

      userApplicableDiscounts = autoApplyDiscounts;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<DiscountModel?> validateDiscountCode(String code) async {
    try {
      // Check in active discounts
      final discount = activeDiscounts.firstWhere(
        (d) => d.code.toUpperCase() == code.toUpperCase() && d.isAvailable,
        orElse: () => throw Exception('Mã khuyến mãi không tồn tại hoặc đã hết hạn'),
      );

      return discount;
    } catch (e) {
      return null;
    }
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
    notifyListeners();
  }
}

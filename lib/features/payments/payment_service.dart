import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/payments/payment_model.dart';

class PaymentService {
  final ApiClient _api;

  PaymentService(this._api);

  /// Lấy lịch sử thanh toán của member hiện tại
  Future<List<PaymentModel>> getMyPaymentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '/api/payments/history/me',
      query: {'page': page.toString(), 'limit': limit.toString()},
    );
    final payments = res['payments'] as List? ?? [];
    return payments
        .map((e) => PaymentModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Lấy lịch sử thanh toán theo member ID (cho admin/staff)
  Future<List<PaymentModel>> getPaymentHistoryByMemberId(
    String memberId, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.getJson(
      '/api/payments/history/$memberId',
      query: {'page': page.toString(), 'limit': limit.toString()},
    );
    final payments = res['payments'] as List? ?? [];
    return payments
        .map((e) => PaymentModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Tạo thanh toán VNPay (Hỗ trợ cả Gói tập và Sản phẩm)
  Future<String> createVNPayPayment({
    String? registrationId, // Cho gói tập (Optional)
    String? orderId, // Cho đơn hàng sản phẩm (MỚI - Optional)
    required num amount,
    String? locale,
  }) async {
    // Validation: Phải có ít nhất 1 loại ID để biết đang thanh toán cho cái gì
    if (registrationId == null && orderId == null) {
      throw Exception(
        "Thiếu thông tin thanh toán (cần registrationId hoặc orderId)",
      );
    }

    final res = await _api.postJson(
      '/api/payments/create-vnpay',
      body: {
        if (registrationId != null) 'registrationId': registrationId,
        if (orderId != null) 'orderId': orderId,
        'amount': amount,
        if (locale != null) 'locale': locale,
      },
    );
    return res['paymentUrl'] as String;
  }

  /// Tạo thanh toán mới (hỗ trợ cả VNPAY và tiền mặt)
  Future<Map<String, dynamic>> createPayment({
    String? registrationId, // Cho gói tập (Optional)
    String? orderId, // Cho đơn hàng sản phẩm (Optional)
    required num amount,
    String? locale,
    required String paymentMethod, // "VNPAY" hoặc "CASH"
  }) async {
    // Validation: Phải có ít nhất 1 loại ID để biết đang thanh toán cho cái gì
    if (registrationId == null && orderId == null) {
      throw Exception(
        "Thiếu thông tin thanh toán (cần registrationId hoặc orderId)",
      );
    }

    final res = await _api.postJson(
      '/api/payments/create',
      body: {
        if (registrationId != null) 'registrationId': registrationId,
        if (orderId != null) 'orderId': orderId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        if (locale != null) 'locale': locale,
      },
    );
    
    return res;
  }

  /// Xác nhận thanh toán tiền mặt (dành cho admin)
  Future<Map<String, dynamic>> confirmCashPayment(String paymentId) async {
    final res = await _api.postJson(
      '/api/payments/confirm-cash',
      body: {
        'paymentId': paymentId,
      },
    );
    
    return res;
  }
}

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

  /// Tạo thanh toán VNPay
  Future<String> createVNPayPayment({
    required String registrationId,
    required num amount,
    String? locale,
  }) async {
    final res = await _api.postJson(
      '/api/payments/create-vnpay',
      body: {
        'registrationId': registrationId,
        'amount': amount,
        if (locale != null) 'locale': locale,
      },
    );
    return res['paymentUrl'] as String;
  }
}

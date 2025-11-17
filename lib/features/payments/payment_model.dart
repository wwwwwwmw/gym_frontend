class PaymentModel {
  final String id;
  final String memberId;
  final String? registrationId;
  final num amount;
  final String method;
  final String status;
  final String? transactionId;
  final String? vnpayTxnRef;
  final DateTime? paidAt;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.memberId,
    this.registrationId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.vnpayTxnRef,
    this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> m) {
    return PaymentModel(
      id: m['_id'] as String,
      memberId: m['member_id'] as String,
      registrationId: m['registration_id'] as String?,
      amount: (m['amount'] ?? 0) as num,
      method: (m['method'] ?? 'cash') as String,
      status: (m['status'] ?? 'pending') as String,
      transactionId: m['transactionId'] as String?,
      vnpayTxnRef: m['vnpayTxnRef'] as String?,
      paidAt: m['paidAt'] != null
          ? DateTime.tryParse(m['paidAt'].toString())
          : null,
      createdAt: DateTime.parse(m['createdAt'].toString()),
    );
  }

  String get displayAmount {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  String get displayStatus {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'pending':
        return 'Chờ thanh toán';
      case 'failed':
        return 'Thất bại';
      case 'refunded':
        return 'Đã hoàn tiền';
      default:
        return status;
    }
  }

  String get displayMethod {
    switch (method) {
      case 'vnpay':
        return 'VNPay';
      case 'cash':
        return 'Tiền mặt';
      case 'bank_transfer':
        return 'Chuyển khoản';
      default:
        return method;
    }
  }
}

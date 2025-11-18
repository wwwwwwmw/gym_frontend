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

  final String? packageName;
  final String? packageImageUrl;

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
    this.packageName,
    this.packageImageUrl,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> m) {
    String getId(dynamic field) {
      if (field == null) return '';
      if (field is String) return field;
      if (field is Map && field.containsKey('_id'))
        return field['_id'].toString();
      return field.toString();
    }

    String? pkgName;
    String? pkgImage;
    try {
      if (m['packageRegistration'] is Map) {
        final reg = m['packageRegistration'];
        final pkgData = reg['package'] ?? reg['package_id'];
        if (pkgData is Map) {
          pkgName = pkgData['name']?.toString();
          pkgImage = pkgData['imageUrl']?.toString();
        }
      }
    } catch (e) {
      print("Lỗi parse gói tập: $e");
    }

    // ✅ LOGIC MỚI: Tự động nhận diện phương thức thanh toán
    String detectedMethod = 'cash'; // Mặc định là Tiền mặt

    if (m['method'] != null && m['method'].toString().isNotEmpty) {
      detectedMethod = m['method'].toString();
    } else {
      // Nếu không có field method, ta đoán dựa trên dữ liệu VNPay
      // Nếu có mã giao dịch VNPay -> Là VNPay
      if (m['vnpTransactionNo'] != null || m['vnpResponseCode'] != null) {
        detectedMethod = 'vnpay';
      }
    }

    return PaymentModel(
      id: m['_id']?.toString() ?? '',
      memberId: getId(m['user'] ?? m['member_id']),
      registrationId: getId(m['packageRegistration'] ?? m['registration_id']),
      amount: (m['amount'] ?? 0) as num,

      // Gán phương thức đã nhận diện
      method: detectedMethod,

      status: (m['status'] ?? 'pending').toString(),
      transactionId: (m['vnpTransactionNo'] ?? m['transactionId'])?.toString(),
      vnpayTxnRef: (m['txnRef'] ?? m['vnpayTxnRef'])?.toString(),
      paidAt: m['paidAt'] != null || m['vnpPayDate'] != null
          ? _parseDate(m['paidAt'] ?? m['vnpPayDate'])
          : null,
      createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      packageName: pkgName,
      packageImageUrl: pkgImage,
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  String get displayAmount {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
        return 'Thành công';
      case 'pending':
        return 'Đang chờ';
      case 'failed':
        return 'Thất bại';
      case 'refunded':
        return 'Hoàn tiền';
      default:
        return 'Đang chờ';
    }
  }

  // Chỉ hiển thị VNPay hoặc Tiền mặt
  String get displayMethod {
    if (method.toLowerCase() == 'vnpay') return 'VNPay';
    return 'Tiền mặt';
  }
}

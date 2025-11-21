import 'package:intl/intl.dart';

class PaymentModel {
  final String id;
  final String memberId;
  final String? registrationId;
  final String? orderId;
  final num amount;
  final String method;
  final String status;
  final String? vnpayTxnRef;
  final DateTime createdAt;

  // ✅ Thông tin hiển thị (Dùng chung cho cả Gói tập & Sản phẩm)
  final String itemName;
  final String? itemImageUrl;
  final bool isProduct;

  PaymentModel({
    required this.id,
    required this.memberId,
    this.registrationId,
    this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    this.vnpayTxnRef,
    required this.createdAt,
    required this.itemName,
    this.itemImageUrl,
    required this.isProduct,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> m) {
    String getId(dynamic field) {
      if (field == null) return '';
      if (field is String) return field;
      if (field is Map && field.containsKey('_id'))
        return field['_id'].toString();
      return field.toString();
    }

    // --- LOGIC NHẬN DIỆN TÊN & ẢNH (QUAN TRỌNG) ---
    String name = 'Thanh toán';
    String? image;
    bool isProd = false;

    try {
      // 1. Kiểm tra Đơn hàng (Sản phẩm)
      if (m['order'] != null && m['order'] is Map) {
        final orderData = m['order'];
        // Backend populate: payment -> order -> product_id
        final productData = orderData['product_id'] ?? orderData['product'];

        if (productData != null && productData is Map) {
          name = productData['name']?.toString() ?? 'Sản phẩm';
          // Lấy ảnh (Backend trả về 'imageUrl')
          image =
              productData['imageUrl']?.toString() ??
              productData['image']?.toString();
          isProd = true;
        } else {
          name = "Đơn hàng sản phẩm";
          isProd = true;
        }
      }
      // 2. Kiểm tra Gói tập
      else if (m['packageRegistration'] != null &&
          m['packageRegistration'] is Map) {
        final regData = m['packageRegistration'];
        // Backend populate: payment -> packageRegistration -> package_id
        final pkgData = regData['package_id'] ?? regData['package'];

        if (pkgData != null && pkgData is Map) {
          name = pkgData['name']?.toString() ?? 'Gói tập';
          // Lấy ảnh gói tập
          image =
              pkgData['imageUrl']?.toString() ?? pkgData['image']?.toString();
        } else {
          name = "Gói tập";
        }
      }
    } catch (e) {
      print("Lỗi parse item: $e");
    }

    // Nhận diện phương thức thanh toán
    String detectedMethod = 'Tiền mặt';
    if (m['paymentMethod'] != null) {
      detectedMethod = m['paymentMethod'].toString() == 'VNPAY' ? 'VNPay' : 'Tiền mặt';
    } else if (m['vnpTransactionNo'] != null || m['vnpResponseCode'] != null) {
      detectedMethod = 'VNPay';
    }

    return PaymentModel(
      id: m['_id']?.toString() ?? '',
      memberId: getId(m['user'] ?? m['member_id']),
      registrationId: getId(m['packageRegistration']),
      orderId: getId(m['order']),
      amount: (m['amount'] ?? 0) as num,
      method: detectedMethod,
      status: (m['status'] ?? 'pending').toString(),
      vnpayTxnRef: (m['txnRef'] ?? m['vnpayTxnRef'])?.toString(),
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      itemName: name,
      itemImageUrl: image,
      isProduct: isProd,
    );
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
        return 'Thành công';
      case 'failed':
        return 'Thất bại';
      default:
        return 'Đang chờ';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/env.dart';
import '../../core/api_client.dart'; // ✅ Import ApiClient để khởi tạo PaymentService
import 'product_model.dart';
import 'product_service.dart';
import '../payments/payment_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = false;

  // ✅ 1. Khởi tạo trực tiếp các Service (Giống cách màn hình gói tập có thể đang làm)
  final ProductService _productService = ProductService();
  final PaymentService _paymentService = PaymentService(ApiClient());

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final r = raw.trim();
    if (r.startsWith('http://') || r.startsWith('https://')) return r;
    final base = apiBaseUrl();
    final cleanBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final cleanPath = r.startsWith('/') ? r : '/$r';
    return '$cleanBase$cleanPath';
  }

  // Xử lý Mua Hàng - Hiển thị lựa chọn phương thức thanh toán
  Future<void> _handleBuyNow() async {
    // Hiển thị dialog chọn phương thức thanh toán
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn phương thức thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.money),
                title: const Text('Thanh toán tiền mặt'),
                subtitle: const Text('Thanh toán tại quầy'),
                onTap: () => Navigator.pop(context, 'CASH'),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Thanh toán online (VNPay)'),
                subtitle: const Text('Thanh toán qua thẻ/ngân hàng'),
                onTap: () => Navigator.pop(context, 'VNPAY'),
              ),
            ],
          ),
        );
      },
    );

    if (paymentMethod == null) return; // User cancelled

    setState(() => _isLoading = true);
    try {
      if (paymentMethod == 'CASH') {
        // Xử lý thanh toán tiền mặt
        final result = await _paymentService.createPayment(
          orderId: await _productService.createOrder(widget.product.id),
          amount: widget.product.price,
          paymentMethod: 'CASH',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đã tạo phiếu thanh toán tiền mặt'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Có thể pop về màn hình trước đó
          Navigator.pop(context);
        }
      } else {
        // Xử lý thanh toán VNPAY
        final orderId = await _productService.createOrder(widget.product.id);
        
        if (!mounted) return;

        final paymentUrl = await _paymentService.createVNPayPayment(
          orderId: orderId,
          amount: widget.product.price,
          locale: 'vn',
        );

        // Mở trình duyệt thanh toán
        if (mounted) {
          final uri = Uri.parse(paymentUrl);

          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              throw 'Không thể mở trình duyệt. Vui lòng kiểm tra lại.';
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedImage = _resolveImageUrl(widget.product.image);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ảnh sản phẩm
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: resolvedImage != null
                  ? Image.network(
                      resolvedImage,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 250,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
          ),

          // Card Thông tin
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: 'đ',
                    ).format(widget.product.price),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Hiển thị trạng thái tồn kho
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.product.isAvailable 
                        ? Colors.green.shade50 
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.product.isAvailable 
                          ? Colors.green.shade200 
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.product.isAvailable 
                            ? Icons.check_circle 
                            : Icons.cancel,
                        color: widget.product.isAvailable 
                            ? Colors.green 
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.product.isAvailable 
                            ? 'Còn hàng (${widget.product.stock} sản phẩm)'
                            : 'Hết hàng',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.product.isAvailable 
                              ? Colors.green.shade700 
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Mô tả',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  (widget.product.description.isNotEmpty)
                      ? widget.product.description
                      : "Đang cập nhật...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Nút Mua Ngay
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: (_isLoading || !widget.product.isAvailable) ? null : _handleBuyNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.product.isAvailable ? cs.error : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: widget.product.isAvailable ? 4 : 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.product.isAvailable ? 'MUA NGAY' : 'HẾT HÀNG',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

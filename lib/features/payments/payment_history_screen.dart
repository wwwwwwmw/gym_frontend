import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/core/env.dart'; // Import env để lấy apiBaseUrl
import 'package:gym_frontend/features/payments/payment_model.dart';
import 'package:gym_frontend/features/payments/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  // Khởi tạo service trực tiếp
  final _service = PaymentService(ApiClient(storage: TokenStorage()));

  bool _isLoading = true;
  String? _errorMessage;
  List<PaymentModel> _payments = [];
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getMyPaymentHistory();
      if (mounted) {
        setState(() {
          _payments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi: $e";
          _isLoading = false;
        });
      }
    }
  }

  // Hàm xử lý đường dẫn ảnh chuẩn
  String _getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;

    final base = apiBaseUrl();
    // Xử lý dấu gạch chéo để tránh trùng lặp (vd: base/ + /uploads)
    final cleanBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final cleanPath = relativePath.startsWith('/')
        ? relativePath
        : '/$relativePath';

    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Lịch sử thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPaymentHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));
    if (_payments.isEmpty)
      return const Center(child: Text("Chưa có giao dịch nào"));

    return RefreshIndicator(
      onRefresh: _fetchPaymentHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildPaymentItem(_payments[index]),
      ),
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    final isSuccess = [
      'success',
      'paid',
    ].contains(payment.status.toLowerCase());
    final statusColor = isSuccess
        ? Colors.green
        : (payment.status == 'failed' ? Colors.red : Colors.orange);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ẢNH SẢN PHẨM / GÓI TẬP
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 70,
              height: 70,
              color: Colors.grey.shade100,
              child:
                  (payment.itemImageUrl != null &&
                      payment.itemImageUrl!.isNotEmpty)
                  ? Image.network(
                      _getImageUrl(payment.itemImageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : Icon(
                      payment.isProduct
                          ? Icons.shopping_bag
                          : Icons.fitness_center,
                      color: Colors.grey.shade300,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // THÔNG TIN CHI TIẾT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy • HH:mm').format(payment.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currencyFormat.format(payment.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payment.displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

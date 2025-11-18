import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/features/payments/payment_model.dart';
import 'package:gym_frontend/features/payments/payment_service.dart';
import 'package:intl/intl.dart';
import 'package:gym_frontend/core/env.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
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
          _errorMessage = "Không thể tải lịch sử: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  String _getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;
    final base = apiBaseUrl();
    String path = relativePath.replaceAll('\\', '/');
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Lịch sử thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPaymentHistory,
          ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            ElevatedButton(
              onPressed: _fetchPaymentHistory,
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchPaymentHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildPaymentItem(_payments[index], colorScheme);
        },
      ),
    );
  }

  Widget _buildPaymentItem(PaymentModel payment, ColorScheme colorScheme) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    final statusLower = payment.status.toLowerCase();

    if (statusLower == 'success' || statusLower == 'paid') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = "Thành công";
    } else if (statusLower == 'failed') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = "Thất bại";
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_bottom;
      statusText = "Đang chờ";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade100,
                  child:
                      payment.packageImageUrl != null &&
                          payment.packageImageUrl!.isNotEmpty
                      ? Image.network(
                          _getImageUrl(payment.packageImageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade300,
                            );
                          },
                        )
                      : Icon(
                          Icons.fitness_center,
                          color: Colors.grey.shade300,
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.packageName ?? "Gói tập Gym",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy • HH:mm',
                          ).format(payment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Mã: ${payment.vnpayTxnRef ?? '---'}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade100,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ SỬA: Dùng hàm _getMethodName đã lọc gọn
                  Text(
                    "Thanh toán qua ${_getMethodName(payment.method)}",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    _currencyFormat.format(payment.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ HÀM HIỂN THỊ CHỈ VNPAY HOẶC TIỀN MẶT
  String _getMethodName(String method) {
    if (method.toLowerCase() == 'vnpay') {
      return 'VNPay';
    }
    // Tất cả các trường hợp còn lại (cash, bank_transfer, null...) gom về Tiền mặt
    // Trừ khi sau này bạn mở rộng thêm
    return 'Tiền mặt';
  }
}

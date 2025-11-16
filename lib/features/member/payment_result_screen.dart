import 'package:flutter/material.dart';

class PaymentResultScreen extends StatelessWidget {
  final String? success;
  final String? code; // thực ra là vnp_ResponseCode

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.code,
  });

  bool get isSuccess => success == "true" || success == "1";

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kết quả thanh toán'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICON
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  size: 120,
                  color: isSuccess ? Colors.green : Colors.red,
                ),

                const SizedBox(height: 32),

                // TIÊU ĐỀ
                Text(
                  isSuccess ? "Thanh toán thành công!" : "Thanh toán thất bại",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color.onBackground,
                  ),
                ),

                const SizedBox(height: 16),

                // MÔ TẢ
                Text(
                  isSuccess
                      ? "Gói tập của bạn đã được kích hoạt.\nBạn có thể xem trong mục “Gói tập của tôi”."
                      : "Giao dịch không thành công.\nVui lòng thử lại hoặc liên hệ hỗ trợ.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),

                // CHỈ HIỂN THỊ MÃ KHI THẤT BẠI
                if (!isSuccess && code != null && code!.isNotEmpty) ...[
                  Text(
                    "Mã phản hồi từ VNPay: $code",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Nếu cần hỗ trợ, vui lòng cung cấp mã này cho nhân viên.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 40),

                // NÚT VỀ MÀN HÌNH CHÍNH
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.error,
                      foregroundColor: color.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dash/member',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Về màn hình chính",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

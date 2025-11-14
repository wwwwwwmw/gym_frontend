import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';

class PaymentResultScreen extends StatefulWidget {
  // Nhận tham số từ deep link / route
  final String? success;
  final String? code;

  const PaymentResultScreen({super.key, this.success, this.code});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  bool _isSuccess = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePaymentResult();
  }

  void _initializePaymentResult() {
    final success = widget.success;
    final code = widget.code;

    // Thành công khi: success = 'true' và code = '00'
    _isSuccess = success == 'true' && code == '00';

    if (!_isSuccess) {
      _errorMessage = _getErrorMessage(code);
    }
  }

  String _getErrorMessage(String? code) {
    switch (code) {
      case '07':
        return 'Trừ tiền thành công nhưng giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường).';
      case '09':
        return 'Thẻ/Tài khoản của khách hàng chưa đăng ký dịch vụ Internet Banking.';
      case '10':
        return 'Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần.';
      case '11':
        return 'Đã hết thời gian chờ thanh toán. Vui lòng thực hiện lại giao dịch.';
      case '12':
        return 'Thẻ/Tài khoản của khách hàng đang bị khóa.';
      case '13':
        return 'Quý khách nhập sai mật khẩu xác thực giao dịch (OTP).';
      case '24':
        return 'Khách hàng đã hủy giao dịch.';
      case '51':
        return 'Tài khoản của quý khách không đủ số dư để thực hiện giao dịch.';
      case '65':
        return 'Tài khoản của quý khách đã vượt quá hạn mức giao dịch trong ngày.';
      case '75':
        return 'Ngân hàng thanh toán đang bảo trì.';
      case '79':
        return 'Quý khách nhập sai mật khẩu thanh toán quá số lần quy định.';
      case '99':
        return 'Lỗi khác. Vui lòng thử lại hoặc liên hệ hỗ trợ.';
      default:
        return 'Đã có lỗi xảy ra trong quá trình thanh toán. Vui lòng thử lại.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả thanh toán'),
        automaticallyImplyLeading: false, // Ẩn nút back mặc định
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSuccess ? Icons.check_circle : Icons.error,
                color: _isSuccess ? Colors.green : Colors.red,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                _isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _isSuccess
                    ? 'Gói tập của bạn đã được kích hoạt.\nBạn có thể kiểm tra trong mục "Gói tập của tôi".'
                    : _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isSuccess ? null : Colors.red.shade700,
                ),
              ),
              if (!_isSuccess && code != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Mã lỗi: $code',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 48),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _navigateToHome,
                child: const Text('Về màn hình chính'),
              ),
              if (!_isSuccess) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    // Quay lại màn đăng ký gói
                    Navigator.of(context).pop();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHome() {
    try {
      final authProvider = context.read<AuthProvider>();
      final role = authProvider.role;

      // Khớp với route bạn đã khai báo trong app.dart
      String route = '/login';
      if (role == 'MEMBER') {
        route = '/dash/member';
      } else if (role == 'ADMIN') {
        route = '/dash/admin';
      } else if (role == 'TRAINER') {
        route = '/dash/trainer';
      } else if (role == 'RECEPTION') {
        route = '/dash/reception';
      }

      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } catch (e) {
      // Fallback nếu có lỗi => về màn login
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }
}

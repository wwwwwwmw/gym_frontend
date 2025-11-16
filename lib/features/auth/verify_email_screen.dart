// lib/features/auth/verify_email_screen.dart

import 'dart:async'; // Cần thiết cho Timer
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart'; // Import package pinput
import 'package:provider/provider.dart';
import 'signup_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Timer? _timer;
  int _countdown = 60; // Thời gian đếm ngược (giây)
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  // Bắt đầu bộ đếm ngược
  void startTimer() {
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          // Kiểm tra widget còn tồn tại
          setState(() {
            _countdown--;
          });
        }
      } else {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  // Đặt lại bộ đếm ngược
  void resetTimer() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
    });
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Huỷ timer khi widget bị xoá
    _pinController.dispose();
    super.dispose();
  }

  // Hàm xử lý khi nhấn "Xác nhận"
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    setState(() => _isLoading = true);
    final pin = _pinController.text;

    // Sử dụng SignupProvider để gọi API
    final signupProvider = Provider.of<SignupProvider>(context, listen: false);
    final email = signupProvider.pendingEmail;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy email đăng ký'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await signupProvider.verify(pin);
      if (!success) {
        throw Exception(signupProvider.error ?? 'Xác minh thất bại');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác minh email thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Quay về màn hình đăng nhập sau khi thành công
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xác minh thất bại: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Hàm xử lý khi nhấn "Gửi lại mã"
  Future<void> _resendCode() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final signupProvider = Provider.of<SignupProvider>(context, listen: false);
    final email = signupProvider.pendingEmail;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy email đăng ký'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Logic gọi API gửi lại mã
      await signupProvider.resend();
      // Kiểm tra lỗi sau khi gọi
      if (signupProvider.error != null) {
        throw Exception(signupProvider.error!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã xác minh.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      // Bắt đầu đếm ngược lại
      resetTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cấu hình giao diện cho các ô Pinput
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    // Giao diện khi ô được focus (giống Hình 2)
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(
        color: Theme.of(context).colorScheme.error,
        width: 2,
      ), // Màu đỏ
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.grey.shade300),
      color: Colors.grey.shade50,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh'), centerTitle: true),
      body: SingleChildScrollView(
        // Dùng SingleChildScrollView để tránh lỗi khi bàn phím hiện
        child: Padding(
          // Thêm padding để nội dung không sát viền và cân đối
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              // Yêu cầu các widget con co giãn theo chiều ngang
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Xác minh mã OTP',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                // Khoảng cách cân đối
                const SizedBox(height: 16),
                Text(
                  'Chúng tôi đã gửi mã OTP đến email của bạn',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Consumer<SignupProvider>(
                  builder: (context, signupProvider, child) {
                    return Text(
                      signupProvider.pendingEmail ?? '(chưa có)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                // Khoảng cách cố định để bố cục cân đối
                const SizedBox(height: 48),

                // Widget Pinput
                Pinput(
                  controller: _pinController,
                  length: 6, // 6 ô
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  validator: (s) {
                    if (s == null || s.length < 6) {
                      return 'Vui lòng nhập đủ 6 số';
                    }
                    return null;
                  },
                  autofocus: true,
                  onCompleted: (pin) => _submit(), // Tự động submit khi nhập đủ
                ),

                const SizedBox(height: 32),
                _buildResendCodeWidget(), // Widget Gửi lại mã
                const SizedBox(height: 32),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Nút to, rõ ràng
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    // Bạn có thể chỉnh màu ở đây cho giống Hình 2
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Xác nhận'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget hiển thị logic "Gửi lại mã"
  Widget _buildResendCodeWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Không nhận được email? '),
        if (_canResend)
          TextButton(
            onPressed: _isLoading ? null : _resendCode,
            child: const Text('Gửi lại mã'),
          )
        else
          // Hiển thị bộ đếm ngược
          Text(
            'Gửi lại sau $_countdown s',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
      ],
    );
  }
}

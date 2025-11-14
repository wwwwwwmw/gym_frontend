import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Thêm form key để validate

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _performVerify() async {
    // Validate trước khi gửi
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = context.read<SignupProvider>();
    final ok = await vm.verify(_code.text.trim());
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác minh thành công, vui lòng đăng nhập.'),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupProvider>();
    final email = vm.pendingEmail ?? '(chưa có)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác minh'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                // Thêm Form
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Xác minh mã OTP',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chúng tôi đã gửi mã OTP đến email của bạn',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Cập nhật TextFormField để yêu cầu 6 số
                      TextFormField(
                        controller: _code,
                        decoration: const InputDecoration(
                          labelText: 'Mã xác minh (6 số)',
                          hintText: '123456',
                          counterText: "", // Ẩn bộ đếm ký tự
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6, // Giới hạn 6 ký tự
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 12,
                        ), // Tạo khoảng cách
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Nhập đủ 6 số' : null,
                      ),
                      const SizedBox(height: 16),

                      // Đếm ngược (nếu có) và Gửi lại
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Không nhận được email? ',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          TextButton(
                            onPressed: () => vm.resend(),
                            child: const Text('Gửi lại mã'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Lỗi (nếu có)
                      if (vm.error != null)
                        Text(
                          vm.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 8),

                      // Nút Xác nhận
                      FilledButton(
                        onPressed: vm.loading ? null : _performVerify,
                        child: vm.loading
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
          ),
        ),
      ),
    );
  }
}

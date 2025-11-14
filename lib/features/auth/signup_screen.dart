import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _performRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<SignupProvider>();

    final ok = await vm.register(
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
    );
    if (ok && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tạo tài khoản',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tạo tài khoản của bạn để khám phá.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),

                      // Full Name
                      const Text(
                        'Tên',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullName,
                        decoration: const InputDecoration(
                          hintText: 'Ex: John Doe',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Nhập họ tên' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          hintText: 'Ex: coffee@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Nhập email' : null,
                      ),
                      const SizedBox(height: 16),

                      // Số điện thoại
                      const Text(
                        'Số điện thoại',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          hintText: 'Ex: 0901234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.length < 10)
                            ? 'Nhập SĐT hợp lệ (10 số)'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      const Text(
                        'Mật khẩu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _password,
                        decoration: const InputDecoration(
                          hintText: 'Nhập mật khẩu của bạn',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mật khẩu tối thiểu 6 ký tự'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Remember me
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) =>
                                setState(() => _rememberMe = val ?? false),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Expanded(child: Text('Ghi nhớ tôi')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lỗi (nếu có)
                      if (vm.error != null)
                        Center(
                          child: Text(
                            vm.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Nút Đăng ký
                      FilledButton(
                        onPressed: vm.loading ? null : _performRegister,
                        child: vm.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Đăng ký với Email'),
                      ),

                      const SizedBox(height: 32),

                      // Nút Đăng nhập
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/login'),
                            child: const Text('Đăng nhập'),
                          ),
                        ],
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

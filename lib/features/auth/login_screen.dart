// THAY THẾ FILE NÀY: lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'test@example.com');
  final _password = TextEditingController(text: 'Test123456');
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.text.trim(), _password.text);
    if (ok && context.mounted) {
      final role = (auth.role ?? '').toUpperCase();
      switch (role) {
        case 'ADMIN':
          Navigator.of(context).pushReplacementNamed('/dash/admin');
          break;
        case 'MANAGER':
          Navigator.of(context).pushReplacementNamed('/dash/manager');
          break;
        case 'TRAINER':
          Navigator.of(context).pushReplacementNamed('/dash/trainer');
          break;
        case 'RECEPTION':
          Navigator.of(context).pushReplacementNamed('/dash/reception');
          break;
        default:
          Navigator.of(context).pushReplacementNamed('/dash/member');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        automaticallyImplyLeading: false, // Ẩn nút back
        // Nút chuông thông báo (tạm thời chưa có chức năng)
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
                        'Chào mừng trở lại!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng nhập email và mật khẩu để đăng nhập.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),
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
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (val) =>
                                    setState(() => _rememberMe = val ?? false),
                                visualDensity: VisualDensity.compact,
                              ),
                              const Text('Ghi nhớ tôi'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Điều hướng sang trang quên mật khẩu
                            },
                            child: const Text('Quên mật khẩu?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (auth.error != null)
                        Center(
                          child: Text(
                            auth.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: auth.loading ? null : _performLogin,
                        child: auth.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Đăng nhập với Email'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/signup'),
                            child: const Text('Đăng ký'),
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

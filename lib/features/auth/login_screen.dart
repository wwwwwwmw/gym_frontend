import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nhập email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                  ),
                  const SizedBox(height: 16),
                  if (auth.error != null)
                    Text(
                      auth.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.loading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final ok = await auth.login(
                                _email.text.trim(),
                                _password.text,
                              );
                              if (ok && context.mounted) {
                                final role = (auth.role ?? '').toUpperCase();
                                switch (role) {
                                  case 'ADMIN':
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/dash/admin');
                                    break;
                                  case 'MANAGER':
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/dash/manager');
                                    break;
                                  case 'TRAINER':
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/dash/trainer');
                                    break;
                                  case 'RECEPTION':
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/dash/reception');
                                    break;
                                  default:
                                    // MEMBER and any other roles fall back to member dashboard
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/dash/member');
                                }
                              }
                            },
                      child: auth.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/signup'),
                    child: const Text('Chưa có tài khoản? Đăng ký'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

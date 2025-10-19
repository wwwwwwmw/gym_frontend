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

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh email')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nhập mã xác minh đã gửi tới: ${vm.pendingEmail ?? '(chưa có)'}',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Mã xác minh (6 số)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                if (vm.error != null)
                  Text(vm.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: vm.loading
                      ? null
                      : () async {
                          final ok = await vm.verify(_code.text.trim());
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Xác minh thành công, vui lòng đăng nhập.',
                                ),
                              ),
                            );
                            Navigator.of(
                              context,
                            ).pushReplacementNamed('/login');
                          }
                        },
                  child: vm.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xác minh'),
                ),
                TextButton(
                  onPressed: () => vm.resend(),
                  child: const Text('Gửi lại mã'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/members/member_provider.dart';

class MemberCreateScreen extends StatefulWidget {
  const MemberCreateScreen({super.key});

  @override
  State<MemberCreateScreen> createState() => _MemberCreateScreenState();
}

class _MemberCreateScreenState extends State<MemberCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _gender = 'other';
  final _address = TextEditingController();
  bool _createUser = true;
  final _password = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(title: const Text('Tạo hội viên')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Invalid email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Nam')),
                      DropdownMenuItem(value: 'female', child: Text('Nữ')),
                      DropdownMenuItem(value: 'other', child: Text('Khác')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'other'),
                    decoration: const InputDecoration(labelText: 'Giới tính'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ (không bắt buộc)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _createUser,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tạo luôn tài khoản đăng nhập (role: MEMBER)'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setState(() => _createUser = v ?? true),
                  ),
                  if (_createUser)
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu (để trống sẽ tự tạo)',
                      ),
                      obscureText: true,
                    ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (!(_formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              setState(() {
                                _saving = true;
                                _error = null;
                              });
                              try {
                                final api = ApiClient();
                                final res = await api.postJson(
                                  '/api/members',
                                  body: {
                                    'fullName': _fullName.text.trim(),
                                    'email': _email.text.trim(),
                                    'phone': _phone.text.trim(),
                                    'gender': _gender,
                                    if (_address.text.trim().isNotEmpty)
                                      'address': _address.text.trim(),
                                    'createUser': _createUser,
                                    if (_createUser && _password.text.isNotEmpty)
                                      'password': _password.text,
                                  },
                                );
                                if (!context.mounted) return;
                                final member = res['member'] as Map<String, dynamic>?;
                                final tempPwd = res['tempPassword'] as String?;
                                await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Tạo hội viên thành công'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (member != null) ...[
                                          Text('Mã hội viên: ${member['membershipNumber'] ?? ''}'),
                                          const SizedBox(height: 6),
                                          Text('Họ tên: ${member['fullName'] ?? ''}'),
                                          Text('Email: ${member['email'] ?? ''}'),
                                        ],
                                        if (tempPwd != null && tempPwd.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          const Text('Tài khoản đã được tạo (MEMBER).'),
                                          Text('Mật khẩu tạm thời: $tempPwd'),
                                        ],
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Đóng'),
                                      ),
                                    ],
                                  ),
                                );
                                // refresh list if provider exists in tree
                                context.read<MemberProvider>().fetch();
                                Navigator.pop(context, true);
                              } catch (e) {
                                setState(() => _error = e.toString());
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Tạo hội viên'),
                    ),
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

class _CreateUserCheckbox extends StatefulWidget {
  const _CreateUserCheckbox();
  @override
  State<_CreateUserCheckbox> createState() => _CreateUserCheckboxState();
}

class _CreateUserCheckboxState extends State<_CreateUserCheckbox> {
  bool _createUser = true;
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: _createUser,
          contentPadding: EdgeInsets.zero,
          title: const Text('Tạo luôn tài khoản đăng nhập (role: MEMBER)'),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (v) => setState(() => _createUser = v ?? true),
        ),
        if (_createUser)
          TextFormField(
            controller: _password,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu (để trống sẽ tự tạo)',
            ),
            obscureText: true,
          ),
      ],
    );
  }
}

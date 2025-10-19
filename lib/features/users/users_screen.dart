import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'user_model.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _search = TextEditingController();
  String? _role;
  bool? _verified;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetch();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UserProvider>().fetch(
              search: _search.text,
              role: _role,
              verified: _verified,
            ),
          ),
          IconButton(
            tooltip: 'Tạo người dùng',
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              final created = await _showCreateDialog(context);
              if (!context.mounted) return;
              if (created == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã tạo người dùng')),
                );
                context.read<UserProvider>().fetch(
                  search: _search.text,
                  role: _role,
                  verified: _verified,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm theo tên hoặc email',
                    ),
                    onSubmitted: (_) => context.read<UserProvider>().fetch(
                      search: _search.text,
                      role: _role,
                      verified: _verified,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _role,
                  hint: const Text('Vai trò'),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'MANAGER', child: Text('MANAGER')),
                    DropdownMenuItem(value: 'TRAINER', child: Text('TRAINER')),
                    DropdownMenuItem(
                      value: 'RECEPTION',
                      child: Text('RECEPTION'),
                    ),
                    DropdownMenuItem(value: 'MEMBER', child: Text('MEMBER')),
                  ],
                  onChanged: (v) {
                    setState(() => _role = v);
                    context.read<UserProvider>().fetch(
                      search: _search.text,
                      role: v,
                      verified: _verified,
                    );
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<bool>(
                  value: _verified,
                  hint: const Text('Xác thực email'),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Đã xác thực')),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Chưa xác thực'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _verified = v);
                    context.read<UserProvider>().fetch(
                      search: _search.text,
                      role: _role,
                      verified: v,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? Center(child: Text(vm.error!))
                : ListView.separated(
                    itemCount: vm.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) => _tile(context, vm.items[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, UserModel u) {
    return ListTile(
      title: Text(u.fullName),
      subtitle: Text(
        '${u.email} • ${u.role} • ${u.isEmailVerified ? 'đã xác thực' : 'chưa xác thực'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.admin_panel_settings),
            onSelected: (value) async {
              final ok = await context.read<UserProvider>().updateRole(
                u.id,
                value,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Đã cập nhật vai trò' : 'Cập nhật thất bại',
                  ),
                ),
              );
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'ADMIN', child: Text('Set ADMIN')),
              PopupMenuItem(value: 'MANAGER', child: Text('Set MANAGER')),
              PopupMenuItem(value: 'TRAINER', child: Text('Set TRAINER')),
              PopupMenuItem(value: 'RECEPTION', child: Text('Set RECEPTION')),
              PopupMenuItem(value: 'MEMBER', child: Text('Set MEMBER')),
            ],
          ),
          IconButton(
            tooltip: u.isEmailVerified
                ? 'Đánh dấu chưa xác thực'
                : 'Đánh dấu đã xác thực',
            icon: Icon(
              u.isEmailVerified ? Icons.verified : Icons.verified_outlined,
            ),
            onPressed: () async {
              final ok = await context.read<UserProvider>().setVerified(
                u.id,
                !u.isEmailVerified,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Đã cập nhật xác thực' : 'Cập nhật thất bại',
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Đặt lại mật khẩu',
            icon: const Icon(Icons.password),
            onPressed: () async {
              final newPass = await _promptText(
                context,
                title: 'Đặt mật khẩu mới (tối thiểu 6 ký tự)',
              );
              if (!context.mounted || newPass == null) return;
              final ok = await context.read<UserProvider>().setPassword(
                u.id,
                newPass,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Đã cập nhật mật khẩu' : 'Cập nhật thất bại',
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Xoá người dùng',
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Xoá người dùng?'),
                  content: Text('Xoá ${u.fullName}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Huỷ'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xoá'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                if (!context.mounted) return;
                final done = await context.read<UserProvider>().remove(u.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      done ? 'Đã xoá người dùng' : 'Xoá không thành công',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      onTap: () async {
        final updated = await _showEditDialog(context, u);
        if (!context.mounted) return;
        if (updated == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User updated')));
          context.read<UserProvider>().fetch(
            search: _search.text,
            role: _role,
            verified: _verified,
          );
        }
      },
    );
  }

  Future<bool?> _showCreateDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'MEMBER';
    bool verified = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo người dùng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Vai trò: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                      DropdownMenuItem(
                        value: 'MANAGER',
                        child: Text('MANAGER'),
                      ),
                      DropdownMenuItem(
                        value: 'TRAINER',
                        child: Text('TRAINER'),
                      ),
                      DropdownMenuItem(
                        value: 'RECEPTION',
                        child: Text('RECEPTION'),
                      ),
                      DropdownMenuItem(value: 'MEMBER', child: Text('MEMBER')),
                    ],
                    onChanged: (v) => role = v ?? role,
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: verified,
                    onChanged: (v) => verified = v ?? verified,
                  ),
                  const Text('Đã xác thực email'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!context.mounted) return false;
      final fullName = nameCtrl.text.trim();
      final email = emailCtrl.text.trim();
      final password = passCtrl.text.trim();
      if (fullName.isEmpty || email.isEmpty || password.length < 6) {
        return false;
      }
      final done = await context.read<UserProvider>().create(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        verified: verified,
      );
      if (!context.mounted) return false;
      return done;
    }
    return null;
  }

  Future<bool?> _showEditDialog(BuildContext context, UserModel u) async {
    final nameCtrl = TextEditingController(text: u.fullName);
    final emailCtrl = TextEditingController(text: u.email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa người dùng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!context.mounted) return false;
      final fullName = nameCtrl.text.trim();
      final email = emailCtrl.text.trim();
      if (fullName.isEmpty || email.isEmpty) {
        return false;
      }
      final done = await context.read<UserProvider>().update(
        u.id,
        fullName: fullName,
        email: email,
      );
      if (!context.mounted) return false;
      return done;
    }
    return null;
  }

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
  }) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, obscureText: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final v = ctrl.text.trim();
      if (v.length < 6) return null;
      return v;
    }
    return null;
  }
}

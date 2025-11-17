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
  final _searchCtrl = TextEditingController();
  String? _role; // ADMIN / MANAGER / ...
  bool? _verified; // true / false / null

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<UserProvider>().fetch(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Người dùng'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => _reload(),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Thêm người dùng',
            onPressed: () => _openCreateUserDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== FILTER BAR =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Tìm theo tên / email...',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _reload();
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _reload(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _role,
                          isExpanded: true,
                          hint: const Text('Vai trò'),
                          items: const [
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Text('ADMIN'),
                            ),
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
                            DropdownMenuItem(
                              value: 'MEMBER',
                              child: Text('MEMBER'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _role = v);
                            _reload();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _verified == null
                              ? null
                              : (_verified! ? 'verified' : 'unverified'),
                          isExpanded: true,
                          hint: const Text('Xác thực email'),
                          items: const [
                            DropdownMenuItem(
                              value: 'verified',
                              child: Text('Đã xác thực'),
                            ),
                            DropdownMenuItem(
                              value: 'unverified',
                              child: Text('Chưa xác thực'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              if (v == null) {
                                _verified = null;
                              } else if (v == 'verified') {
                                _verified = true;
                              } else {
                                _verified = false;
                              }
                            });
                            _reload();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== LIST =====
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? _errorView(vm.error!)
                : vm.items.isEmpty
                ? _emptyView()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: vm.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) =>
                        _userCard(context, vm.items[i], colorScheme),
                  ),
          ),
        ],
      ),
    );
  }

  // =================== HELPERS ===================

  void _reload() {
    context.read<UserProvider>().fetch(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      role: _role,
      verified: _verified,
    );
  }

  Widget _errorView(String error) {
    final text = error.length > 120 ? '${error.substring(0, 120)}...' : error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Có lỗi xảy ra khi tải danh sách người dùng.\n$text',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Chưa có người dùng nào',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hãy thêm người dùng hoặc kiểm tra lại bộ lọc.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, UserModel u, ColorScheme colorScheme) {
    final initials = _initialsOf(u.fullName);
    final verifiedColor = u.isEmailVerified
        ? Colors.green.shade600
        : Colors.orange.shade700;
    final verifiedLabel = u.isEmailVerified
        ? 'Email đã xác thực'
        : 'Email chưa xác thực';

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // nếu sau này có màn chi tiết user thì mở ở đây
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            u.role,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: verifiedColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                u.isEmailVerified
                                    ? Icons.verified
                                    : Icons.mark_email_unread,
                                size: 13,
                                color: verifiedColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                verifiedLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: verifiedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_UserAction>(
                onSelected: (action) => _handleAction(action, u),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: _UserAction.changeRole,
                    child: Text('Đổi vai trò'),
                  ),
                  PopupMenuItem(
                    value: _UserAction.toggleVerify,
                    child: Text(
                      u.isEmailVerified
                          ? 'Đánh dấu chưa xác thực'
                          : 'Đánh dấu đã xác thực',
                    ),
                  ),
                  const PopupMenuItem(
                    value: _UserAction.resetPassword,
                    child: Text('Đặt lại mật khẩu'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _UserAction.delete,
                    child: Text(
                      'Xoá người dùng',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initialsOf(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // =================== ACTIONS ===================

  Future<void> _handleAction(_UserAction action, UserModel u) async {
    final provider = context.read<UserProvider>();

    switch (action) {
      case _UserAction.changeRole:
        final newRole = await _pickRole(u.role);
        if (newRole == null || newRole == u.role) return;
        final ok = await provider.updateRole(u.id, newRole);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Đã cập nhật vai trò' : 'Cập nhật vai trò thất bại',
            ),
          ),
        );
        break;

      case _UserAction.toggleVerify:
        final target = !u.isEmailVerified;
        final ok = await provider.setVerified(u.id, target);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              target
                  ? (ok
                        ? 'Đã đánh dấu email đã xác thực'
                        : 'Cập nhật trạng thái email thất bại')
                  : (ok
                        ? 'Đã đánh dấu email chưa xác thực'
                        : 'Cập nhật trạng thái email thất bại'),
            ),
          ),
        );
        break;

      case _UserAction.resetPassword:
        final newPass = await _askNewPassword();
        if (newPass == null || newPass.trim().isEmpty) return;
        final ok = await provider.setPassword(u.id, newPass.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Đã đặt lại mật khẩu' : 'Đặt lại mật khẩu thất bại',
            ),
          ),
        );
        break;

      case _UserAction.delete:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xoá người dùng?'),
            content: Text('Bạn có chắc muốn xoá "${u.fullName}"?'),
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
        if (confirm != true) return;
        final ok = await provider.remove(u.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã xoá người dùng' : 'Xoá người dùng thất bại'),
          ),
        );
        break;
    }
  }

  Future<String?> _pickRole(String current) async {
    String role = current;
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn vai trò'),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) => DropdownButton<String>(
            value: role,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
              DropdownMenuItem(value: 'MANAGER', child: Text('MANAGER')),
              DropdownMenuItem(value: 'TRAINER', child: Text('TRAINER')),
              DropdownMenuItem(value: 'RECEPTION', child: Text('RECEPTION')),
              DropdownMenuItem(value: 'MEMBER', child: Text('MEMBER')),
            ],
            onChanged: (v) => setStateDialog(() => role = v ?? role),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, role),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askNewPassword() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu mới',
            hintText: '••••••',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ===== Dialog tạo user mới =====
  Future<void> _openCreateUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'MEMBER';
    bool verified = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm người dùng'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Email không hợp lệ'
                      : null,
                ),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Ít nhất 6 ký tự' : null,
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (ctx, setStateDialog) => Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: role,
                        items: const [
                          DropdownMenuItem(
                            value: 'ADMIN',
                            child: Text('ADMIN'),
                          ),
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
                          DropdownMenuItem(
                            value: 'MEMBER',
                            child: Text('MEMBER'),
                          ),
                        ],
                        onChanged: (v) =>
                            setStateDialog(() => role = v ?? role),
                        decoration: const InputDecoration(labelText: 'Vai trò'),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Đánh dấu email đã xác thực'),
                        value: verified,
                        onChanged: (v) =>
                            setStateDialog(() => verified = v ?? false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final ok = await context.read<UserProvider>().create(
                fullName: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                password: passCtrl.text.trim(),
                role: role,
                verified: verified,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Đã tạo người dùng mới' : 'Tạo người dùng thất bại',
                  ),
                ),
              );
              if (ok) Navigator.pop(context, true);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    // nếu result == true thì đã thêm thành công, danh sách đã được update trong provider
    if (result == true) {
      // có thể reload lại nếu thích
      _reload();
    }
  }
}

enum _UserAction { changeRole, toggleVerify, resetPassword, delete }

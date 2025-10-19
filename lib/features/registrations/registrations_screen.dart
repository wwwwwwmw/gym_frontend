import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'registration_provider.dart';
import 'registration_model.dart';
import 'registration_view_screen.dart';

class RegistrationsScreen extends StatefulWidget {
  const RegistrationsScreen({super.key});

  @override
  State<RegistrationsScreen> createState() => _RegistrationsScreenState();
}

class _RegistrationsScreenState extends State<RegistrationsScreen> {
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistrationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký gói'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<RegistrationProvider>().fetch(status: _status),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Text('Trạng thái:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  hint: const Text('Tất cả'),
                  items: const [
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Đang hoạt động'),
                    ),
                    DropdownMenuItem(
                      value: 'suspended',
                      child: Text('Tạm dừng'),
                    ),
                    DropdownMenuItem(value: 'cancelled', child: Text('Đã huỷ')),
                    DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v);
                    context.read<RegistrationProvider>().fetch(status: v);
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
                    itemBuilder: (ctx, i) {
                      final r = vm.items[i];
                      return _tile(context, r);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, RegistrationModel r) {
    return ListTile(
      title: Text(r.member.fullName.isNotEmpty ? r.member.fullName : '(Không tên)'),
      subtitle: Text(
        '${r.package.name.isNotEmpty ? r.package.name : '(Gói)'} • ${_statusVi(r.status)} • ${r.finalPrice} VND',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RegistrationViewScreen(id: r.id)),
        );
        if (!context.mounted) return;
        context.read<RegistrationProvider>().fetch(status: _status);
      },
    );
  }

  String _statusVi(String s) {
    switch (s) {
      case 'active':
        return 'Đang hoạt động';
      case 'suspended':
        return 'Tạm dừng';
      case 'cancelled':
        return 'Đã huỷ';
      case 'expired':
        return 'Hết hạn';
      default:
        return s;
    }
  }
}

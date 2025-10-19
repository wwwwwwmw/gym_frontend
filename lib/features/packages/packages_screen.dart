import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_frontend/features/packages/package_provider.dart';
import 'package:gym_frontend/features/packages/package_model.dart';
import 'package:gym_frontend/features/packages/save_package_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PackageProvider>().fetch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PackageProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gói tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<PackageProvider>().fetch(status: _status),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const SavePackageScreen()),
              );
              if (!context.mounted) return;
              if (ok == true) {
                context.read<PackageProvider>().fetch(status: _status);
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
                const Text('Trạng thái:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  hint: const Text('Tất cả'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Đang bán')),
                    DropdownMenuItem(value: 'inactive', child: Text('Tạm ẩn')),
                    DropdownMenuItem(
                      value: 'discontinued',
                      child: Text('Ngừng kinh doanh'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v);
                    context.read<PackageProvider>().fetch(status: v);
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
                      final p = vm.items[i];
                      return _tile(context, p);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, PackageModel p) {
    return ListTile(
      title: Text(p.name),
      subtitle: Text(
        '${p.duration} ngày • ${p.price} VND • ${_statusVi(p.status)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => SavePackageScreen(editing: p),
                ),
              );
              if (!context.mounted) return;
              if (ok == true) {
                context.read<PackageProvider>().fetch(status: _status);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Xoá gói tập?'),
                  content: Text('Xoá "${p.name}"?'),
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
                final done = await context.read<PackageProvider>().remove(p.id);
                if (!context.mounted) return;
                if (!done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xoá không thành công')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _statusVi(String s) {
    switch (s) {
      case 'active':
        return 'Đang bán';
      case 'inactive':
        return 'Tạm ẩn';
      case 'discontinued':
        return 'Ngừng kinh doanh';
      default:
        return s;
    }
  }
}

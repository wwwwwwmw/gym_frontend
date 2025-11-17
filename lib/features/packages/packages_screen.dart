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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gói tập'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () =>
                context.read<PackageProvider>().fetch(status: _status),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm gói tập',
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
          // ====== FILTER + TỔNG QUAN ======
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng trạng thái + tổng số
                  Row(
                    children: [
                      const Text(
                        'Trạng thái:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _status,
                        underline: const SizedBox(),
                        hint: const Text('Tất cả'),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Đang bán'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Tạm ẩn'),
                          ),
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
                      const Spacer(),
                      if (!vm.loading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Tổng: ${vm.items.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quản lý các gói tập đang bán, tạm ẩn hoặc ngừng kinh doanh.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // ====== DANH SÁCH GÓI TẬP ======
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        vm.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : vm.items.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: vm.items.length,
                    itemBuilder: (ctx, i) {
                      final p = vm.items[i];
                      return _packageCard(context, p, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ====== CARD GÓI TẬP ======

  Widget _packageCard(
    BuildContext context,
    PackageModel p,
    ColorScheme colorScheme,
  ) {
    final statusColor = _statusColor(p.status, colorScheme);
    final statusText = _statusVi(p.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final ok = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => SavePackageScreen(editing: p)),
            );
            if (!context.mounted) return;
            if (ok == true) {
              context.read<PackageProvider>().fetch(status: _status);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon trái
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 22,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),

                // Nội dung chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên gói
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Giá + thời lượng
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.duration} ngày',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.payments,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.price} VND',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Chip trạng thái
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
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

                // Actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => _openPackageMenu(context, p),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPackageMenu(BuildContext context, PackageModel p) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Chỉnh sửa gói tập'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xoá gói tập',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;

    if (action == 'edit') {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => SavePackageScreen(editing: p)),
      );
      if (!context.mounted) return;
      if (ok == true) {
        context.read<PackageProvider>().fetch(status: _status);
      }
    } else if (action == 'delete') {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Xoá không thành công')));
        }
      }
    }
  }

  // ====== EMPTY STATE ======

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có gói tập nào',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hãy bấm nút dấu "+" ở góc trên để thêm gói tập đầu tiên.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ====== STATUS HELPER ======

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

  Color _statusColor(String s, ColorScheme scheme) {
    switch (s) {
      case 'active':
        return Colors.green.shade600;
      case 'inactive':
        return Colors.orange.shade700;
      case 'discontinued':
        return Colors.red.shade600;
      default:
        return scheme.primary;
    }
  }
}

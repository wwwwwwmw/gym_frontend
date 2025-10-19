import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'discount_provider.dart';
import 'discount_model.dart';
import 'save_discount_screen.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key});

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  String? _status;
  String? _type;
  String? _validity; // permanent | once | range

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DiscountProvider>().fetch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã giảm giá'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DiscountProvider>().fetch(
              status: _status,
              type: _type,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const SaveDiscountScreen()),
              );
              if (!context.mounted) return;
              if (ok == true) {
                context.read<DiscountProvider>().fetch(
                  status: _status,
                  type: _type,
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
                DropdownButton<String>(
                  value: _status,
                  hint: const Text('Trạng thái'),
                  items: const [
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Đang hoạt động'),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Ngừng hoạt động'),
                    ),
                    DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v);
                    context.read<DiscountProvider>().fetch(
                      status: v,
                      type: _type,
                    );
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _type,
                  hint: const Text('Loại giảm giá'),
                  items: const [
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Phần trăm'),
                    ),
                    DropdownMenuItem(value: 'fixed', child: Text('Số tiền')),
                  ],
                  onChanged: (v) {
                    setState(() => _type = v);
                    context.read<DiscountProvider>().fetch(
                      status: _status,
                      type: v,
                    );
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _validity,
                  hint: const Text('Hiệu lực'),
                  items: const [
                    DropdownMenuItem(
                      value: 'permanent',
                      child: Text('Vĩnh viễn'),
                    ),
                    DropdownMenuItem(value: 'once', child: Text('Một lần')),
                    DropdownMenuItem(
                      value: 'range',
                      child: Text('Từ ngày - đến ngày'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _validity = v),
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
                    itemCount: vm.items
                        .where((d) => _validity == null || _validity == _vOf(d))
                        .length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final list = vm.items
                          .where(
                            (d) => _validity == null || _validity == _vOf(d),
                          )
                          .toList();
                      return _tile(context, list[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, DiscountModel d) {
    final validity = _vOf(d);
    return ListTile(
      title: Text(d.name),
      subtitle: Text(
        '${_typeVi(d.type)} • ${d.value} • ${_statusVi(d.status)} • ${_validityVi(validity)}',
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
                  builder: (_) => SaveDiscountScreen(editing: d),
                ),
              );
              if (!context.mounted) return;
              if (ok == true) {
                context.read<DiscountProvider>().fetch(
                  status: _status,
                  type: _type,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Xoá mã giảm giá?'),
                  content: Text('Bạn có chắc muốn xoá "${d.name}"?'),
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
                final done = await context.read<DiscountProvider>().remove(
                  d.id,
                );
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

  String _vOf(DiscountModel d) {
    if (d.maxUsageCount == 1) return 'once';
  final startUtc = DateTime.utc(d.startDate.year, d.startDate.month, d.startDate.day);
  final endUtc = DateTime.utc(d.endDate.year, d.endDate.month, d.endDate.day);
  final isPermanent = startUtc.isAtSameMomentAs(DateTime.utc(1970, 1, 1)) &&
    endUtc.isAtSameMomentAs(DateTime.utc(2099, 12, 31));
    return isPermanent ? 'permanent' : 'range';
  }

  String _typeVi(String t) => t == 'percentage' ? 'Phần trăm' : 'Số tiền';
  String _statusVi(String s) {
    switch (s) {
      case 'active':
        return 'Đang hoạt động';
      case 'inactive':
        return 'Ngừng hoạt động';
      case 'expired':
        return 'Hết hạn';
      default:
        return s;
    }
  }

  String _validityVi(String v) {
    switch (v) {
      case 'permanent':
        return 'Vĩnh viễn';
      case 'once':
        return 'Một lần';
      case 'range':
        return 'Từ ngày - đến ngày';
      default:
        return v;
    }
  }
}

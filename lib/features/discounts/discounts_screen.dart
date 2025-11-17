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
    final colorScheme = Theme.of(context).colorScheme;

    // Lọc theo hiệu lực (local filter)
    final filtered = vm.items
        .where((d) => _validity == null || _validity == _vOf(d))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã giảm giá'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => context.read<DiscountProvider>().fetch(
              status: _status,
              type: _type,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm mã giảm giá',
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
          // ====== FILTER CARD ======
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Trạng thái
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _status,
                            isExpanded: true,
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
                              DropdownMenuItem(
                                value: 'expired',
                                child: Text('Hết hạn'),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _status = v);
                              context.read<DiscountProvider>().fetch(
                                status: v,
                                type: _type,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Loại
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _type,
                            isExpanded: true,
                            hint: const Text('Loại giảm giá'),
                            items: const [
                              DropdownMenuItem(
                                value: 'percentage',
                                child: Text('Phần trăm'),
                              ),
                              DropdownMenuItem(
                                value: 'fixed',
                                child: Text('Số tiền'),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _type = v);
                              context.read<DiscountProvider>().fetch(
                                status: _status,
                                type: v,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Hiệu lực
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _validity,
                            isExpanded: true,
                            hint: const Text('Hiệu lực'),
                            items: const [
                              DropdownMenuItem(
                                value: 'permanent',
                                child: Text('Vĩnh viễn'),
                              ),
                              DropdownMenuItem(
                                value: 'once',
                                child: Text('Một lần'),
                              ),
                              DropdownMenuItem(
                                value: 'range',
                                child: Text('Theo ngày'),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _validity = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            'Tổng: ${filtered.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ====== LIST ======
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
                : filtered.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final d = filtered[i];
                      return _discountCard(context, d, colorScheme, i == 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ====== CARD MÃ GIẢM GIÁ ======
  Widget _discountCard(
    BuildContext context,
    DiscountModel d,
    ColorScheme scheme,
    bool isFirst,
  ) {
    final validity = _vOf(d);
    final statusText = _statusVi(d.status);
    final statusColor = _statusColor(d.status);
    final typeText = _typeVi(d.type);
    final validityText = _validityVi(validity);

    String valueDisplay;
    if (d.type == 'percentage') {
      valueDisplay = '${d.value}%';
    } else {
      valueDisplay = '${d.value} VND';
    }

    String? dateRange;
    if (validity == 'range') {
      final s = _shortDate(d.startDate);
      final e = _shortDate(d.endDate);
      dateRange = '$s → $e';
    }

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 0, bottom: 12),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_offer, color: scheme.primary, size: 22),
              ),
              const SizedBox(width: 10),

              // Nội dung chính
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên + trị giá
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          valueDisplay,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Loại + hiệu lực text
                    Text(
                      '$typeText • $validityText',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    if (dateRange != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateRange,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Chips trạng thái + hiệu lực
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            validityText,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions (sửa / xoá)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
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
                    icon: const Icon(Icons.delete_outline, size: 20),
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
                        final done = await context
                            .read<DiscountProvider>()
                            .remove(d.id);
                        if (!context.mounted) return;
                        if (!done) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Xoá không thành công'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
              Icons.local_offer_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có mã giảm giá nào',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hãy bấm nút "+" ở góc trên bên phải để tạo mã giảm giá mới.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ====== HELPERS ======

  String _vOf(DiscountModel d) {
    if (d.maxUsageCount == 1) return 'once';

    final startUtc = DateTime.utc(
      d.startDate.year,
      d.startDate.month,
      d.startDate.day,
    );
    final endUtc = DateTime.utc(d.endDate.year, d.endDate.month, d.endDate.day);
    final isPermanent =
        startUtc.isAtSameMomentAs(DateTime.utc(1970, 1, 1)) &&
        endUtc.isAtSameMomentAs(DateTime.utc(2099, 12, 31));
    return isPermanent ? 'permanent' : 'range';
  }

  String _shortDate(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month';
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
        return 'Theo ngày';
      default:
        return v;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return Colors.green.shade600;
      case 'inactive':
        return Colors.orange.shade700;
      case 'expired':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade700;
    }
  }
}

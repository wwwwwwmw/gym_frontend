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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<RegistrationProvider>().fetch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistrationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký gói'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () =>
                context.read<RegistrationProvider>().fetch(status: _status),
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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            child: Text('Đang hoạt động'),
                          ),
                          DropdownMenuItem(
                            value: 'suspended',
                            child: Text('Tạm dừng'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Đã huỷ'),
                          ),
                          DropdownMenuItem(
                            value: 'expired',
                            child: Text('Hết hạn'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _status = v);
                          context.read<RegistrationProvider>().fetch(status: v);
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
                    'Theo dõi các đăng ký gói tập của hội viên.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // ====== DANH SÁCH ĐĂNG KÝ ======
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
                      final r = vm.items[i];
                      return _registrationCard(context, r, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ====== CARD ĐĂNG KÝ ======

  Widget _registrationCard(
    BuildContext context,
    RegistrationModel r,
    ColorScheme scheme,
  ) {
    final memberName = r.member.fullName.isNotEmpty
        ? r.member.fullName
        : '(Không tên)';
    final packageName = r.package.name.isNotEmpty
        ? r.package.name
        : '(Gói tập)';
    final statusText = _statusVi(r.status);
    final statusColor = _statusColor(r.status, scheme);

    String? dateRange;
    try {
      final start = r.startDate; // nếu model của bạn khác tên, sửa lại
      final end = r.endDate;
      if (start != null && end != null) {
        final s =
            '${start.day.toString().padLeft(2, '0')}/'
            '${start.month.toString().padLeft(2, '0')}';
        final e =
            '${end.day.toString().padLeft(2, '0')}/'
            '${end.month.toString().padLeft(2, '0')}';
        dateRange = '$s - $e';
      }
    } catch (_) {
      dateRange = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegistrationViewScreen(id: r.id),
              ),
            );
            if (!context.mounted) return;
            context.read<RegistrationProvider>().fetch(status: _status);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên khách
                      Text(
                        memberName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Tên gói + giá
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              packageName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${r.finalPrice} VND',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Ngày dùng
                      if (dateRange != null)
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

                      const SizedBox(height: 6),

                      // Chip trạng thái
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
                ),

                // Icon mũi tên
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, top: 4),
                  child: Icon(Icons.chevron_right, size: 20),
                ),
              ],
            ),
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
              Icons.receipt_long_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có đăng ký gói nào',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Khi hội viên đăng ký gói tập, thông tin sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ====== STATUS HELPERS ======

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

  Color _statusColor(String s, ColorScheme scheme) {
    switch (s) {
      case 'active':
        return Colors.green.shade600;
      case 'suspended':
        return Colors.orange.shade700;
      case 'cancelled':
        return Colors.red.shade600;
      case 'expired':
        return Colors.grey.shade700;
      default:
        return scheme.primary;
    }
  }
}

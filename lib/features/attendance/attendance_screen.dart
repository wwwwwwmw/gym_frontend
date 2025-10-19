import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'attendance_provider.dart';
import 'attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _status;
  final _memberIdCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AttendanceProvider>();
      vm.fetch();
      vm.fetchOverview();
    });
  }

  @override
  void dispose() {
    _memberIdCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AttendanceProvider>().fetch(status: _status);
              context.read<AttendanceProvider>().fetchOverview();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (vm.overview != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                children: [
                  _chip('Hôm nay check-in', vm.overview!.totalCheckins),
                  _chip('Đang trong phòng tập', vm.overview!.currentlyInGym),
                  _chip('Phút trung bình', vm.overview!.avgWorkoutDuration),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Trạng thái:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  hint: const Text('Tất cả'),
                  items: const [
                    DropdownMenuItem(
                      value: 'checked_in',
                      child: Text('Đã check-in'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Đã hoàn tất'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v);
                    context.read<AttendanceProvider>().fetch(status: v);
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _memberIdCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Mã khách hàng',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Check-in',
                  icon: const Icon(Icons.login),
                  onPressed: () async {
                    final ok = await context.read<AttendanceProvider>().checkIn(
                      _memberIdCtrl.text.trim(),
                      note: _noteCtrl.text.trim(),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Check-in thành công' : 'Check-in thất bại',
                        ),
                      ),
                    );
                    if (ok) {
                      context.read<AttendanceProvider>().fetch(status: _status);
                      context.read<AttendanceProvider>().fetchOverview();
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Check-out',
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    final ok = await context
                        .read<AttendanceProvider>()
                        .checkOut(
                          _memberIdCtrl.text.trim(),
                          note: _noteCtrl.text.trim(),
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Check-out thành công' : 'Check-out thất bại',
                        ),
                      ),
                    );
                    if (ok) {
                      context.read<AttendanceProvider>().fetch(status: _status);
                      context.read<AttendanceProvider>().fetchOverview();
                    }
                  },
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ghi chú (tuỳ chọn)',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _chip(String label, int value) {
    return Chip(label: Text('$label: $value'));
  }

  Widget _tile(BuildContext context, AttendanceModel a) {
    final subtitle = a.checkoutTime == null
        ? 'Đang tập • từ ${a.checkinTime.toLocal().toString().substring(11, 16)}'
        : 'Đã xong • ${a.workoutDurationMinutes ?? 0} phút';
    return ListTile(
      title: Text(a.memberName ?? a.memberId),
      subtitle: Text(subtitle),
      trailing: Text(a.status == 'checked_in' ? 'Đã check-in' : 'Đã hoàn tất'),
    );
  }
}

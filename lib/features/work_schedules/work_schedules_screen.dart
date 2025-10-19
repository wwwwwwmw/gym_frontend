import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'work_schedule_provider.dart';
import 'work_schedule_model.dart';

class WorkSchedulesScreen extends StatefulWidget {
  const WorkSchedulesScreen({super.key});

  @override
  State<WorkSchedulesScreen> createState() => _WorkSchedulesScreenState();
}

class _WorkSchedulesScreenState extends State<WorkSchedulesScreen> {
  DateTime? _date;
  String? _status;
  String? _shiftType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<WorkScheduleProvider>().fetchMy(),
    );
  }

  Future<void> _pickDate() async {
    final initial = _date ?? DateTime.now();
    final provider = context.read<WorkScheduleProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final iso = DateTime(
        picked.year,
        picked.month,
        picked.day,
      ).toIso8601String();
      if (!mounted) return;
      setState(() => _date = picked);
      provider.fetchMy(
        date: iso.substring(0, 10),
        status: _status,
        shiftType: _shiftType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkScheduleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch làm việc của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<WorkScheduleProvider>().fetchMy(
              date: _date != null
                  ? DateTime(
                      _date!.year,
                      _date!.month,
                      _date!.day,
                    ).toIso8601String().substring(0, 10)
                  : null,
              status: _status,
              shiftType: _shiftType,
            ),
          ),
          IconButton(
            tooltip: 'Bỏ lọc',
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () {
              setState(() {
                _date = null;
                _status = null;
                _shiftType = null;
              });
              context.read<WorkScheduleProvider>().fetchMy();
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
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _date == null
                        ? 'Chọn ngày'
                        : '${_date!.toLocal()}'.split(' ')[0],
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  hint: const Text('Trạng thái'),
                  items: const [
                    DropdownMenuItem(
                      value: 'scheduled',
                      child: Text('Đã xếp lịch'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Hoàn thành'),
                    ),
                    DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                    DropdownMenuItem(value: 'absent', child: Text('Vắng mặt')),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v);
                    context.read<WorkScheduleProvider>().fetchMy(
                      date: _date != null
                          ? DateTime(
                              _date!.year,
                              _date!.month,
                              _date!.day,
                            ).toIso8601String().substring(0, 10)
                          : null,
                      status: v,
                      shiftType: _shiftType,
                    );
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _shiftType,
                  hint: const Text('Ca làm'),
                  items: const [
                    DropdownMenuItem(value: 'morning', child: Text('Sáng')),
                    DropdownMenuItem(value: 'afternoon', child: Text('Chiều')),
                    DropdownMenuItem(value: 'evening', child: Text('Tối')),
                    DropdownMenuItem(value: 'night', child: Text('Đêm')),
                    DropdownMenuItem(value: 'full-day', child: Text('Cả ngày')),
                  ],
                  onChanged: (v) {
                    setState(() => _shiftType = v);
                    context.read<WorkScheduleProvider>().fetchMy(
                      date: _date != null
                          ? DateTime(
                              _date!.year,
                              _date!.month,
                              _date!.day,
                            ).toIso8601String().substring(0, 10)
                          : null,
                      status: _status,
                      shiftType: v,
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
                : vm.items.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        itemCount: vm.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) => _tile(vm.items[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tile(WorkScheduleModel s) {
    return ListTile(
      title: Text('${s.date.toLocal()}'.split(' ')[0]),
      subtitle: Text(
        '${s.startTime} - ${s.endTime} • ${_shiftVi(s.shiftType)} • ${_statusVi(s.status)}'
        '${s.employeeName != null ? ' • ${s.employeeName}' : ''}'
        '${s.notes != null && s.notes!.isNotEmpty ? ' • ${s.notes}' : ''}',
      ),
    );
  }

  String _statusVi(String v) {
    switch (v) {
      case 'scheduled':
        return 'Đã xếp lịch';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'absent':
        return 'Vắng mặt';
      default:
        return v;
    }
  }

  String _shiftVi(String v) {
    switch (v) {
      case 'morning':
        return 'Sáng';
      case 'afternoon':
        return 'Chiều';
      case 'evening':
        return 'Tối';
      case 'night':
        return 'Đêm';
      case 'full-day':
        return 'Cả ngày';
      default:
        return v;
    }
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Chưa có lịch làm việc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quản lý cần tạo lịch làm việc cho bạn.\n' 
              'Bạn cũng có thể thử bỏ lọc rồi tải lại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _date = null;
                  _status = null;
                  _shiftType = null;
                });
                context.read<WorkScheduleProvider>().fetchMy();
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Bỏ lọc và tải lại'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'attendance_provider.dart';
import 'attendance_model.dart';
import '../../core/api_client.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        centerTitle: true,
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
          // ====== KHỐI FILTER + Ô NHẬP MÃ ======
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng trạng thái
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
                            value: 'checked_in',
                            child: Text('Đang tập'),
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
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ô nhập mã + nút chọn HV + nút checkin/checkout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memberIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Mã khách hàng / SĐT',
                            hintText: 'VD: 0903xxxxxx hoặc mã thẻ',
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Nút mở danh sách hội viên
                      InkWell(
                        onTap: _openMemberPicker,
                        borderRadius: BorderRadius.circular(999),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.search, color: colorScheme.error),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Nút check-in
                      InkWell(
                        onTap: _onCheckIn,
                        borderRadius: BorderRadius.circular(999),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.error,
                          child: const Icon(Icons.login, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Nút check-out
                      InkWell(
                        onTap: _onCheckOut,
                        borderRadius: BorderRadius.circular(999),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(
                            Icons.logout,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (tuỳ chọn)',
                      filled: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====== CHIP OVERVIEW HÔM NAY ======
          if (vm.overview != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Hôm nay check-in', vm.overview!.totalCheckins),
                  _chip('Đang trong phòng tập', vm.overview!.currentlyInGym),
                  _chip('Phút trung bình', vm.overview!.avgWorkoutDuration),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ====== DANH SÁCH ĐIỂM DANH ======
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? Center(
                    child: Text(
                      vm.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: vm.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) => _tile(context, vm.items[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // =================== ACTIONS ===================

  Future<void> _onCheckIn() async {
    final code = _memberIdCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập mã khách hàng / SĐT trước')),
      );
      return;
    }
    final ok = await context.read<AttendanceProvider>().checkIn(
      code,
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Check-in thành công' : 'Check-in thất bại')),
    );
    if (ok) {
      context.read<AttendanceProvider>().fetch(status: _status);
      context.read<AttendanceProvider>().fetchOverview();
      _noteCtrl.clear();
    }
  }

  Future<void> _onCheckOut() async {
    final code = _memberIdCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập mã khách hàng / SĐT trước')),
      );
      return;
    }
    final ok = await context.read<AttendanceProvider>().checkOut(
      code,
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Check-out thành công' : 'Check-out thất bại'),
      ),
    );
    if (ok) {
      context.read<AttendanceProvider>().fetch(status: _status);
      context.read<AttendanceProvider>().fetchOverview();
      _noteCtrl.clear();
    }
  }

  // =================== PICKER HỘI VIÊN ===================

  Future<void> _openMemberPicker() async {
    final selected = await showModalBottomSheet<MemberLite>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _MemberPickerSheet();
      },
    );

    if (selected != null) {
      // Ưu tiên fill theo SĐT, nếu không có thì dùng id
      _memberIdCtrl.text = selected.phone ?? selected.id;
    }
  }

  // =================== WIDGET PHỤ ===================

  Widget _chip(String label, int value) {
    return Chip(
      label: Text('$label: $value'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _tile(BuildContext context, AttendanceModel a) {
    final isInGym = a.checkoutTime == null;
    final timeStr = a.checkinTime.toLocal().toString().substring(11, 16);
    final subtitle = isInGym
        ? 'Đang tập • từ $timeStr'
        : 'Đã xong • ${a.workoutDurationMinutes ?? 0} phút';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isInGym ? Colors.green.shade50 : Colors.grey.shade200,
        child: Icon(
          isInGym ? Icons.fitness_center : Icons.check,
          color: isInGym ? Colors.green : Colors.grey.shade700,
        ),
      ),
      title: Text(a.memberName ?? a.memberId),
      subtitle: Text(subtitle),
      trailing: Text(
        isInGym ? 'Đang tập' : 'Đã hoàn tất',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isInGym ? Colors.green : Colors.grey.shade800,
        ),
      ),
    );
  }
}

/// Model nhẹ dùng cho picker
class MemberLite {
  final String id;
  final String name;
  final String? phone;

  MemberLite({required this.id, required this.name, this.phone});

  factory MemberLite.fromJson(Map<String, dynamic> json) {
    return MemberLite(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name:
          json['fullName']?.toString() ??
          json['name']?.toString() ??
          'Không tên',
      phone: json['phone']?.toString(),
    );
  }
}

/// BottomSheet chọn hội viên
class _MemberPickerSheet extends StatefulWidget {
  @override
  State<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<_MemberPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _api = ApiClient();
  bool _loading = false;
  String? _error;
  List<MemberLite> _items = const [];

  @override
  void initState() {
    super.initState();
    _load(); // load danh sách lần đầu
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getJson(
        '/api/members',
        query: {
          if (_searchCtrl.text.trim().isNotEmpty)
            'keyword': _searchCtrl.text.trim(),
          'limit': '20',
          'page': '1',
        },
      );

      final raw =
          res['items'] ??
          res['members'] ??
          res['data'] ??
          res; // để tương thích nhiều kiểu response

      final list = (raw as List)
          .map((e) => MemberLite.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        _items = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: 480,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn học viên',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên / SĐT / mã...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _load();
                    },
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  : _items.isEmpty
                  ? const Center(child: Text('Không tìm thấy học viên nào'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = _items[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(m.name),
                          subtitle: Text(
                            m.phone != null && m.phone!.isNotEmpty
                                ? m.phone!
                                : m.id,
                          ),
                          onTap: () {
                            Navigator.of(context).pop(m);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'attendance_provider.dart';
import 'attendance_model.dart';
import '../../core/api_client.dart';
import 'qr_checkin_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _status;
  final _memberIdCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  /// id thành viên được chọn để check-out
  String? _selectedMemberId;

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

    // Gom lại để mỗi học viên chỉ còn 1 bản ghi mới nhất
    final latestList = _buildLatestPerMember(vm.items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Quét QR',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final ok = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrCheckInScreen()),
              );
              if (ok == true) {
                if (!mounted) return;
                final vm = context.read<AttendanceProvider>();
                vm.fetch(status: _status);
                vm.fetchOverview();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedMemberId = null;
              });
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
                          setState(() {
                            _status = v;
                            _selectedMemberId = null;
                          });
                          context.read<AttendanceProvider>().fetch(status: v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ô nhập mã + nút chọn HV + check-in / check-out
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memberIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Mã khách hàng / SĐT (Check-in)',
                            hintText: 'VD: 0903xxxxxx hoặc mã thẻ',
                            filled: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Nút mở bottom sheet chọn học viên
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

                      // Nút CHECK-IN
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

                      // Nút CHECK-OUT (chỉ sáng khi chọn học viên đang tập)
                      InkWell(
                        onTap: _selectedMemberId == null ? null : _onCheckOut,
                        borderRadius: BorderRadius.circular(999),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: _selectedMemberId == null
                              ? Colors.grey.shade300
                              : Colors.green.shade600,
                          child: Icon(
                            Icons.logout,
                            color: _selectedMemberId == null
                                ? Colors.black87
                                : Colors.white,
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
                  const SizedBox(height: 4),
                  const Text(
                    '• Check-in: nhập mã khách hàng / SĐT rồi bấm nút check-in.\n'
                    '• Check-out: bấm chọn học viên đang tập trong danh sách → nút check-out sẽ sáng lên.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // ====== OVERVIEW HÔM NAY ======
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

          // ====== DANH SÁCH (MỖI NGƯỜI 1 DÒNG) ======
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
                    itemCount: latestList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) => _tile(context, latestList[i]),
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

    final vm = context.read<AttendanceProvider>();
    final ok = await vm.checkIn(code, note: _noteCtrl.text.trim());

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Check-in thành công')));
      vm.fetch(status: _status);
      vm.fetchOverview();
      _memberIdCtrl.clear();
      _noteCtrl.clear();
    } else {
      final msg = vm.lastErrorMessage ?? 'Check-in thất bại';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _onCheckOut() async {
    final selectedId = _selectedMemberId;
    if (selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy chọn 1 học viên đang tập để check-out'),
        ),
      );
      return;
    }

    final vm = context.read<AttendanceProvider>();
    final ok = await vm.checkOut(selectedId, note: _noteCtrl.text.trim());

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Check-out thành công')));
      setState(() => _selectedMemberId = null);
      vm.fetch(status: _status);
      vm.fetchOverview();
      _noteCtrl.clear();
    } else {
      final msg = vm.lastErrorMessage ?? 'Check-out thất bại';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      builder: (ctx) => _MemberPickerSheet(),
    );

    if (selected != null) {
      // Ưu tiên fill SĐT, nếu không có thì dùng id
      _memberIdCtrl.text = selected.phone ?? selected.id;
    }
  }

  // =================== UI PHỤ ===================

  Widget _chip(String label, int value) {
    return Chip(
      label: Text('$label: $value'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _tile(BuildContext context, AttendanceModel a) {
    final isInGym = a.checkoutTime == null;
    final selected = _selectedMemberId == a.memberId;

    final timeStr = a.checkinTime.toLocal().toString().substring(11, 16);
    final subtitle = isInGym
        ? 'Đang tập • từ $timeStr'
        : 'Đã xong • ${a.workoutDurationMinutes ?? 0} phút';

    return InkWell(
      onTap: () {
        if (!isInGym) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Học viên này đã hoàn tất buổi tập')),
          );
          return;
        }

        setState(() {
          _selectedMemberId = selected ? null : a.memberId;
        });
      },
      child: Container(
        color: selected ? Colors.green.shade50 : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isInGym
                ? Colors.green.shade50
                : Colors.grey.shade200,
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
        ),
      ),
    );
  }

  /// Mỗi học viên chỉ còn 1 dòng – bản ghi mới nhất
  List<AttendanceModel> _buildLatestPerMember(List<AttendanceModel> list) {
    final Map<String, AttendanceModel> map = {};

    for (final a in list) {
      final key = a.memberId;
      final existing = map[key];
      if (existing == null) {
        map[key] = a;
      } else {
        if (a.checkinTime.isAfter(existing.checkinTime)) {
          map[key] = a;
        }
      }
    }

    final result = map.values.toList()
      ..sort((a, b) => b.checkinTime.compareTo(a.checkinTime));

    return result;
  }
}

/// Model nhẹ dùng để pick hội viên
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

/// BottomSheet chọn hội viên – chỉ hiện member có gói tập đang hoạt động
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
    _load(); // load lần đầu
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final query = <String, String>{
        'limit': '20',
        'page': '1',
        // 🔴 Chỉ lấy member có gói tập đang hoạt động
        'hasActivePackage': 'true',
      };

      final keyword = _searchCtrl.text.trim();
      if (keyword.isNotEmpty) {
        // backend MemberService dùng param 'search'
        query['search'] = keyword;
      }

      final res = await _api.getJson('/api/members', query: query);

      final raw = res['members'] ?? res['items'] ?? res['data'] ?? res;

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
              'Chọn học viên (đã có gói tập)',
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
                  ? const Center(
                      child: Text(
                        'Không tìm thấy học viên nào có gói tập đang hoạt động',
                      ),
                    )
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
                            m.phone?.isNotEmpty == true ? m.phone! : m.id,
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

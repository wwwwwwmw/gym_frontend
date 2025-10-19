import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/registrations/registration_model.dart';
import 'package:gym_frontend/features/registrations/registration_service.dart';

class MyStudentsScreen extends StatefulWidget {
  const MyStudentsScreen({super.key});

  @override
  State<MyStudentsScreen> createState() => _MyStudentsScreenState();
}

class _MyStudentsScreenState extends State<MyStudentsScreen> {
  final _svc = RegistrationService(ApiClient());
  bool _loading = true;
  String? _error;
  String? _status;
  int _page = 1;
  int _pages = 1;
  List<RegistrationModel> _items = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (list, pageInfo) = await _svc.listMineAsTrainer(
        status: _status,
        page: page,
        limit: 20,
      );
      setState(() {
        _items = list;
        _page = pageInfo['page'] ?? 1;
        _pages = pageInfo['pages'] ?? 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học viên của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetch(page: _page),
          )
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
                    DropdownMenuItem(value: 'pending', child: Text('Chờ duyệt')),
                    DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                    DropdownMenuItem(value: 'suspended', child: Text('Tạm dừng')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                    DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v);
                    _fetch(page: 1);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(child: Text('Chưa có học viên'))
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) => _tile(_items[i]),
                          ),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1 ? () => _fetch(page: _page - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Trang $_page/$_pages'),
                  IconButton(
                    onPressed: _page < _pages ? () => _fetch(page: _page + 1) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile(RegistrationModel r) {
    final start = r.startDate.toLocal().toString().split(' ').first;
    final end = r.endDate.toLocal().toString().split(' ').first;
    final dayNames = {
      1: 'Thứ 2', 2: 'Thứ 3', 3: 'Thứ 4', 4: 'Thứ 5', 5: 'Thứ 6', 6: 'Thứ 7', 7: 'Chủ nhật'
    };
    String prefsText = '';
    if (r.memberPreferredDays != null && r.memberPreferredDays!.isNotEmpty) {
      final names = r.memberPreferredDays!..sort();
      prefsText = ' • ${names.map((d) => dayNames[d] ?? d.toString()).join(', ')}'
          + (r.memberPreferredShift != null
              ? ' • Ca: ${r.memberPreferredShift == 'afternoon' ? 'Chiều' : 'Sáng'}'
              : '');
    }
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(r.member.fullName.isNotEmpty ? r.member.fullName : '(Không rõ tên)'),
      subtitle: Text('${r.package.name} • $start → $end • ${_statusVi(r.status)}$prefsText'),
    );
  }

  String _statusVi(String s) {
    switch (s) {
      case 'pending':
        return 'Chờ duyệt';
      case 'active':
        return 'Hoạt động';
      case 'suspended':
        return 'Tạm dừng';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return s;
    }
  }
}

import 'package:flutter/material.dart';
import '../registrations/registration_service.dart';
import '../registrations/registration_model.dart';
import '../../core/api_client.dart';
import '../packages/package_detail_screen.dart';
import '../packages/package_model.dart';

class MemberCurrentPackageScreen extends StatefulWidget {
  const MemberCurrentPackageScreen({super.key});

  @override
  State<MemberCurrentPackageScreen> createState() =>
      _MemberCurrentPackageScreenState();
}

class _MemberCurrentPackageScreenState
    extends State<MemberCurrentPackageScreen> {
  bool _loading = true;
  String? _error;
  List<RegistrationModel> _active = const [];
  List<RegistrationModel> _prebooked = const [];
  List<RegistrationModel> _pending = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = RegistrationService(ApiClient());
      final list = await svc.getSelfActive();
      // Split: showing pending as prebooked if start date in future
      final now = DateTime.now();
      final active = <RegistrationModel>[];
      final pre = <RegistrationModel>[];
      final pending = <RegistrationModel>[];
      for (final r in list) {
        if (r.status == 'active') {
          active.add(r);
        } else if (r.status == 'pending' && r.startDate.isAfter(now)) {
          pre.add(r);
        } else if (r.status == 'pending') {
          pending.add(r);
        }
      }
      setState(() { _active = active; _prebooked = pre; _pending = pending; });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gói tập hiện tại')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _active.isEmpty && _prebooked.isEmpty && _pending.isEmpty
          ? _empty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  if (_active.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Đang hoạt động', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ..._active.map(_tileActive),
                    const Divider(height: 24),
                  ],
                  if (_prebooked.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Đã đặt trước (chưa tới ngày)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ..._prebooked.map(_tilePrebooked),
                    const Divider(height: 24),
                  ],
                  if (_pending.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Chờ duyệt (đã tới ngày)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ..._pending.map(_tilePending),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bạn chưa có gói tập nào đang hoạt động.'),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pushNamed('/member/register-package'),
          child: const Text('Đăng ký gói tập'),
        ),
      ],
    ),
  );

  Widget _tileActive(RegistrationModel r) {
    return ListTile(
      leading: const Icon(Icons.fitness_center),
      title: Text(r.package.name),
      subtitle: Text(
        'Từ: ${r.startDate.toLocal().toString().split(' ').first} • Đến: ${r.endDate.toLocal().toString().split(' ').first}\nTrạng thái: ${r.status.toUpperCase()}',
      ),
      trailing: Text('${r.finalPrice}đ'),
      onTap: () {
        final pkg = PackageModel(
          id: r.package.id,
          name: r.package.name,
          description: null,
          duration: r.package.duration ?? 0,
          price: r.package.price ?? r.finalPrice,
          features: const [],
          status: 'active',
          maxSessions: null,
          isPersonalTraining: false,
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PackageDetailScreen(package: pkg, currentRegistration: r),
        ));
      },
    );
  }

  Widget _tilePrebooked(RegistrationModel r) {
    return ListTile(
      leading: const Icon(Icons.schedule),
      title: Text(r.package.name),
      subtitle: Text(
        'Bắt đầu: ${r.startDate.toLocal().toString().split(' ').first} • Kết thúc: ${r.endDate.toLocal().toString().split(' ').first}\nTrạng thái: CHỜ DUYỆT',
      ),
      trailing: TextButton(
        child: const Text('Đổi ngày bắt đầu'),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: r.startDate,
            firstDate: DateTime.now().add(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked == null) return;
          try {
            final svc = RegistrationService(ApiClient());
            await svc.updateSelfStartDate(r.id, DateTime.utc(picked.year, picked.month, picked.day));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật ngày bắt đầu')), 
            );
            await _load();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${e.toString()}')),
            );
          }
        },
      ),
      onTap: () {
        final pkg = PackageModel(
          id: r.package.id,
          name: r.package.name,
          description: null,
          duration: r.package.duration ?? 0,
          price: r.package.price ?? r.finalPrice,
          features: const [],
          status: 'active',
          maxSessions: null,
          isPersonalTraining: false,
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PackageDetailScreen(package: pkg, currentRegistration: r),
        ));
      },
    );
  }

  Widget _tilePending(RegistrationModel r) {
    return ListTile(
      leading: const Icon(Icons.hourglass_top),
      title: Text(r.package.name),
      subtitle: Text(
        'Bắt đầu: ${r.startDate.toLocal().toString().split(' ').first} • Kết thúc: ${r.endDate.toLocal().toString().split(' ').first}\nTrạng thái: CHỜ DUYỆT',
      ),
      trailing: Text('${r.finalPrice}đ'),
      onTap: () {
        final pkg = PackageModel(
          id: r.package.id,
          name: r.package.name,
          description: null,
          duration: r.package.duration ?? 0,
          price: r.package.price ?? r.finalPrice,
          features: const [],
          status: 'active',
          maxSessions: null,
          isPersonalTraining: false,
        );
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PackageDetailScreen(package: pkg, currentRegistration: r),
        ));
      },
    );
  }
}

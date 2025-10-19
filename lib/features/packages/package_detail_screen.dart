import 'package:flutter/material.dart';
import 'package:gym_frontend/features/packages/package_model.dart';
import 'package:gym_frontend/features/registrations/registration_model.dart';
import 'package:gym_frontend/features/packages/package_service.dart';
import 'package:gym_frontend/core/api_client.dart';

class PackageDetailScreen extends StatefulWidget {
  const PackageDetailScreen({super.key, required this.package, this.currentRegistration});
  final PackageModel package;
  final RegistrationModel? currentRegistration; // to show trainer if PT package

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  PackageModel? _full;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final svc = PackageService(ApiClient());
      final got = await svc.getById(widget.package.id);
      if (!mounted) return;
      setState(() { _full = got; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _full ?? widget.package;
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(p.description ?? 'Không có mô tả'),
                    const SizedBox(height: 12),
                    _kv('Thời hạn', '${p.duration} ngày'),
                    _kv('Giá', '${p.price}đ'),
                    if (p.maxSessions != null) _kv('Số buổi', '${p.maxSessions}'),
                    const SizedBox(height: 12),
                    const Text('Tính năng bao gồm:'),
                    const SizedBox(height: 8),
                    ...p.features.map((f) => Row(
                          children: [
                            const Icon(Icons.check, size: 18, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(child: Text(f)),
                          ],
                        )),
                    if (p.isPersonalTraining) ...[
                      const Divider(height: 24),
                      const Text('Huấn luyện viên đã đăng ký'),
                      const SizedBox(height: 8),
                      _trainerTile(widget.currentRegistration),
                    ],
                  ],
                ),
    );
  }

  Widget _trainerTile(RegistrationModel? r) {
    if (r?.trainer == null) return const Text('Chưa có huấn luyện viên');
    final t = r!.trainer!;
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(t.fullName.isEmpty ? 'Huấn luyện viên' : t.fullName),
      subtitle: Text([
        if (t.email != null) 'Email: ${t.email}',
        if (t.phone != null) 'Phone: ${t.phone}',
      ].join(' • ')),
    );
  }

  // isPersonalTraining flag indicates PT package.

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
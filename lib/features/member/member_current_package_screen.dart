import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final _dateFmt = DateFormat('dd/MM/yyyy');

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

      setState(() {
        _active = active;
        _prebooked = pre;
        _pending = pending;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Gói tập hiện tại'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Không tải được dữ liệu.\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : _active.isEmpty && _prebooked.isEmpty && _pending.isEmpty
          ? _empty(colorScheme)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_active.isNotEmpty) ...[
                    _sectionTitle('Đang hoạt động'),
                    const SizedBox(height: 8),
                    ..._active.map(_tileActive),
                    const SizedBox(height: 24),
                  ],
                  if (_prebooked.isNotEmpty) ...[
                    _sectionTitle('Đã đặt trước (chưa tới ngày)'),
                    const SizedBox(height: 8),
                    ..._prebooked.map(_tilePrebooked),
                    const SizedBox(height: 24),
                  ],
                  if (_pending.isNotEmpty) ...[
                    _sectionTitle('Chờ duyệt (đã tới ngày)'),
                    const SizedBox(height: 8),
                    ..._pending.map(_tilePending),
                  ],
                ],
              ),
            ),
    );
  }

  // ===================== EMPTY STATE =====================

  Widget _empty(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa có gói tập nào đang hoạt động.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy đăng ký một gói tập để bắt đầu hành trình luyện tập của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/member/register-package'),
                child: const Text(
                  'Đăng ký gói tập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== COMMON HELPERS =====================

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  String _dateRange(RegistrationModel r) {
    return '${_dateFmt.format(r.startDate)}  •  ${_dateFmt.format(r.endDate)}';
  }

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required RegistrationModel r,
    required Widget statusChip,
    Widget? trailing,
    Widget? bottomRight,
  }) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _openPackageDetail(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 12),

            // CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÊN GÓI + STATUS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          r.package.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusChip,
                    ],
                  ),
                  const SizedBox(height: 4),
                  // KHOẢNG THỜI GIAN
                  Text(
                    _dateRange(r),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  // GIÁ
                  Text(
                    '${r.finalPrice.toStringAsFixed(0)} đ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.error,
                    ),
                  ),
                  if (bottomRight != null) ...[
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: bottomRight),
                  ],
                ],
              ),
            ),

            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  void _openPackageDetail(RegistrationModel r) {
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PackageDetailScreen(package: pkg, currentRegistration: r),
      ),
    );
  }

  // ===================== TILES =====================

  Widget _tileActive(RegistrationModel r) {
    return _buildCard(
      icon: Icons.fitness_center,
      iconBg: Colors.white,
      iconColor: Theme.of(context).colorScheme.error,
      r: r,
      statusChip: _statusChip(
        'ĐANG HOẠT ĐỘNG',
        const Color(0xFFE6F7EB),
        const Color(0xFF1A7F37),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _tilePrebooked(RegistrationModel r) {
    return _buildCard(
      icon: Icons.schedule,
      iconBg: Colors.white,
      iconColor: Colors.orange,
      r: r,
      statusChip: _statusChip(
        'ĐÃ ĐẶT TRƯỚC',
        const Color(0xFFFFF4E5),
        const Color(0xFFB36B00),
      ),
      bottomRight: TextButton(
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
            await svc.updateSelfStartDate(
              r.id,
              DateTime.utc(picked.year, picked.month, picked.day),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật ngày bắt đầu')),
            );
            await _load();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
          }
        },
        child: const Text('Đổi ngày bắt đầu'),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _tilePending(RegistrationModel r) {
    return _buildCard(
      icon: Icons.hourglass_top,
      iconBg: Colors.white,
      iconColor: Colors.amber.shade800,
      r: r,
      statusChip: _statusChip(
        'CHỜ DUYỆT',
        const Color(0xFFEFF4FF),
        const Color(0xFF1D4ED8),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../registrations/registration_service.dart';
import '../registrations/registration_model.dart';
import '../../core/api_client.dart';
import '../packages/package_detail_screen.dart';
import '../packages/package_model.dart';
import '../../core/env.dart';
import '../banners/banner_service.dart';
import '../banners/banner_model.dart';

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
  List<BannerModel> _banners = const [];

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
      final api = ApiClient();
      final svc = RegistrationService(api);
      final bannerSvc = BannerService(api);

      final list = await svc.getSelfActive();
      final banners = await bannerSvc.getBanners(position: 'packages');

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
        _banners = banners;
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

                  // BANNERS
                  if (_banners.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ..._banners.map(
                      (banner) => _buildBanner(banner, colorScheme),
                    ),
                  ],

                  const SizedBox(height: 32),
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

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final r = raw.trim();
    if (r.startsWith('http://') || r.startsWith('https://')) return r;
    // Treat as relative path from API base
    final base = apiBaseUrl();
    if (r.startsWith('/')) return '$base$r';
    return '$base/$r';
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
    final resolvedImage = _resolveImageUrl(r.package.imageUrl);
    final hasImage = resolvedImage != null;

    return GestureDetector(
      onTap: () => _openPackageDetail(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PACKAGE IMAGE (ở trên cùng như register screen)
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  resolvedImage,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 140,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER: ICON + NAME + STATUS + TRAILING
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasImage)
                        Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.fitness_center, color: cs.error),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.package.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            statusChip,
                          ],
                        ),
                      ),
                      if (trailing != null) trailing,
                    ],
                  ),

                  const SizedBox(height: 12),

                  // DATE RANGE & DURATION
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _dateRange(r),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (r.package.duration != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${r.package.duration} ngày',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // DESCRIPTION (if available)
                  if (r.package.description != null &&
                      r.package.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      r.package.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  if (r.trainer != null && r.trainer!.fullName.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Huấn luyện viên: ${r.trainer!.fullName}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // FEATURES (if available)
                  if (r.package.features != null &&
                      r.package.features!.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: r.package.features!
                          .take(3)
                          .map(
                            (feature) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // PRICE
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${r.finalPrice.toStringAsFixed(0)} đ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.error,
                          ),
                        ),
                      ),
                      if (r.discountAmount > 0)
                        Text(
                          '${r.originalPrice.toStringAsFixed(0)} đ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),

                  if (bottomRight != null) ...[
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: bottomRight),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPackageDetail(RegistrationModel r) {
    final pkg = PackageModel(
      id: r.package.id,
      name: r.package.name,
      description: r.package.description,
      duration: r.package.duration ?? 0,
      price: r.package.price ?? r.finalPrice,
      features: r.package.features ?? const [],
      status: 'active',
      maxSessions: null,
      isPersonalTraining: false,
      imageUrl: r.package.imageUrl,
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

  // ===================== BANNER =====================

  Widget _buildBanner(BannerModel banner, ColorScheme colorScheme) {
    final resolvedImage = _resolveImageUrl(banner.imageUrl);

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/member/register-package'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              if (resolvedImage != null)
                Image.network(
                  resolvedImage,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 160,
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),

              // Title overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

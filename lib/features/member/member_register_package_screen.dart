import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../discounts/discount_provider.dart';
import '../employees/employee_service.dart';
import '../packages/package_provider.dart';
import '../registrations/registration_service.dart';
import '../registrations/registration_model.dart';
import 'member_current_package_screen.dart';

class MemberRegisterPackageScreen extends StatefulWidget {
  const MemberRegisterPackageScreen({super.key});

  @override
  State<MemberRegisterPackageScreen> createState() =>
      _MemberRegisterPackageScreenState();
}

class _MemberRegisterPackageScreenState
    extends State<MemberRegisterPackageScreen> {
  String? _packageId;
  String? _discountId; // nullable allows "no discount"
  String? _trainerId; // nullable allows "no trainer"
  List<Map<String, String>> _trainers = const [];
  bool _submitting = false;
  bool _blocked = false; // has active or pending package
  String? _blockMsg;
  bool _prebook = false;
  DateTime? _currentEnd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load available packages and active discounts
      context.read<PackageProvider>().fetch();
      // Members should use the public active discounts endpoint to avoid 403
      await context.read<DiscountProvider>().fetchActivePublic();
      await _loadTrainers();
      await _checkBlock();
    });
  }

  Future<void> _loadTrainers() async {
    try {
      final svc = EmployeeService(ApiClient());
      final list = await svc.listActiveTrainers();
      if (!mounted) return;
      setState(() {
        _trainers = [
          for (final t in list) {'id': t.id, 'name': t.fullName},
        ];
      });
    } catch (_) {
      // ignore errors here; just show no trainers
    }
  }

  Future<void> _checkBlock() async {
    try {
      final svc = RegistrationService(ApiClient());
      final List<RegistrationModel> list = await svc.getSelfActive();
      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          _blocked = true;
          final p = list.first.package.name;
          _blockMsg = 'Bạn đang có gói tập hoạt động hoặc đang chờ duyệt${p.isNotEmpty ? ': $p' : ''}';
          _currentEnd = list.first.endDate;
        });
      } else {
        setState(() {
          _blocked = false;
          _blockMsg = null;
          _currentEnd = null;
        });
      }
    } catch (_) {
      // ignore check errors silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final pk = context.watch<PackageProvider>();
    final dc = context.watch<DiscountProvider>();
    final isPt = pk.items.any((e) => e.id == _packageId && e.isPersonalTraining);

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký gói tập')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_blocked && _blockMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_blockMsg!),
                        if (_currentEnd != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Gói hiện tại còn ${( _currentEnd!.difference(DateTime.now()).inDays ).clamp(0, 100000)} ngày (đến ${_currentEnd!.toLocal().toString().split(' ').first})',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        Row(
                          children: [
                            Checkbox(
                              value: _prebook,
                              onChanged: (v) => setState(() => _prebook = v ?? false),
                            ),
                            const Expanded(
                              child: Text('Đặt trước: tạo đăng ký mới bắt đầu ngay sau khi gói hiện tại kết thúc'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MemberCurrentPackageScreen(),
                        ),
                      );
                    },
                    child: const Text('Xem gói hiện tại'),
                  ),
                ],
              ),
            ),
          const Text('Chọn gói'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _packageId,
            items: [
              for (final p in pk.items)
                DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.name} • ${p.price}đ'),
                ),
            ],
            onChanged: (v) => setState(() {
              _packageId = v;
              // If newly selected package is not PT, clear any chosen trainer
              final idx = pk.items.indexWhere((e) => e.id == v);
              final selIsPt = idx >= 0 ? pk.items[idx].isPersonalTraining : false;
              if (!selIsPt) {
                _trainerId = null;
              }
            }),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text('Chọn mã giảm giá (tuỳ chọn)'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _discountId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Không áp dụng'),
              ),
              for (final d in dc.items)
                DropdownMenuItem<String?>(
                  value: d.id,
                  child: Text(d.name),
                ),
            ],
            onChanged: (v) => setState(() => _discountId = v),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          if (isPt) ...[
            const SizedBox(height: 16),
            const Text('Chọn huấn luyện viên (PT)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: _trainerId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Không chọn'),
                ),
                for (final t in _trainers)
                  DropdownMenuItem<String?>(
                    value: t['id'],
                    child: Text(t['name'] ?? ''),
                  ),
              ],
              onChanged: (v) => setState(() => _trainerId = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting
                ? null
                : () async {
                    if (_blocked && !_prebook) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_blockMsg ?? 'Bạn đang có gói tập hoạt động hoặc đang chờ duyệt')),
                      );
                      return;
                    }
                    if (_packageId == null || _packageId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn gói tập')),
                      );
                      return;
                    }
                    setState(() => _submitting = true);
                    try {
                      final svc = RegistrationService(ApiClient());
                      final reg = await svc.createSelf(
                        packageId: _packageId!,
                        discountId: _discountId,
                        trainerId: _trainerId,
                        prebook: _prebook,
                      );
                      if (!context.mounted) return;
                      await showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Đã gửi đăng ký'),
                          content: Text(
                            'Gói: ${reg.package.name}\nTrạng thái: ${reg.status.toUpperCase()} (chờ duyệt)',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      final msg = e is ApiException ? e.message : e.toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                      await _checkBlock();
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gửi đăng ký'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/packages/package_service.dart';
import 'package:gym_frontend/features/packages/package_model.dart';
import 'package:gym_frontend/features/discounts/discount_service.dart';
import 'package:gym_frontend/features/discounts/discount_model.dart';
import 'package:gym_frontend/features/members/member_service.dart';
import 'package:gym_frontend/features/members/member_model.dart';
import 'package:gym_frontend/features/employees/employee_service.dart';
import 'package:gym_frontend/features/employees/employee_model.dart';

class RegistrationCreateScreen extends StatefulWidget {
  const RegistrationCreateScreen({super.key});

  @override
  State<RegistrationCreateScreen> createState() =>
      _RegistrationCreateScreenState();
}

class _RegistrationCreateScreenState extends State<RegistrationCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _memberId;
  String? _packageId;
  String? _discountId;
  String _paymentMethod = 'cash';
  DateTime? _memberCurrentEnd;
  List<EmployeeModel> _trainers = [];
  String? _trainerId; // selected trainer for PT package

  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<MemberModel> _members = [];
  List<PackageModel> _packages = [];
  List<DiscountModel> _discounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiClient();
      final membersService = MemberService(api);
      final packagesService = PackageService(api);
      final discountsService = DiscountService(api);

      final (members, _) = await membersService.list(limit: 100);
  final (packages, _) = await packagesService.list(limit: 100);
      // Reception should use the public active discounts endpoint to avoid 403
      final discounts = await discountsService.listActivePublic();
  // Load active trainers for PT packages
  final trainers = await EmployeeService(api).listActiveTrainers();

      setState(() {
        _members = members;
    _packages = packages;
    _discounts = discounts;
    _trainers = trainers;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<DateTime?> _fetchMemberActiveEnd(String memberId) async {
    try {
      final api = ApiClient();
      final res = await api.getJson('/api/registrations/member/$memberId/active');
      final list = (res['activePackages'] as List?) ?? const [];
      if (list.isEmpty) return null;
      DateTime? latest;
      for (final item in list.cast<Map<String, dynamic>>()) {
        final raw = item['end_date'] ?? item['endDate'];
        if (raw == null) continue;
        final end = DateTime.tryParse(raw.toString());
        if (end == null) continue;
        if (latest == null || end.isAfter(latest)) latest = end;
      }
      return latest;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Registration')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null) ...[
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                        ],
                        DropdownButtonFormField<String>(
                          initialValue: _memberId,
                          items: _members
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text('${m.fullName} (${m.email})'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) async {
                            setState(() {
                              _memberId = v;
                              _memberCurrentEnd = null;
                            });
                            if (v != null && v.isNotEmpty) {
                              final end = await _fetchMemberActiveEnd(v);
                              if (mounted) setState(() => _memberCurrentEnd = end);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Member',
                          ),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _packageId,
                          items: _packages
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.name} - ${p.price} VND'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _packageId = v;
                              // Reset trainer selection when switching packages
                              final isPt = _packages.any((p) => p.id == v && p.isPersonalTraining);
                              if (!isPt) _trainerId = null;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Package',
                          ),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        // Trainer selector appears only if selected package is PT
                        if (_packageId != null &&
                            _packages.any((p) => p.id == _packageId && p.isPersonalTraining)) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _trainerId,
                            items: _trainers
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text('${t.fullName} (${t.email})'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _trainerId = v),
                            decoration: const InputDecoration(
                              labelText: 'Chọn Huấn luyện viên (PT)',
                            ),
                            validator: (v) {
                              final isPt = _packages.any((p) => p.id == _packageId && p.isPersonalTraining);
                              if (isPt && (v == null || v.isEmpty)) return 'Bắt buộc chọn PT';
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: _discountId,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No discount'),
                            ),
                            ..._discounts.map(
                              (d) => DropdownMenuItem(
                                value: d.id,
                                child: Text('${d.name} (${d.type} ${d.value})'),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _discountId = v),
                          decoration: const InputDecoration(
                            labelText: 'Discount (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          items: const [
                            DropdownMenuItem(
                              value: 'cash',
                              child: Text('Cash'),
                            ),
                            DropdownMenuItem(
                              value: 'card',
                              child: Text('Card'),
                            ),
                            DropdownMenuItem(
                              value: 'transfer',
                              child: Text('Transfer'),
                            ),
                            DropdownMenuItem(
                              value: 'online',
                              child: Text('Online'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _paymentMethod = v ?? 'cash'),
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    if (!(_formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }
                                    final api = ApiClient();
                                    bool prebook = false;
                                    if (_memberCurrentEnd != null) {
                                      final daysLeft = _memberCurrentEnd!
                                          .difference(DateTime.now())
                                          .inDays;
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Đăng ký trước?'),
                                          content: Text(
                                            'Thành viên đang có gói hoạt động còn khoảng $daysLeft ngày (đến ${_memberCurrentEnd!.toLocal().toString().split(' ').first}).\nBạn có muốn đăng ký trước để gói mới tự động bắt đầu sau khi gói hiện tại kết thúc không?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Huỷ'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Đăng ký trước'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed != true) return;
                                      prebook = true;
                                    }

                                    setState(() {
                                      _saving = true;
                                      _error = null;
                                    });
                                    try {
                                      await api.postJson(
                                        '/api/registrations',
                                        body: {
                                          'memberId': _memberId,
                                          'packageId': _packageId,
                                          if (_discountId != null)
                                            'discountId': _discountId,
                                          if (_trainerId != null)
                                            'trainerId': _trainerId,
                                          'paymentMethod': _paymentMethod,
                                          if (prebook) 'prebook': true,
                                        },
                                      );
                                      if (!context.mounted) return;
                                      Navigator.pop(context, true);
                                    } on ApiException catch (e) {
                                      // Backend fallback: if still blocked due to active package, ask to prebook and retry
                                      final msg = e.message.toLowerCase();
                                      final shouldOffer = msg.contains('đã có gói tập đang hoạt động') || msg.contains('active');
                                      if (!prebook && shouldOffer) {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Đăng ký trước?'),
                                            content: const Text(
                                              'Hệ thống phát hiện thành viên đang có gói hoạt động. Bạn có muốn đăng ký trước để gói mới tự động bắt đầu sau khi gói hiện tại kết thúc không?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('Huỷ'),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Đăng ký trước'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await api.postJson(
                                            '/api/registrations',
                                            body: {
                                              'memberId': _memberId,
                                              'packageId': _packageId,
                                              if (_discountId != null)
                                                'discountId': _discountId,
                                              if (_trainerId != null)
                                                'trainerId': _trainerId,
                                              'paymentMethod': _paymentMethod,
                                              'prebook': true,
                                            },
                                          );
                                          if (!context.mounted) return;
                                          Navigator.pop(context, true);
                                          return;
                                        }
                                      }
                                      setState(() => _error = e.toString());
                                    } catch (e) {
                                      setState(() => _error = e.toString());
                                    } finally {
                                      if (mounted) {
                                        setState(() => _saving = false);
                                      }
                                    }
                                  },
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Create Registration'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

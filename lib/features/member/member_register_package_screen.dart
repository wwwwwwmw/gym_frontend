import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../discounts/discount_provider.dart';
import '../employees/employee_service.dart';
import '../packages/package_provider.dart';
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
  String? _discountId;
  String? _trainerId;
  List<Map<String, String>> _trainers = const [];
  bool _submitting = false;
  bool _blocked = false;
  String? _blockMsg;
  bool _prebook = false;
  DateTime? _currentEnd;

  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<PackageProvider>().fetch();
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
    } catch (_) {}
  }

  Future<void> _checkBlock() async {
    try {
      final apiClient = ApiClient();

      // Endpoint member: GET /api/registrations/me/active
      final response = await apiClient.getJson('/api/registrations/me/active');

      final list = (response['activePackages'] as List)
          .map((json) => RegistrationModel.fromJson(json))
          .toList();

      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          _blocked = true;
          final p = list.first.package.name;
          _blockMsg =
              'Bạn đang có gói tập hoạt động hoặc đang chờ duyệt${p.isNotEmpty ? ': $p' : ''}';
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
      if (mounted) {
        setState(() {
          _blocked = false;
          _blockMsg = null;
          _currentEnd = null;
        });
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (_blocked && !_prebook) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _blockMsg ?? 'Bạn đang có gói tập hoạt động hoặc đang chờ duyệt',
          ),
        ),
      );
      return;
    }

    if (_packageId == null || _packageId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn gói tập')));
      return;
    }

    final pk = context.read<PackageProvider>();
    final selectedPackage = pk.items
        .where((e) => e.id == _packageId)
        .firstOrNull;

    if (selectedPackage != null && selectedPackage.isPersonalTraining) {
      if (_trainerId == null || _trainerId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gói PT yêu cầu chọn Huấn luyện viên')),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    bool didNavigate = false;

    try {
      final apiClient = ApiClient();
      final body = {
        'packageId': _packageId!,
        'discountId': _discountId,
        'trainerId': _trainerId,
        'prebook': _prebook,
        'paymentMethod': _paymentMethod,
      };

      // ✅ Dùng endpoint cho member: POST /api/registrations/me
      final response = await apiClient.postJson(
        '/api/registrations/me',
        body: body,
      );

      if (!context.mounted) return;

      // --- VNPay ---
      if (response.containsKey('paymentUrl')) {
        final url = response['paymentUrl'] as String;
        final uri = Uri.parse(url);

        // Gọi thẳng launchUrl, không dùng canLaunchUrl nữa
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!ok) {
          throw Exception('Không thể mở cổng thanh toán VNPay');
        }

        Navigator.of(context).pop();
        didNavigate = true;
      }
      // --- Cash ---
      else if (response.containsKey('registration')) {
        final reg = RegistrationModel.fromJson(response['registration']);

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
        didNavigate = true;
      } else {
        throw Exception('Phản hồi API không hợp lệ');
      }
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _checkBlock();
    } finally {
      if (mounted && !didNavigate) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pk = context.watch<PackageProvider>();
    final dc = context.watch<DiscountProvider>();
    final selectedPackage = pk.items
        .where((e) => e.id == _packageId)
        .firstOrNull;
    final isPt = selectedPackage?.isPersonalTraining ?? false;

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
                            child: Text(() {
                              final daysLeft = _currentEnd!
                                  .difference(DateTime.now())
                                  .inDays;
                              if (daysLeft > 0) {
                                return 'Gói hiện tại còn $daysLeft ngày (đến ${_currentEnd!.toLocal().toString().split(' ').first})';
                              } else {
                                return 'Gói hiện tại đã hết hạn (${_currentEnd!.toLocal().toString().split(' ').first})';
                              }
                            }(), style: const TextStyle(color: Colors.black87)),
                          ),
                        Row(
                          children: [
                            Checkbox(
                              value: _prebook,
                              onChanged: (v) =>
                                  setState(() => _prebook = v ?? false),
                            ),
                            const Expanded(
                              child: Text(
                                'Đặt trước: tạo đăng ký mới bắt đầu ngay sau khi gói hiện tại kết thúc',
                              ),
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

          // chọn gói
          const Text('Chọn gói'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            value: _packageId,
            items: [
              for (final p in pk.items)
                DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.name} • ${p.price}đ'),
                ),
            ],
            onChanged: (v) => setState(() {
              _packageId = v;
              final selectedPackage = pk.items
                  .where((e) => e.id == v)
                  .firstOrNull;
              if (selectedPackage != null &&
                  !selectedPackage.isPersonalTraining) {
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
            value: _discountId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Không áp dụng'),
              ),
              for (final d in dc.items)
                DropdownMenuItem<String?>(value: d.id, child: Text(d.name)),
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
              value: _trainerId,
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

          const SizedBox(height: 16),
          const Text('Chọn phương thức thanh toán'),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _paymentMethod,
            items: const [
              DropdownMenuItem<String>(
                value: 'cash',
                child: Text('Thanh toán tại quầy (Tiền mặt)'),
              ),
              DropdownMenuItem<String>(
                value: 'vnpay',
                child: Text('Thanh toán Online (VNPay)'),
              ),
            ],
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: _submitting ? null : _submitRegistration,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _paymentMethod == 'vnpay'
                        ? 'Tiếp tục thanh toán VNPay'
                        : 'Gửi đăng ký',
                  ),
          ),
        ],
      ),
    );
  }
}

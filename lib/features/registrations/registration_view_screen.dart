import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'registration_model.dart';
import 'registration_service.dart';

class RegistrationViewScreen extends StatefulWidget {
  final String id;
  const RegistrationViewScreen({super.key, required this.id});

  @override
  State<RegistrationViewScreen> createState() => _RegistrationViewScreenState();
}

class _RegistrationViewScreenState extends State<RegistrationViewScreen> {
  final _api = ApiClient();
  late final _service = RegistrationService(_api);
  RegistrationModel? _reg;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _service.getById(widget.id);
      setState(() {
        _reg = r;
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đăng ký'), centerTitle: true),
      body: _loading
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
          : _reg == null
          ? const Center(child: Text('Không tìm thấy đăng ký'))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: _content(context, _reg!, colorScheme),
              ),
            ),
    );
  }

  Widget _content(
    BuildContext context,
    RegistrationModel r,
    ColorScheme colorScheme,
  ) {
    final memberName = r.member.fullName.isNotEmpty
        ? r.member.fullName
        : '(Không tên)';
    final packageName = r.package.name.isNotEmpty
        ? r.package.name
        : '(Gói tập)';

    final startStr = _formatDate(r.startDate);
    final endStr = _formatDate(r.endDate);

    final statusText = _statusVi(r.status);
    final statusColor = _statusColor(r.status, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ====== KHỐI 1: HỘI VIÊN & GÓI TẬP ======
        Text(
          'Hội viên & gói tập',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                offset: const Offset(0, 2),
                color: Colors.black.withOpacity(0.02),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar chữ cái
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gói: $packageName',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$startStr → $endStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ====== KHỐI 2: THANH TOÁN ======
        Text(
          'Thông tin thanh toán',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                offset: const Offset(0, 2),
                color: Colors.black.withOpacity(0.02),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Phương thức', _paymentVi(r.paymentMethod)),
              const SizedBox(height: 8),
              _infoRow('Giá gốc', '${r.originalPrice} VND'),
              const SizedBox(height: 8),
              _infoRow('Giảm', '- ${r.discountAmount} VND'),
              const Divider(height: 20),
              _infoRow('Thanh toán', '${r.finalPrice} VND', isEmphasis: true),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ====== KHỐI 3: TRẠNG THÁI & THAO TÁC ======
        Text(
          'Trạng thái đăng ký',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                offset: const Offset(0, 2),
                color: Colors.black.withOpacity(0.02),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dòng trạng thái hiện tại
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (r.statusReason != null && r.statusReason!.isNotEmpty)
                    Expanded(
                      child: Text(
                        'Lý do: ${r.statusReason!}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Nút duyệt nhanh cho pending
              if (r.status == 'pending') ...[
                _ApproveNowButton(id: r.id, onApproved: _load),
                const SizedBox(height: 16),
              ],

              // Component cập nhật trạng thái
              _StatusUpdater(
                id: r.id,
                current: r.status,
                onDone: () async {
                  await _load();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isEmphasis = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  String _statusVi(String s) {
    switch (s) {
      case 'active':
        return 'Hoạt động';
      case 'suspended':
        return 'Tạm dừng';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      case 'pending':
        return 'Chờ duyệt';
      default:
        return s;
    }
  }

  Color _statusColor(String s, ColorScheme scheme) {
    switch (s) {
      case 'active':
        return Colors.green.shade600;
      case 'suspended':
        return Colors.orange.shade700;
      case 'cancelled':
        return Colors.red.shade600;
      case 'expired':
        return Colors.grey.shade700;
      case 'pending':
        return Colors.blue.shade600;
      default:
        return scheme.primary;
    }
  }

  String _paymentVi(String? method) {
    switch (method) {
      case 'cash':
        return 'Tiền mặt';
      case 'card':
        return 'Thẻ';
      case 'transfer':
        return 'Chuyển khoản';
      case 'online':
        return 'Thanh toán online';
      case 'vnpay':
        return 'VNPAY';
      default:
        return method ?? 'Không rõ';
    }
  }
}

// ================== DUYỆT NHANH PENDING ==================

class _ApproveNowButton extends StatefulWidget {
  final String id;
  final Future<void> Function() onApproved;
  const _ApproveNowButton({required this.id, required this.onApproved});

  @override
  State<_ApproveNowButton> createState() => _ApproveNowButtonState();
}

class _ApproveNowButtonState extends State<_ApproveNowButton> {
  final _api = ApiClient();
  late final _service = RegistrationService(_api);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _saving
            ? null
            : () async {
                setState(() => _saving = true);
                try {
                  await _service.updateStatus(widget.id, 'active');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã duyệt đăng ký')),
                  );
                  await widget.onApproved();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Duyệt thất bại: $e')));
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
        icon: _saving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline),
        label: const Text('Duyệt luôn'),
      ),
    );
  }
}

// ================== CẬP NHẬT TRẠNG THÁI ==================

class _StatusUpdater extends StatefulWidget {
  final String id;
  final String current;
  final Future<void> Function() onDone;
  const _StatusUpdater({
    required this.id,
    required this.current,
    required this.onDone,
  });

  @override
  State<_StatusUpdater> createState() => _StatusUpdaterState();
}

class _StatusUpdaterState extends State<_StatusUpdater> {
  final _api = ApiClient();
  late final _service = RegistrationService(_api);
  String? _status;
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Chỉ cho các trạng thái có trong dropdown
    const allowed = ['active', 'suspended', 'cancelled', 'expired'];
    _status = allowed.contains(widget.current) ? widget.current : null;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: _status,
          hint: const Text('Chọn trạng thái mới'),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
            DropdownMenuItem(value: 'suspended', child: Text('Tạm dừng')),
            DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
            DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
          ],
          onChanged: (v) => setState(() => _status = v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reason,
          decoration: const InputDecoration(
            labelText: 'Lý do (tuỳ chọn)',
            hintText: 'Ghi chú thêm khi đổi trạng thái',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving || _status == null || _status == widget.current
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await _service.updateStatus(
                        widget.id,
                        _status!,
                        reason: _reason.text.trim(),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật trạng thái thành công'),
                        ),
                      );
                      await widget.onDone();
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật trạng thái thất bại'),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cập nhật trạng thái'),
          ),
        ),
      ],
    );
  }
}

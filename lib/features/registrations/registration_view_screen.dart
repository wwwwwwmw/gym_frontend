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
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đăng ký')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _reg == null
          ? const Center(child: Text('Không tìm thấy'))
          : _content(context, _reg!),
    );
  }

  Widget _content(BuildContext context, RegistrationModel r) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khách hàng: ${r.member.fullName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Gói: ${r.package.name}'),
          Text(
            'Thời gian: ${r.startDate.toLocal().toString().split(' ')[0]} → ${r.endDate.toLocal().toString().split(' ')[0]}',
          ),
          Text('Thanh toán: ${r.paymentMethod}'),
          Text(
            'Giá: ${r.originalPrice} - ${r.discountAmount} = ${r.finalPrice}',
          ),
          const Divider(height: 24),
          Row(
            children: [
              Chip(label: Text(_statusVi(r.status))),
              const SizedBox(width: 8),
              if (r.statusReason != null)
                Text(
                  'Lý do: ${r.statusReason!}',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick approve button for pending registrations
          if (r.status == 'pending') _ApproveNowButton(id: r.id, onApproved: _load),
          if (r.status == 'pending') const SizedBox(height: 16),
          _StatusUpdater(
            id: r.id,
            current: r.status,
            onDone: () async {
              await _load();
            },
          ),
        ],
      ),
    );
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
}

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
    return FilledButton.icon(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Duyệt thất bại: $e')),
                );
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
      icon: _saving
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.check_circle_outline),
      label: const Text('Duyệt luôn'),
    );
  }
}

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
    // Only allow values present in the dropdown. If current is not allowed (e.g., 'pending'), leave null.
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
          decoration: const InputDecoration(labelText: 'Lý do (tuỳ chọn)'),
        ),
        const SizedBox(height: 8),
        FilledButton(
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
                      const SnackBar(content: Text('Cập nhật thất bại')),
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
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'discount_provider.dart';
import 'discount_model.dart';

class SaveDiscountScreen extends StatefulWidget {
  const SaveDiscountScreen({super.key, this.editing});
  final DiscountModel? editing;

  @override
  State<SaveDiscountScreen> createState() => _SaveDiscountScreenState();
}

class _SaveDiscountScreenState extends State<SaveDiscountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _type = 'percentage';
  final _value = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  String _status = 'active';
  final _minPurchase = TextEditingController();
  final _maxUsage = TextEditingController();
  String _validity = 'range'; // permanent | once | range

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _description.text = e.description ?? '';
      _type = e.type;
      _value.text = e.value.toString();
      _start = e.startDate;
      _end = e.endDate;
      _status = e.status;
      _minPurchase.text = e.minPurchaseAmount?.toString() ?? '';
      _maxUsage.text = e.maxUsageCount?.toString() ?? '';
      // infer validity (timezone-robust)
      if (e.maxUsageCount == 1) {
        _validity = 'once';
      } else {
    final s = DateTime.utc(e.startDate.year, e.startDate.month, e.startDate.day);
    final ed = DateTime.utc(e.endDate.year, e.endDate.month, e.endDate.day);
    final isPermanent = s.isAtSameMomentAs(DateTime.utc(1970, 1, 1)) &&
      ed.isAtSameMomentAs(DateTime.utc(2099, 12, 31));
        _validity = isPermanent ? 'permanent' : 'range';
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _value.dispose();
    _minPurchase.dispose();
    _maxUsage.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa mã giảm giá' : 'Tạo mã giảm giá'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên mã giảm giá'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 2,
            ),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: const [
                DropdownMenuItem(value: 'percentage', child: Text('Phần trăm')),
                DropdownMenuItem(value: 'fixed', child: Text('Số tiền')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'percentage'),
              decoration: const InputDecoration(labelText: 'Loại giảm giá'),
            ),
            TextFormField(
              controller: _value,
              decoration: InputDecoration(
                labelText: _type == 'percentage'
                    ? 'Giá trị (%)'
                    : 'Giá trị (VND)',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = num.tryParse(v ?? '');
                if (n == null || n < 0) return 'Không hợp lệ';
                if (_type == 'percentage' && n > 100) return 'Tối đa 100%';
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _validity,
              items: const [
                DropdownMenuItem(value: 'permanent', child: Text('Vĩnh viễn')),
                DropdownMenuItem(value: 'once', child: Text('Một lần')),
                DropdownMenuItem(
                  value: 'range',
                  child: Text('Từ ngày - đến ngày'),
                ),
              ],
              onChanged: (v) => setState(() => _validity = v ?? 'range'),
              decoration: const InputDecoration(labelText: 'Hiệu lực'),
            ),
            if (_validity == 'range')
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày bắt đầu'),
                      subtitle: Text('${_start.toLocal()}'.split(' ')[0]),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickDate(start: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày kết thúc'),
                      subtitle: Text('${_end.toLocal()}'.split(' ')[0]),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickDate(start: false),
                      ),
                    ),
                  ),
                ],
              ),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(
                  value: 'active',
                  child: Text('Đang hoạt động'),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Text('Ngừng hoạt động'),
                ),
                DropdownMenuItem(value: 'expired', child: Text('Hết hạn')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
              decoration: const InputDecoration(labelText: 'Trạng thái'),
            ),
            TextFormField(
              controller: _minPurchase,
              decoration: const InputDecoration(
                labelText: 'Mua tối thiểu (VND)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _maxUsage,
              decoration: const InputDecoration(
                labelText: 'Số lượt sử dụng tối đa',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                final data = {
                  'name': _name.text.trim(),
                  if (_description.text.trim().isNotEmpty)
                    'description': _description.text.trim(),
                  'type': _type,
                  'value': num.parse(_value.text.trim()),
                  'status': _status,
                  if (_minPurchase.text.trim().isNotEmpty)
                    'minPurchaseAmount': num.parse(_minPurchase.text.trim()),
                };
                // apply validity
                if (_validity == 'permanent') {
                  // Use UTC sentinel dates to avoid timezone shifting a day
                  data['startDate'] = DateTime.utc(1970, 1, 1).toIso8601String();
                  data['endDate'] = DateTime.utc(2099, 12, 31).toIso8601String();
                  // ensure no maxUsageCount key for permanent
                  data.remove('maxUsageCount');
                } else if (_validity == 'once') {
                  // Normalize to UTC midnight of selected day
                  final s = DateTime.utc(_start.year, _start.month, _start.day);
                  data['startDate'] = s.toIso8601String();
                  data['endDate'] = s.toIso8601String();
                  data['maxUsageCount'] = 1;
                } else {
                  // Normalize to UTC midnight for consistency
                  final s = DateTime.utc(_start.year, _start.month, _start.day);
                  final e = DateTime.utc(_end.year, _end.month, _end.day);
                  data['startDate'] = s.toIso8601String();
                  data['endDate'] = e.toIso8601String();
                  // for range, forward user-entered max usage if any
                  if (_maxUsage.text.trim().isNotEmpty) {
                    data['maxUsageCount'] = int.parse(_maxUsage.text.trim());
                  } else {
                    data.remove('maxUsageCount');
                  }
                }
                // If validity is once, we always force 1 regardless of user input.
                final ok = await context
                    .read<DiscountProvider>()
                    .createOrUpdate(id: widget.editing?.id, data: data);
                if (!context.mounted) return;
                if (ok) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lưu không thành công')),
                  );
                }
              },
              child: Text(isEdit ? 'Lưu' : 'Tạo'),
            ),
          ],
        ),
      ),
    );
  }
}

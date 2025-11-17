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

      // Suy ra kiểu hiệu lực (timezone-robust)
      if (e.maxUsageCount == 1) {
        _validity = 'once';
      } else {
        final s = DateTime.utc(
          e.startDate.year,
          e.startDate.month,
          e.startDate.day,
        );
        final ed = DateTime.utc(e.endDate.year, e.endDate.month, e.endDate.day);
        final isPermanent =
            s.isAtSameMomentAs(DateTime.utc(1970, 1, 1)) &&
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
    if (picked != null) {
      setState(() {
        if (start) {
          _start = picked;
          if (_end.isBefore(_start)) {
            _end = _start;
          }
        } else {
          _end = picked.isBefore(_start) ? _start : picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa mã giảm giá' : 'Tạo mã giảm giá'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ====== THÔNG TIN CƠ BẢN ======
              Text(
                'Thông tin cơ bản',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Tên mã giảm giá *',
                        hintText: 'VD: TET2025, NEWMEMBER, SUMMER...',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả (tuỳ chọn)',
                        hintText: 'VD: Giảm cho hội viên mới...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _type,
                      items: const [
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Phần trăm'),
                        ),
                        DropdownMenuItem(
                          value: 'fixed',
                          child: Text('Số tiền cố định'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _type = v ?? 'percentage');
                      },
                      decoration: const InputDecoration(
                        labelText: 'Loại giảm giá *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _value,
                      decoration: InputDecoration(
                        labelText: _type == 'percentage'
                            ? 'Giá trị giảm (%) *'
                            : 'Giá trị giảm (VND) *',
                        hintText: _type == 'percentage'
                            ? 'VD: 10, 20, 50...'
                            : 'VD: 50000, 100000...',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final n = num.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Không hợp lệ';
                        if (_type == 'percentage' && n > 100) {
                          return 'Tối đa 100%';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ====== QUY TẮC ÁP DỤNG ======
              Text(
                'Quy tắc áp dụng',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                  children: [
                    // Hiệu lực
                    DropdownButtonFormField<String>(
                      value: _validity,
                      items: const [
                        DropdownMenuItem(
                          value: 'permanent',
                          child: Text('Vĩnh viễn'),
                        ),
                        DropdownMenuItem(value: 'once', child: Text('Một lần')),
                        DropdownMenuItem(
                          value: 'range',
                          child: Text('Trong khoảng ngày'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _validity = v ?? 'range'),
                      decoration: const InputDecoration(
                        labelText: 'Hiệu lực *',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Khoảng ngày (chỉ hiện khi range hoặc once)
                    if (_validity == 'range' || _validity == 'once')
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _validity == 'once'
                                    ? 'Ngày áp dụng'
                                    : 'Ngày bắt đầu',
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                '${_start.toLocal()}'.split(' ')[0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _pickDate(start: true),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_validity == 'range')
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Ngày kết thúc',
                                  style: TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${_end.toLocal()}'.split(' ')[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () => _pickDate(start: false),
                                ),
                              ),
                            ),
                        ],
                      ),

                    if (_validity == 'range' || _validity == 'once')
                      const SizedBox(height: 4),

                    DropdownButtonFormField<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Đang hoạt động'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Ngừng hoạt động'),
                        ),
                        DropdownMenuItem(
                          value: 'expired',
                          child: Text('Hết hạn'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'active'),
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _minPurchase,
                      decoration: const InputDecoration(
                        labelText: 'Mua tối thiểu (VND, tuỳ chọn)',
                        hintText: 'Đơn hàng tối thiểu để được giảm',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_validity == 'range')
                      TextFormField(
                        controller: _maxUsage,
                        decoration: const InputDecoration(
                          labelText: 'Số lượt sử dụng tối đa (tuỳ chọn)',
                          hintText: 'Để trống nếu không giới hạn',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    if (_validity == 'once')
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Hiệu lực "Một lần": hệ thống sẽ tự giới hạn 1 lượt sử dụng.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    if (_validity == 'permanent')
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Hiệu lực "Vĩnh viễn": không giới hạn ngày và số lượt sử dụng.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ====== NÚT LƯU ======
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _onSubmit,
                  icon: Icon(isEdit ? Icons.save : Icons.check),
                  label: Text(isEdit ? 'Lưu thay đổi' : 'Tạo mã giảm giá'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      'type': _type,
      'value': num.parse(_value.text.trim()),
      'status': _status,
      if (_minPurchase.text.trim().isNotEmpty)
        'minPurchaseAmount': num.parse(_minPurchase.text.trim()),
    };

    // Áp dụng logic hiệu lực (giữ nguyên như bạn đang làm)
    if (_validity == 'permanent') {
      // Dùng sentinel UTC để tránh lệch ngày
      data['startDate'] = DateTime.utc(1970, 1, 1).toIso8601String();
      data['endDate'] = DateTime.utc(2099, 12, 31).toIso8601String();
      data.remove('maxUsageCount');
    } else if (_validity == 'once') {
      // Chỉ trong 1 ngày, giới hạn 1 lượt
      final s = DateTime.utc(_start.year, _start.month, _start.day);
      data['startDate'] = s.toIso8601String();
      data['endDate'] = s.toIso8601String();
      data['maxUsageCount'] = 1;
    } else {
      // range
      final s = DateTime.utc(_start.year, _start.month, _start.day);
      final e = DateTime.utc(_end.year, _end.month, _end.day);
      data['startDate'] = s.toIso8601String();
      data['endDate'] = e.toIso8601String();
      if (_maxUsage.text.trim().isNotEmpty) {
        data['maxUsageCount'] = int.parse(_maxUsage.text.trim());
      } else {
        data.remove('maxUsageCount');
      }
    }

    final ok = await context.read<DiscountProvider>().createOrUpdate(
      id: widget.editing?.id,
      data: data,
    );

    if (!context.mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu không thành công')));
    }
  }
}

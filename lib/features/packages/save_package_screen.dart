import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_frontend/features/packages/package_provider.dart';
import 'package:gym_frontend/features/packages/package_model.dart';

class SavePackageScreen extends StatefulWidget {
  const SavePackageScreen({super.key, this.editing});
  final PackageModel? editing;

  @override
  State<SavePackageScreen> createState() => _SavePackageScreenState();
}

class _SavePackageScreenState extends State<SavePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _duration = TextEditingController();
  final _price = TextEditingController();
  final _features = TextEditingController();
  final _maxSessions = TextEditingController();
  String _status = 'active';
  bool _isPt = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _description.text = e.description ?? '';
      _duration.text = e.duration.toString();
      _price.text = e.price.toString();
      _features.text = e.features.join(', ');
      _status = e.status;
      _maxSessions.text = e.maxSessions?.toString() ?? '';
      _isPt = e.isPersonalTraining;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    _price.dispose();
    _features.dispose();
    _maxSessions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa gói tập' : 'Tạo gói tập'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ====== THÔNG TIN GÓI TẬP ======
              Text(
                'Thông tin gói tập',
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
                        labelText: 'Tên gói *',
                        hintText: 'VD: Gói 1 tháng, Gói 12 buổi PT',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        hintText: 'Giới thiệu ngắn về gói tập',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Thời lượng (ngày) *',
                        hintText: 'VD: 30, 90...',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Giá (VND) *',
                        hintText: 'VD: 1500000',
                      ),
                      validator: (v) {
                        final n = num.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _features,
                      decoration: const InputDecoration(
                        labelText: 'Tính năng (phân tách bằng dấu phẩy)',
                        hintText:
                            'VD: Phòng tập không giới hạn, Tủ đồ riêng, Nước uống miễn phí',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Đang bán'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Tạm ẩn'),
                        ),
                        DropdownMenuItem(
                          value: 'discontinued',
                          child: Text('Ngừng kinh doanh'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'active'),
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ====== CẤU HÌNH NÂNG CAO ======
              Text(
                'Cấu hình nâng cao',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Có PT riêng'),
                      subtitle: const Text(
                        'Gói này bao gồm huấn luyện viên cá nhân',
                      ),
                      value: _isPt,
                      onChanged: (v) => setState(() => _isPt = v),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _maxSessions,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số buổi tối đa (tuỳ chọn)',
                        hintText: 'VD: 12, 24 (để trống nếu không giới hạn)',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '• Dùng cho gói PT hoặc gói theo số buổi.\n'
                        '• Để trống nếu là gói theo thời gian (ví dụ: gói tháng).',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
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
                  label: Text(isEdit ? 'Lưu thay đổi' : 'Tạo gói tập'),
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

    final features = _features.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final data = {
      'name': _name.text.trim(),
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      'duration': int.parse(_duration.text.trim()),
      'price': num.parse(_price.text.trim()),
      'features': features,
      'status': _status,
      'isPersonalTraining': _isPt,
      if (_maxSessions.text.trim().isNotEmpty)
        'maxSessions': int.parse(_maxSessions.text.trim()),
    };

    final ok = await context.read<PackageProvider>().createOrUpdate(
      id: widget.editing?.id,
      data: data,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu không thành công')));
    }
  }
}

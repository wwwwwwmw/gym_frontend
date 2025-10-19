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
  String _status = 'active';
  final _maxSessions = TextEditingController();
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
      appBar: AppBar(title: Text(isEdit ? 'Sửa gói tập' : 'Tạo gói tập')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên gói'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 2,
            ),
            TextFormField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Thời lượng (ngày)'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Không hợp lệ';
                return null;
              },
            ),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá (VND)'),
              validator: (v) {
                final n = num.tryParse(v ?? '');
                if (n == null || n < 0) return 'Không hợp lệ';
                return null;
              },
            ),
            TextFormField(
              controller: _features,
              decoration: const InputDecoration(
                labelText: 'Tính năng (phân tách bằng dấu phẩy)',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Đang bán')),
                DropdownMenuItem(value: 'inactive', child: Text('Tạm ẩn')),
                DropdownMenuItem(
                  value: 'discontinued',
                  child: Text('Ngừng kinh doanh'),
                ),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
              decoration: const InputDecoration(labelText: 'Trạng thái'),
            ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Có PT riêng'),
                subtitle: const Text('Gói này bao gồm huấn luyện viên cá nhân'),
                value: _isPt,
                onChanged: (v) => setState(() => _isPt = v),
              ),
            TextFormField(
              controller: _maxSessions,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số buổi tối đa (tuỳ chọn)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
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

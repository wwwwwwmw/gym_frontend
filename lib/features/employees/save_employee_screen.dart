import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'employee_model.dart';
import 'employee_provider.dart';

class SaveEmployeeScreen extends StatefulWidget {
  const SaveEmployeeScreen({super.key, this.editing});
  final EmployeeModel? editing;

  @override
  State<SaveEmployeeScreen> createState() => _SaveEmployeeScreenState();
}

class _SaveEmployeeScreenState extends State<SaveEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'TRAINER';
  final _department = TextEditingController();
  final _salary = TextEditingController();
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _fullName.text = e.fullName;
      _email.text = e.email;
      _phone.text = e.phone;
      _role = e.position.isNotEmpty ? e.position : 'TRAINER';
      _department.text = e.department ?? '';
      _salary.text = e.salary?.toString() ?? '';
      _status = e.status.toLowerCase();
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _department.dispose();
    _salary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa nhân viên' : 'Tạo nhân viên'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ====== THÔNG TIN CÁ NHÂN ======
              Text(
                'Thông tin cá nhân',
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
                      controller: _fullName,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        hintText: 'VD: Nguyễn Văn A',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        hintText: 'VD: nv.a@gym.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = v ?? '';
                        if (value.trim().isEmpty) return 'Bắt buộc';
                        if (!value.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        hintText: 'VD: 090xxxxxxx',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ====== THÔNG TIN CÔNG VIỆC ======
              Text(
                'Thông tin công việc',
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
                    DropdownButtonFormField<String>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                        DropdownMenuItem(
                          value: 'MANAGER',
                          child: Text('MANAGER'),
                        ),
                        DropdownMenuItem(
                          value: 'TRAINER',
                          child: Text('TRAINER'),
                        ),
                        DropdownMenuItem(
                          value: 'RECEPTION',
                          child: Text('RECEPTION'),
                        ),
                        DropdownMenuItem(
                          value: 'MEMBER',
                          child: Text('MEMBER'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? _role),
                      decoration: const InputDecoration(
                        labelText: 'Vị trí (Vai trò) *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _department,
                      decoration: const InputDecoration(
                        labelText: 'Phòng ban (tuỳ chọn)',
                        hintText: 'VD: Lễ tân, PT, Quản lý...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _salary,
                      decoration: const InputDecoration(
                        labelText: 'Lương (VND, tuỳ chọn)',
                        hintText: 'VD: 10000000',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Đang làm việc'),
                        ),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Tạm nghỉ'),
                        ),
                        DropdownMenuItem(
                          value: 'terminated',
                          child: Text('Đã nghỉ việc'),
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

              const SizedBox(height: 24),

              // ====== NÚT LƯU ======
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _onSubmit,
                  icon: Icon(isEdit ? Icons.save : Icons.check),
                  label: Text(isEdit ? 'Lưu thay đổi' : 'Tạo nhân viên'),
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

    final data = {
      'fullName': _fullName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'position': _role,
      if (_department.text.trim().isNotEmpty)
        'department': _department.text.trim(),
      if (_salary.text.trim().isNotEmpty)
        'salary': num.parse(_salary.text.trim()),
      'status': _status,
    };

    final ok = await context.read<EmployeeProvider>().createOrUpdate(
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'employee_provider.dart';
import 'employee_model.dart';
import 'save_employee_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _search = TextEditingController();
  String? _status;
  String? _position;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<EmployeeProvider>().fetch(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EmployeeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => context.read<EmployeeProvider>().fetch(
              search: _search.text.trim(),
              status: _status,
              position: _position,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm nhân viên',
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const SaveEmployeeScreen()),
              );
              if (!context.mounted) return;
              if (ok == true) {
                context.read<EmployeeProvider>().fetch(
                  search: _search.text.trim(),
                  status: _status,
                  position: _position,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ====== KHỐI TÌM KIẾM + LỌC ======
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Tìm theo tên / email / vai trò...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        context.read<EmployeeProvider>().fetch(
                          status: _status,
                          position: _position,
                        );
                      },
                    ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => context.read<EmployeeProvider>().fetch(
                    search: _search.text.trim(),
                    status: _status,
                    position: _position,
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFDF9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Trạng thái
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _status,
                            hint: const Text('Trạng thái'),
                            isExpanded: true,
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
                            onChanged: (v) {
                              setState(() => _status = v);
                              context.read<EmployeeProvider>().fetch(
                                search: _search.text.trim(),
                                status: v,
                                position: _position,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Vai trò
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _position,
                            hint: const Text('Vai trò'),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'ADMIN',
                                child: Text('ADMIN'),
                              ),
                              // DropdownMenuItem( // ĐÃ XÓA
                              //   value: 'MANAGER',
                              //   child: Text('MANAGER'),
                              // ),
                              DropdownMenuItem(
                                value: 'TRAINER',
                                child: Text('TRAINER'),
                              ),
                              // DropdownMenuItem( // ĐÃ XÓA
                              //   value: 'RECEPTION',
                              //   child: Text('RECEPTION'),
                              // ),
                              // DropdownMenuItem( // ĐÃ XÓA
                              //   value: 'MEMBER',
                              //   child: Text('MEMBER'),
                              // ),
                            ],
                            onChanged: (v) {
                              setState(() => _position = v);
                              context.read<EmployeeProvider>().fetch(
                                search: _search.text.trim(),
                                status: _status,
                                position: v,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!vm.loading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Tổng: ${vm.items.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ====== DANH SÁCH NHÂN VIÊN ======
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        vm.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : vm.items.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: vm.items.length,
                    itemBuilder: (ctx, i) {
                      final e = vm.items[i];
                      return _employeeCard(context, e, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ====== CARD NHÂN VIÊN ======

  Widget _employeeCard(
    BuildContext context,
    EmployeeModel e,
    ColorScheme scheme,
  ) {
    final name = e.fullName.isNotEmpty ? e.fullName : '(Không tên)';
    final email = e.email;
    final position = e.position;
    final statusText = _statusVi(e.status);
    final statusColor = _statusColor(e.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            // Mặc định là mở màn sửa
            final ok = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => SaveEmployeeScreen(editing: e)),
            );
            if (!context.mounted) return;
            if (ok == true) {
              context.read<EmployeeProvider>().fetch(
                search: _search.text.trim(),
                status: _status,
                position: _position,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar chữ cái
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Nội dung chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên + vai trò
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              position,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Email
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Trạng thái
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () async {
                        final ok = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaveEmployeeScreen(editing: e),
                          ),
                        );
                        if (!context.mounted) return;
                        if (ok == true) {
                          context.read<EmployeeProvider>().fetch(
                            search: _search.text.trim(),
                            status: _status,
                            position: _position,
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Xoá nhân viên?'),
                            content: Text('Xoá "${e.fullName}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Huỷ'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Xoá'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          if (!context.mounted) return;
                          final done = await context
                              .read<EmployeeProvider>()
                              .remove(e.id);
                          if (!context.mounted) return;
                          if (!done) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Xoá không thành công'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ====== EMPTY STATE ======

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Chưa có nhân viên nào',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hãy bấm nút "+" ở góc trên bên phải để thêm nhân viên mới.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ====== HELPERS ======

  String _statusVi(String s) {
    switch (s) {
      case 'active':
        return 'Đang làm việc';
      case 'inactive':
        return 'Tạm nghỉ';
      case 'terminated':
        return 'Đã nghỉ việc';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return Colors.green.shade600;
      case 'inactive':
        return Colors.orange.shade700;
      case 'terminated':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade700;
    }
  }
}

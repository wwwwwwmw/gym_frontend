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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<EmployeeProvider>().fetch(
              search: _search.text,
              status: _status,
              position: _position,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const SaveEmployeeScreen()),
              );
              if (!context.mounted) return;
              if (ok == true) {
                context.read<EmployeeProvider>().fetch(
                  search: _search.text,
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Tìm theo tên/email/vai trò',
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
                    ),
                    onSubmitted: (_) => context.read<EmployeeProvider>().fetch(
                      search: _search.text,
                      status: _status,
                      position: _position,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  hint: const Text('Trạng thái'),
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
                      search: _search.text,
                      status: v,
                      position: _position,
                    );
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _position,
                  hint: const Text('Vai trò'),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(value: 'MANAGER', child: Text('MANAGER')),
                    DropdownMenuItem(value: 'TRAINER', child: Text('TRAINER')),
                    DropdownMenuItem(
                      value: 'RECEPTION',
                      child: Text('RECEPTION'),
                    ),
                    DropdownMenuItem(value: 'MEMBER', child: Text('MEMBER')),
                  ],
                  onChanged: (v) {
                    setState(() => _position = v);
                    context.read<EmployeeProvider>().fetch(
                      search: _search.text,
                      status: _status,
                      position: v,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? Center(child: Text(vm.error!))
                : ListView.separated(
                    itemCount: vm.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final e = vm.items[i];
                      return _tile(context, e);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, EmployeeModel e) {
    return ListTile(
      title: Text(e.fullName),
      subtitle: Text('${e.position} • ${e.email} • ${_statusVi(e.status)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
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
                  search: _search.text,
                  status: _status,
                  position: _position,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
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
                final done = await context.read<EmployeeProvider>().remove(
                  e.id,
                );
                if (!context.mounted) return;
                if (!done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xoá không thành công')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'member_provider.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MemberProvider>().fetch();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemberProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Thành viên')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Tìm tên, email, SĐT...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (v) => vm.fetch(search: v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => vm.fetch(search: _search.text),
                  child: const Text('Tìm'),
                ),
              ],
            ),
          ),
          if (vm.loading) const LinearProgressIndicator(minHeight: 2),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => vm.fetch(search: _search.text),
              child: ListView.separated(
                itemCount: vm.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final m = vm.items[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(m.fullName.isNotEmpty ? m.fullName[0] : '?'),
                    ),
                    title: Text(m.fullName),
                    subtitle: Text('${m.email} • ${m.phone}'),
                    trailing: Chip(label: Text(m.status)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

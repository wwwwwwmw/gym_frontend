import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'discount_provider.dart';

class ActiveDiscountsScreen extends StatefulWidget {
  const ActiveDiscountsScreen({super.key});

  @override
  State<ActiveDiscountsScreen> createState() => _ActiveDiscountsScreenState();
}

class _ActiveDiscountsScreenState extends State<ActiveDiscountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountProvider>().fetchActivePublic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Khuyến mãi đang chạy')),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: vm.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = vm.items[i];
                final typeVi = d.type == 'percentage' ? 'Phần trăm' : 'Số tiền';
                return ListTile(
                  title: Text(d.name),
                  subtitle: Text('$typeVi • ${d.value}'),
                );
              },
            ),
    );
  }
}

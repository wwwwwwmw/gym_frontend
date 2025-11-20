import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'discount_provider.dart';

class ActiveDiscountsScreen extends StatefulWidget {
  const ActiveDiscountsScreen({super.key});

  @override
  State<ActiveDiscountsScreen> createState() => _ActiveDiscountsScreenState();
}

class _ActiveDiscountsScreenState extends State<ActiveDiscountsScreen> {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountProvider>().loadActiveDiscounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khuyến mãi đang chạy'),
        centerTitle: true,
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.items.isEmpty
          ? _emptyState(colorScheme)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: vm.items.length,
              itemBuilder: (_, i) {
                final d = vm.items[i];
                final isPercent = d.type == 'percentage';
                final valueText = isPercent
                    ? '${d.value.toStringAsFixed(0)}%'
                    : _currency.format(d.value);

                final typeText = isPercent ? 'Giảm theo %' : 'Giảm số tiền';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ICON
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_offer_outlined,
                          color: colorScheme.error,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // CONTENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$typeText • Giảm $valueText',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _emptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hiện chưa có khuyến mãi nào đang diễn ra.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn hãy quay lại sau hoặc theo dõi thông báo từ phòng gym.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

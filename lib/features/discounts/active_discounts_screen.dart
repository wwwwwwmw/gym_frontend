import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'discount_provider.dart';
import 'discount_model.dart';

class ActiveDiscountsScreen extends StatefulWidget {
  const ActiveDiscountsScreen({super.key, this.packageId});
  
  final String? packageId;

  @override
  State<ActiveDiscountsScreen> createState() => _ActiveDiscountsScreenState();
}

class _ActiveDiscountsScreenState extends State<ActiveDiscountsScreen> {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DiscountProvider>();
      if (widget.packageId != null) {
        provider.fetchActiveDiscountsForPackage(widget.packageId);
      } else {
        provider.loadActiveDiscounts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.packageId != null 
              ? 'Mã giảm giá cho gói tập' 
              : 'Khuyến mãi đang chạy',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.packageId != null) {
                vm.fetchActiveDiscountsForPackage(widget.packageId);
              } else {
                vm.loadActiveDiscounts();
              }
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.activeDiscounts.isEmpty
          ? _emptyState(colorScheme)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: vm.activeDiscounts.length,
              itemBuilder: (_, i) {
                final d = vm.activeDiscounts[i];
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
                            const SizedBox(height: 8),
                            // Mã code khuyến mãi
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: d.code.toUpperCase()));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã copy mã: ${d.code.toUpperCase()}'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B6B), Color(0xFFFFA500)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_offer,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      d.code.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.content_copy,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ],
                                ),
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
    final isPackageSpecific = widget.packageId != null;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPackageSpecific 
                  ? 'Chưa có mã giảm giá cho gói này' 
                  : 'Chưa có khuyến mãi nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPackageSpecific
                  ? 'Hiện tại chưa có mã giảm giá nào áp dụng cho gói tập này. Bạn có thể thử các mã khuyến mãi chung bên dưới hoặc quay lại sau!'
                  : 'Hiện tại chưa có chương trình khuyến mãi nào đang diễn ra. Bạn hãy quay lại sau hoặc theo dõi thông báo từ phòng gym!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (isPackageSpecific) ...[
              ElevatedButton.icon(
                onPressed: () {
                  // Chuyển sang xem tất cả mã khuyến mãi
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActiveDiscountsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.local_offer, size: 20),
                label: const Text('Xem tất cả mã khuyến mãi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Theo dõi để không bỏ lỡ ưu đãi!',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

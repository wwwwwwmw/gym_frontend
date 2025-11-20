import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_frontend/features/discounts/discount_model.dart';
import 'package:gym_frontend/features/discounts/discount_provider.dart';
import 'package:provider/provider.dart';

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final _discountCodeController = TextEditingController();
  // String? _selectedDiscountId; // Temporarily commented out - will be used later
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _discountCodeController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscountProvider>().loadActiveDiscounts();
    });
  }

  void _onTextChanged() {
    setState(() {}); // Trigger rebuild to update suffixIcon
  }

  @override
  void dispose() {
    _discountCodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _applyDiscount() async {
    final code = _discountCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã khuyến mãi')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<DiscountProvider>();
      final discount = await provider.validateDiscountCode(code);
      
      if (discount != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã áp dụng mã khuyến mãi: ${discount.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(discount.code);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã khuyến mãi không hợp lệ hoặc đã hết hạn'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể áp dụng khuyến mãi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectAutoApplyDiscount(DiscountModel discount) async {
    try {
      final provider = context.read<DiscountProvider>();
      final validatedDiscount = await provider.validateDiscountCode(discount.code);
      
      if (validatedDiscount != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã áp dụng mã khuyến mãi: ${discount.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(discount.code);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã khuyến mãi không hợp lệ hoặc đã hết hạn'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể áp dụng khuyến mãi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshDiscounts() async {
    final provider = context.read<DiscountProvider>();
    await provider.loadActiveDiscounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khuyến mãi'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshDiscounts,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Consumer<DiscountProvider>(
        builder: (context, provider, child) {
          if (provider.loading && provider.activeDiscounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final autoApplyDiscounts = provider.activeDiscounts
              .where((discount) => discount.isAutoApply && discount.isAvailable)
              .toList();

          return RefreshIndicator(
            onRefresh: _refreshDiscounts,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Manual discount code input section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhập mã khuyến mãi',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _discountCodeController,
                            decoration: InputDecoration(
                              labelText: 'Mã khuyến mãi',
                              hintText: 'Nhập mã giảm giá của bạn',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.local_offer),
                              suffixIcon: _discountCodeController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => _discountCodeController.clear(),
                                    )
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _applyDiscount,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Áp dụng mã',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Auto-apply discounts section
                  if (autoApplyDiscounts.isNotEmpty) ...[
                    Text(
                      'Khuyến mãi tự động áp dụng',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: autoApplyDiscounts.length,
                      itemBuilder: (context, index) {
                        final discount = autoApplyDiscounts[index];
                        return _buildDiscountCard(discount);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscountCard(DiscountModel discount) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectAutoApplyDiscount(discount),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Tag icon với màu đỏ như trong hình
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên chương trình khuyến mãi
                    Text(
                      discount.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Thông tin giảm giá
                    Text(
                      'Giảm theo ${discount.type == 'percentage' ? '%' : 'đ'} • ${discount.discountText}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Thời gian hết hạn
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Hết hạn: ${_formatDate(discount.endDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Mã code với gradient background như trong hình
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: discount.code.toUpperCase()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã copy mã: ${discount.code.toUpperCase()}'),
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
                        discount.code.toUpperCase(),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
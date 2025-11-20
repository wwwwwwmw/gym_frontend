import 'package:flutter/material.dart';
import 'package:gym_frontend/features/discounts/discount_model.dart';
import 'package:gym_frontend/features/discounts/discount_screen.dart';

class DiscountSelector extends StatefulWidget {
  final String? selectedDiscountCode;
  final Function(String?) onDiscountSelected;
  final double originalPrice;
  final String? packageId;

  const DiscountSelector({
    Key? key,
    this.selectedDiscountCode,
    required this.onDiscountSelected,
    required this.originalPrice,
    this.packageId,
  }) : super(key: key);

  @override
  State<DiscountSelector> createState() => _DiscountSelectorState();
}

class _DiscountSelectorState extends State<DiscountSelector> {
  String? _selectedCode;
  double? _discountAmount;
  double? _finalPrice;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.selectedDiscountCode;
    _calculateDiscount();
  }

  void _calculateDiscount() {
    if (_selectedCode != null && widget.originalPrice > 0) {
      // This would need to call the discount service to get actual discount amount
      // For now, we'll use a placeholder calculation
      _discountAmount = widget.originalPrice * 0.1; // 10% placeholder
      _finalPrice = widget.originalPrice - _discountAmount!;
    } else {
      _discountAmount = null;
      _finalPrice = widget.originalPrice;
    }
  }

  Future<void> _selectDiscount() async {
    final selectedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const DiscountScreen(),
      ),
    );

    if (selectedCode != null) {
      setState(() {
        _selectedCode = selectedCode;
        _calculateDiscount();
      });
      widget.onDiscountSelected(selectedCode);
    }
  }

  void _removeDiscount() {
    setState(() {
      _selectedCode = null;
      _discountAmount = null;
      _finalPrice = widget.originalPrice;
    });
    widget.onDiscountSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khuyến mãi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedCode != null)
                  TextButton.icon(
                    onPressed: _removeDiscount,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_selectedCode == null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectDiscount,
                  icon: const Icon(Icons.local_offer),
                  label: const Text('Chọn mã khuyến mãi'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã: ${_selectedCode!.toUpperCase()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (_discountAmount != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Giảm: ${_formatCurrency(_discountAmount!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Hiển thị mã code với gradient background
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFFA500)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedCode!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Price breakdown
            _buildPriceRow('Giá gốc', widget.originalPrice),
            if (_discountAmount != null) ...[
              _buildPriceRow('Giảm giá', -_discountAmount!, color: Colors.green),
              const Divider(height: 16),
              _buildPriceRow('Tổng cộng', _finalPrice!, 
                color: Theme.of(context).primaryColor,
                isBold: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            _formatCurrency(amount.abs()),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }
}
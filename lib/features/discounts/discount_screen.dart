import 'package:flutter/material.dart';
import 'package:gym_frontend/features/discounts/discount_model.dart';
import 'package:gym_frontend/features/discounts/discount_provider.dart';
import 'package:gym_frontend/features/campaigns/campaign_model.dart';
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
  String? _applyingCampaignId;
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
      await provider.validateDiscountCode(code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Áp dụng mã "${code.toUpperCase()}" thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mã khuyến mãi không hợp lệ: ${e.toString()}'),
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
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<DiscountProvider>();
      await provider.validateDiscountCode(discount.code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chọn khuyến mãi: ${discount.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(discount.code);
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

  Future<void> _selectCampaign(CampaignModel campaign) async {
    setState(() => _applyingCampaignId = campaign.id);
    
    try {
      final provider = context.read<DiscountProvider>();
      
      // Get best discount from campaign discount IDs
      if (campaign.discountIds.isNotEmpty) {
        // Find the discount in provider's active discounts
        final discountId = campaign.discountIds.first;
        final discount = provider.activeDiscounts.firstWhere(
          (d) => d.id == discountId,
          orElse: () => throw Exception('Discount not found'),
        );
        
        await provider.validateDiscountCode(discount.code);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã áp dụng chiến dịch: ${campaign.name}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(discount.code);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chiến dịch này không có mã giảm giá nào'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể áp dụng chiến dịch: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _applyingCampaignId = null);
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manual Code Entry Section
                  Card(
                    elevation: 2,
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
                              hintText: 'Nhập mã khuyến mãi của bạn',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_offer),
                              suffixIcon: _discountCodeController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear),
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
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Áp dụng mã'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Auto-apply Discounts Section
                  if (autoApplyDiscounts.isNotEmpty) ...[
                    Text(
                      'Khuyến mãi dành cho bạn',
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

                  // Available Campaigns Section
                  if (provider.activeCampaigns.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Chiến dịch khuyến mãi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.activeCampaigns.length,
                      itemBuilder: (context, index) {
                        final campaign = provider.activeCampaigns[index];
                        return _buildCampaignCard(
                          campaign,
                          isApplying: _applyingCampaignId == campaign.id,
                        );
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
      child: InkWell(
        onTap: () => _selectAutoApplyDiscount(discount),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    discount.discountText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discount.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (discount.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        discount.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Hết hạn: ${_formatDate(discount.endDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(CampaignModel campaign, {bool isApplying = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isApplying ? null : () => _selectCampaign(campaign),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      campaign.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isApplying)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCampaignStatusColor(campaign.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        campaign.campaignText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (campaign.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  campaign.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    campaign.targetAudienceText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCampaignStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'ended':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
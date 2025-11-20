import 'dart:async'; // Thêm import này để dùng Timer
import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/discounts/discount_model.dart';
import 'package:gym_frontend/features/discounts/discount_service.dart';
import 'package:gym_frontend/features/discounts/active_discounts_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_frontend/core/env.dart';

class GymPackage {
  final String id;
  final String name;
  final String description;
  final int price; // đơn vị: VND
  final int durationInDays; // số ngày
  final int? sessions; // số buổi (nếu có)
  final String? imageUrl; // hình ảnh gói tập

  GymPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationInDays,
    this.sessions,
    this.imageUrl,
  });

  factory GymPackage.fromJson(Map<String, dynamic> json) {
    return GymPackage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gói tập',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      durationInDays:
          (json['durationInDays'] as num?)?.toInt() ??
          (json['duration'] as num?)?.toInt() ??
          0,
      sessions: (json['sessions'] as num?)?.toInt(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class MemberRegisterPackageScreen extends StatefulWidget {
  const MemberRegisterPackageScreen({super.key});

  @override
  State<MemberRegisterPackageScreen> createState() =>
      _MemberRegisterPackageScreenState();
}

class _MemberRegisterPackageScreenState
    extends State<MemberRegisterPackageScreen> {
  final _api = ApiClient();
  late DiscountService _discountService; // Thêm service
  late Future<List<GymPackage>> _futurePackages;
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  bool _creatingOrder = false;

  @override
  void initState() {
    super.initState();
    _discountService = DiscountService(_api); // Khởi tạo service
    _futurePackages = _loadPackages();
  }

  Future<List<GymPackage>> _loadPackages() async {
    final res = await _api.getJson('/api/packages?page=1&limit=20');
    final raw = res['items'] ?? res['data'] ?? res['results'] ?? [];
    final list = (raw as List)
        .map((e) => GymPackage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list;
  }

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final r = raw.trim();
    if (r.startsWith('http://') || r.startsWith('https://')) return r;
    final base = apiBaseUrl();
    if (r.startsWith('/')) return '$base$r';
    return '$base/$r';
  }

  // Thêm tham số discountId và finalAmount vào hàm
  Future<void> _startVnPayPayment(
    GymPackage pkg,
    String? discountId,
    int finalAmount,
  ) async {
    if (_creatingOrder) return;
    setState(() => _creatingOrder = true);

    try {
      // Gửi yêu cầu đăng ký với paymentMethod là 'vnpay'
      // Backend sẽ tự động tạo Payment và trả về link thanh toán
      final res = await _api.postJson(
        '/api/registrations/me',
        body: {
          'packageId': pkg.id,
          if (discountId != null) 'discountId': discountId,
          'paymentMethod':
              'vnpay', // Quan trọng: Báo cho backend biết đây là VNPay
        },
      );

      final paymentUrl = res['paymentUrl']?.toString();

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw ApiException('Không nhận được link thanh toán từ server');
      }

      if (!mounted) return;

      // Đóng bottom sheet
      Navigator.of(context).pop();

      // Mở trình duyệt thanh toán (VNPay Sandbox)
      final uri = Uri.parse(paymentUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được trang thanh toán VNPay')),
        );
      } else {
        // (Tùy chọn) Chuyển hướng người dùng đến màn hình lịch sử thanh toán
        // hoặc hiển thị thông báo chờ kết quả
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingOrder = false);
      }
    }
  }

  void _onSelectPackage(GymPackage pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để tránh bàn phím che
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PackageRegistrationSheet(
          package: pkg,
          currencyFormatter: _currency,
          discountService: _discountService,
          onConfirm: (discountId, finalAmount) {
            _startVnPayPayment(pkg, discountId, finalAmount);
          },
          isCreatingOrder: _creatingOrder,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký gói tập'), centerTitle: true),
      body: FutureBuilder<List<GymPackage>>(
        future: _futurePackages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Không tải được danh sách gói tập.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _futurePackages = _loadPackages();
                        });
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final packages = snapshot.data ?? [];

          if (packages.isEmpty) {
            return const Center(child: Text('Hiện chưa có gói tập nào.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: packages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pkg = packages[index];
              final resolvedImage = _resolveImageUrl(pkg.imageUrl);
              final hasImage = resolvedImage != null;

              return InkWell(
                onTap: () => _onSelectPackage(pkg),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PACKAGE IMAGE
                      if (hasImage)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            resolvedImage,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: double.infinity,
                              height: 140,
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.fitness_center,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      // CONTENT
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!hasImage)
                                  Container(
                                    width: 48,
                                    height: 48,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.fitness_center,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pkg.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currency.format(pkg.price),
                                        style: TextStyle(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Thời hạn: ${pkg.durationInDays} ngày'
                              '${pkg.sessions != null ? ' • ${pkg.sessions} buổi' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (pkg.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                pkg.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Widget riêng cho BottomSheet để quản lý state của form nhập mã giảm giá
class _PackageRegistrationSheet extends StatefulWidget {
  final GymPackage package;
  final NumberFormat currencyFormatter;
  final DiscountService discountService;
  final Function(String? discountId, int finalAmount) onConfirm;
  final bool isCreatingOrder;

  const _PackageRegistrationSheet({
    required this.package,
    required this.currencyFormatter,
    required this.discountService,
    required this.onConfirm,
    required this.isCreatingOrder,
  });

  @override
  State<_PackageRegistrationSheet> createState() =>
      _PackageRegistrationSheetState();
}

class _PackageRegistrationSheetState extends State<_PackageRegistrationSheet> {
  final _discountController = TextEditingController();
  DiscountModel? _appliedDiscount;
  String? _discountError;
  bool _isValidating = false;
  int _finalPrice = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _finalPrice = widget.package.price;
  }

  @override
  void dispose() {
    _discountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _validateDiscount() async {
    final code = _discountController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _discountError = null;
      _appliedDiscount = null;
      _finalPrice = widget.package.price;
    });

    try {
      final discount = await widget.discountService.validate(
        code,
        widget.package.id,
      );

      // Tính toán giá mới
      int discountAmount = 0;
      if (discount.type == 'percentage') {
        // Backend: (price * value) / 100
        double raw = (widget.package.price * discount.value) / 100.0;
        if (discount.maxDiscountAmount != null &&
            raw > discount.maxDiscountAmount!) {
          raw = discount.maxDiscountAmount!.toDouble();
        }
        discountAmount = raw.toInt();
      } else {
        // Fixed
        discountAmount = discount.value.toInt();
      }

      setState(() {
        _appliedDiscount = discount;
        _finalPrice = (widget.package.price - discountAmount).clamp(
          0,
          999999999,
        );
      });
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _discountError =
              e.message; // Hiển thị lỗi từ Backend (hết hạn, sai gói, v.v.)
        } else {
          _discountError = 'Mã giảm giá không hợp lệ';
        }
      });
    } finally {
      setState(() => _isValidating = false);
    }
  }

  void _clearDiscount() {
    print('Clearing discount...'); // Debug print
    _discountController.clear();
    setState(() {
      _appliedDiscount = null;
      _discountError = null;
      _finalPrice = widget.package.price;
    });
    print('Discount cleared!'); // Debug print
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pkg = widget.package;

    // Lấy viewInsets để đẩy UI lên khi bàn phím mở
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + viewInsets.bottom, // Padding bottom theo bàn phím
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Handle bar
          Center(
            child: Container(
              width: 50,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          Text(
            pkg.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Thông tin gói
          Text(
            'Thời hạn: ${pkg.durationInDays} ngày'
            '${pkg.sessions != null ? ' • ${pkg.sessions} buổi' : ''}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          if (pkg.description.isNotEmpty) ...[
            Text(
              pkg.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 8),

          // --- DISCOUNT BANNER ---
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.red.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Có mã giảm giá?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Xem các mã khuyến mãi dành riêng cho gói này',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to package-specific discounts
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActiveDiscountsScreen(packageId: widget.package.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Xem mã'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- DISCOUNT INPUT SECTION ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountController,
                  readOnly: _appliedDiscount != null, // Chỉ readonly khi đã áp dụng, không disable hoàn toàn
                  enabled: true, // Luôn enabled để suffixIcon hoạt động
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giảm giá',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _discountError,
                    suffixIcon: _appliedDiscount != null
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: _clearDiscount,
                            tooltip: 'Xóa mã',
                            splashRadius: 24,
                            padding: const EdgeInsets.all(8),
                          )
                        : (_discountController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _discountController.clear();
                                  if (_discountError != null) {
                                    setState(() => _discountError = null);
                                  }
                                },
                                tooltip: 'Xóa',
                                splashRadius: 20,
                                padding: const EdgeInsets.all(8),
                              )
                            : null),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    if (_appliedDiscount == null) { // Chỉ cho phép thay đổi khi chưa áp dụng
                      // Xóa lỗi khi user gõ lại
                      if (_discountError != null)
                        setState(() => _discountError = null);
                      // Cập nhật UI để hiện/ẩn nút clear
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isValidating ? null : _validateDiscount,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Áp dụng'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- PRICE SUMMARY ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá gốc:', style: Theme.of(context).textTheme.bodyLarge),
              Text(
                widget.currencyFormatter.format(pkg.price),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  decoration: _appliedDiscount != null
                      ? TextDecoration.lineThrough
                      : null,
                  color: _appliedDiscount != null ? Colors.grey : null,
                ),
              ),
            ],
          ),

          if (_appliedDiscount != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã giảm (${_appliedDiscount!.type == 'percentage' ? '${_appliedDiscount!.value}%' : 'trực tiếp'}):',
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  '-${widget.currencyFormatter.format(pkg.price - _finalPrice)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thành tiền:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.currencyFormatter.format(_finalPrice),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- CONFIRM BUTTON ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: widget.isCreatingOrder
                  ? null
                  : () => widget.onConfirm(_appliedDiscount?.id, _finalPrice),
              child: widget.isCreatingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Thanh toán VNPay'),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

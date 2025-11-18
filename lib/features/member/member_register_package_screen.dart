import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
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
  late Future<List<GymPackage>> _futurePackages;
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  bool _creatingOrder = false; // trạng thái đang tạo đơn VNPay

  @override
  void initState() {
    super.initState();
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
    // Treat as relative path from API base
    final base = apiBaseUrl();
    if (r.startsWith('/')) return '$base$r';
    return '$base/$r';
  }

  /// Gọi API /api/registrations/me với paymentMethod = 'vnpay'
  /// rồi mở trang thanh toán VNPay
  /// Gọi API /api/payments/create-vnpay để lấy link thanh toán và lưu lịch sử
  Future<void> _startVnPayPayment(GymPackage pkg) async {
    if (_creatingOrder) return;
    setState(() => _creatingOrder = true);

    try {
      // 1. Đầu tiên phải tạo bản ghi đăng ký (Registration) trước
      // Để lấy được ID đăng ký (registrationId)
      final regRes = await _api.postJson(
        '/api/registrations/me',
        body: {
          'packageId': pkg.id,
          // 'paymentMethod': 'vnpay', // Không cần thiết nếu API không yêu cầu bắt buộc
        },
      );

      final registrationId =
          regRes['registration']?['_id'] ??
          regRes['data']?['_id'] ??
          regRes['_id']; // Tùy cấu trúc trả về của API registration

      if (registrationId == null) {
        throw ApiException('Lỗi: Không lấy được ID đăng ký gói tập');
      }

      // 2. Gọi API tạo thanh toán VNPay (API mới chúng ta vừa làm)
      final paymentRes = await _api.postJson(
        '/api/payments/create-vnpay',
        body: {
          'registrationId': registrationId,
          'amount': pkg.price, // Số tiền từ gói tập
          'locale': 'vn',
        },
      );

      final paymentUrl = paymentRes['paymentUrl']?.toString();

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw ApiException('Không nhận được link thanh toán từ server');
      }

      if (!mounted) return;

      // Đóng bottom sheet trước khi mở trình duyệt
      Navigator.of(context).pop();

      // Mở trình duyệt để thanh toán
      final uri = Uri.parse(paymentUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được trang thanh toán VNPay')),
        );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                _currency.format(pkg.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thời hạn: ${pkg.durationInDays} ngày'
                '${pkg.sessions != null ? ' • ${pkg.sessions} buổi' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              if (pkg.description.isNotEmpty)
                Text(
                  pkg.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 24),
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
                  onPressed: _creatingOrder
                      ? null
                      : () => _startVnPayPayment(pkg),
                  child: _creatingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Tiếp tục đăng ký'),
                ),
              ),
            ],
          ),
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

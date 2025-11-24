import 'dart:async'; // Thêm import này để dùng Timer
import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/discounts/discount_model.dart';
import 'package:gym_frontend/features/discounts/discount_service.dart';
import 'package:gym_frontend/features/discounts/active_discounts_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_frontend/core/env.dart';
import 'package:gym_frontend/features/trainer/trainer_service.dart';
import 'package:gym_frontend/features/trainer/trainer_model.dart';
import 'package:gym_frontend/features/registrations/registration_service.dart';
import 'package:gym_frontend/features/registrations/registration_model.dart';

class GymPackage {
  final String id;
  final String name;
  final String description;
  final int price; // đơn vị: VND
  final int durationInDays; // số ngày
  final int? sessions; // số buổi (nếu có)
  final String? imageUrl; // hình ảnh gói tập
  final List<String> features;
  final String? defaultTrainerId;
  final bool isPersonalTraining;

  GymPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationInDays,
    this.sessions,
    this.imageUrl,
    this.features = const [],
    this.defaultTrainerId,
    this.isPersonalTraining = false,
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
      features: ((json['features'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      defaultTrainerId: (() {
        final v =
            json['defaultTrainerId'] ??
            json['defaultTrainer'] ??
            json['trainerId'];
        return v?.toString();
      })(),
      isPersonalTraining: (() {
        final v = json['isPersonalTraining'];
        if (v is bool) return v;
        if (v is String)
          return v.toLowerCase() == 'true' ||
              v.toUpperCase() == 'PT' ||
              v.toUpperCase() == 'PERSONAL_TRAINING';
        if (v is num) return v == 1;
        final requiresTrainer = json['requiresTrainer'];
        if (requiresTrainer is bool && requiresTrainer) return true;
        final type = (json['type']?.toString() ?? '').toUpperCase();
        if (type == 'PT' || type == 'PERSONAL_TRAINING') return true;
        final feats = ((json['features'] as List?) ?? const [])
            .map((e) => e.toString().toLowerCase())
            .toList();
        if (feats.any(
          (f) =>
              f.contains('pt') ||
              f.contains('personal') ||
              f.contains('huấn luyện') ||
              f.contains('trainer'),
        )) {
          return true;
        }
        return false;
      })(),
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
  final _registrationService = RegistrationService(ApiClient());

  bool _creatingOrder = false;
  List<RegistrationModel>? _activePackages;
  bool _hasCheckedActivePackages = false;

  @override
  void initState() {
    super.initState();
    _discountService = DiscountService(_api); // Khởi tạo service
    _futurePackages = _loadPackages();
    _checkActivePackages();
  }

  Future<void> _checkActivePackages() async {
    try {
      final active = await _registrationService.getSelfActive();
      if (mounted) {
        setState(() {
          _activePackages = active;
          _hasCheckedActivePackages = true;
        });
      }
    } catch (_) {
      // Ignore error, just don't show warning
      if (mounted) {
        setState(() {
          _hasCheckedActivePackages = true;
        });
      }
    }
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

  Future<void> _submitRegistration(
    GymPackage pkg,
    String? discountId,
    int finalAmount,
    String method,
    String? trainerId, {
    bool prebook = false,
  }) async {
    if (_creatingOrder) return;
    setState(() => _creatingOrder = true);

    try {
      // Nếu có active package, tự động dùng prebook
      final shouldPrebook =
          prebook || (_activePackages != null && _activePackages!.isNotEmpty);

      final res = await _api.postJson(
        '/api/registrations/me',
        body: {
          'packageId': pkg.id,
          if (discountId != null) 'discountId': discountId,
          'paymentMethod': method,
          if (trainerId != null) 'trainerId': trainerId,
          if (shouldPrebook) 'prebook': true,
        },
        includeErrorResponse: true, // Để lấy response body khi lỗi
      );

      if (method == 'vnpay') {
        final paymentUrl = res['paymentUrl']?.toString();
        if (paymentUrl == null || paymentUrl.isEmpty) {
          throw ApiException('Không nhận được link thanh toán từ server');
        }
        if (!mounted) return;
        Navigator.of(context).pop();
        final uri = Uri.parse(paymentUrl);
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không mở được trang thanh toán VNPay'),
            ),
          );
        }
      } else {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldPrebook
                  ? 'Đã đăng ký gói tập mới. Gói sẽ bắt đầu sau khi gói hiện tại kết thúc.'
                  : 'Đã gửi đăng ký, vui lòng chờ duyệt',
            ),
          ),
        );
        Navigator.of(context).pushNamed('/member/current-package');
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      // Xử lý lỗi 400 - đã có gói tập đang hoạt động hoặc lịch tập trùng
      if (e.statusCode == 400) {
        if (e.message.contains('lịch tập trùng') ||
            e.message.contains('trùng với gói đang hoạt động')) {
          // Lỗi do lịch tập trùng
          await _handleScheduleConflictError(
            pkg,
            discountId,
            finalAmount,
            method,
            trainerId,
            e.responseBody,
            e.message,
          );
          return;
        } else if (e.message.contains('đã có gói tập đang hoạt động') ||
            e.message.contains('Thành viên đã có gói tập')) {
          // Lỗi do đã có gói active (có thể không trùng lịch nhưng vẫn bị chặn)
          await _handleActivePackageError(
            pkg,
            discountId,
            finalAmount,
            method,
            trainerId,
            e.responseBody,
          );
          return;
        }
      }

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

  Future<void> _handleActivePackageError(
    GymPackage pkg,
    String? discountId,
    int finalAmount,
    String method,
    String? trainerId,
    Map<String, dynamic>? errorResponse,
  ) async {
    if (!mounted) return;

    // Lấy thông tin gói đang active từ error response hoặc từ state
    RegistrationModel? activePackage;
    String? packageName;
    String? endDateStr;

    if (errorResponse != null && errorResponse['activePackage'] != null) {
      try {
        final reg = RegistrationModel.fromJson(errorResponse['activePackage']);
        activePackage = reg;
        packageName = reg.package.name;
        endDateStr = DateFormat('dd/MM/yyyy').format(reg.endDate);
      } catch (_) {
        // Ignore
      }
    }

    // Fallback: dùng active package từ state
    if (activePackage == null &&
        _activePackages != null &&
        _activePackages!.isNotEmpty) {
      final reg = _activePackages!.first;
      activePackage = reg;
      packageName = reg.package.name;
      endDateStr = DateFormat('dd/MM/yyyy').format(reg.endDate);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Expanded(child: Text('Bạn đã có gói tập đang hoạt động')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (packageName != null) ...[
              Text(
                'Gói hiện tại: $packageName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (endDateStr != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Kết thúc: $endDateStr',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 16),
            ],
            const Text(
              'Bạn có muốn đăng ký gói mới để bắt đầu sau khi gói hiện tại kết thúc không?',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gói mới sẽ tự động bắt đầu sau khi gói hiện tại kết thúc',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Đăng ký gói mới'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Đăng ký với prebook = true
      await _submitRegistration(
        pkg,
        discountId,
        finalAmount,
        method,
        trainerId,
        prebook: true,
      );
    }
  }

  Future<void> _handleScheduleConflictError(
    GymPackage pkg,
    String? discountId,
    int finalAmount,
    String method,
    String? trainerId,
    Map<String, dynamic>? errorResponse,
    String errorMessage,
  ) async {
    if (!mounted) return;

    // Lấy thông tin gói đang active từ error response hoặc từ state
    RegistrationModel? activePackage;
    String? packageName;
    String? endDateStr;

    if (errorResponse != null && errorResponse['activePackage'] != null) {
      try {
        final reg = RegistrationModel.fromJson(errorResponse['activePackage']);
        activePackage = reg;
        packageName = reg.package.name;
        endDateStr = DateFormat('dd/MM/yyyy').format(reg.endDate);
        // Lấy lịch tập của gói đang active (nếu có)
        // Note: Cần check trong package data
      } catch (_) {
        // Ignore
      }
    }

    // Fallback: dùng active package từ state
    if (activePackage == null &&
        _activePackages != null &&
        _activePackages!.isNotEmpty) {
      final reg = _activePackages!.first;
      activePackage = reg;
      packageName = reg.package.name;
      endDateStr = DateFormat('dd/MM/yyyy').format(reg.endDate);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Expanded(child: Text('Lịch tập bị trùng')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (packageName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gói đang hoạt động: $packageName',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    if (endDateStr != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Kết thúc: $endDateStr',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có thể đăng ký gói mới với lịch tập khác (ví dụ: nếu gói hiện tại là 2-4-6, bạn có thể đăng ký gói 3-5-7)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hoặc đăng ký prebook để gói mới bắt đầu sau khi gói hiện tại kết thúc?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Đăng ký prebook'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Đăng ký với prebook = true
      await _submitRegistration(
        pkg,
        discountId,
        finalAmount,
        method,
        trainerId,
        prebook: true,
      );
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
          apiClient: _api,
          onConfirm: (discountId, finalAmount, method, trainerId) {
            _submitRegistration(
              pkg,
              discountId,
              finalAmount,
              method,
              trainerId,
            );
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

          return Column(
            children: [
              // Cảnh báo nếu có gói đang active
              if (_hasCheckedActivePackages &&
                  _activePackages != null &&
                  _activePackages!.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bạn đang có gói tập đang hoạt động',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gói mới sẽ tự động bắt đầu sau khi gói hiện tại kết thúc',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: ListView.separated(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!hasImage)
                                        Container(
                                          width: 48,
                                          height: 48,
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF5F5),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                ),
              ),
            ],
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
  final ApiClient apiClient;
  final Function(
    String? discountId,
    int finalAmount,
    String method,
    String? trainerId,
  )
  onConfirm;
  final bool isCreatingOrder;

  const _PackageRegistrationSheet({
    required this.package,
    required this.currencyFormatter,
    required this.discountService,
    required this.apiClient,
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
  String _paymentMethod = 'vnpay';
  List<TrainerModel> _trainers = const [];
  bool _loadingTrainers = false;
  String? _selectedTrainerId;
  late final TrainerService _trainerService = TrainerService(widget.apiClient);
  bool _overrideTrainer = false;
  Map<String, dynamic>? _trainerScheduleSummary;
  bool _loadingTrainerSchedule = false;

  @override
  void initState() {
    super.initState();
    _finalPrice = widget.package.price;
    if (widget.package.isPersonalTraining) {
      if (widget.package.defaultTrainerId != null &&
          widget.package.defaultTrainerId!.isNotEmpty) {
        _selectedTrainerId = widget.package.defaultTrainerId;
      }
      _fetchTrainers();
      if (_selectedTrainerId != null && _selectedTrainerId!.isNotEmpty) {
        _fetchTrainerScheduleSummary(_selectedTrainerId!);
      }
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchTrainers() async {
    if (!mounted) return;
    setState(() => _loadingTrainers = true);
    try {
      final list = await _trainerService.getActiveTrainers();
      if (!mounted) return;
      setState(() => _trainers = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _trainers = const []);
    } finally {
      if (mounted) {
        setState(() => _loadingTrainers = false);
      }
    }
  }

  Future<void> _fetchTrainerScheduleSummary(String id) async {
    if (!mounted) return;
    setState(() => _loadingTrainerSchedule = true);
    try {
      final res = await widget.apiClient.getJson(
        '/api/work-schedules/trainer/$id/summary',
        query: {'packageId': widget.package.id},
      );
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res['data'] ?? {});
      setState(() => _trainerScheduleSummary = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _trainerScheduleSummary = null);
    } finally {
      if (mounted) {
        setState(() => _loadingTrainerSchedule = false);
      }
    }
  }

  Widget _buildTrainerSchedulePreview() {
    if (_loadingTrainerSchedule) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 28,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    final data = _trainerScheduleSummary;
    if (data == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Chưa tải được lịch huấn luyện viên',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    final days = (data['daysOfWeek'] as List?)?.cast<int>() ?? const [];
    final sc = Map<String, dynamic>.from(data['shiftCounts'] ?? {});
    String commonShift = 'morning';
    int m = (sc['morning'] ?? 0) as int;
    int a = (sc['afternoon'] ?? 0) as int;
    int e = (sc['evening'] ?? 0) as int;
    if (a >= m && a >= e) {
      commonShift = 'afternoon';
    } else if (e >= m && e >= a) {
      commonShift = 'evening';
    }
    String shiftLabel = commonShift == 'morning'
        ? 'Sáng'
        : (commonShift == 'afternoon' ? 'Trưa' : 'Chiều');
    final dayNums = days.isNotEmpty ? days.join(' ') : '';
    final items = (data['items'] as List?)?.cast<Map>() ?? const [];
    final nextItems = items.take(5).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dayNums.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.event_available, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lịch HLV: $dayNums • Ca: $shiftLabel',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (nextItems.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...nextItems.map((e) {
              final date = DateTime.tryParse(e['date']?.toString() ?? '');
              final ds = date != null ? DateFormat('dd/MM').format(date) : '';
              final sh = (e['shiftType']?.toString() ?? '');
              final sl = sh == 'morning'
                  ? 'Sáng'
                  : (sh == 'afternoon' ? 'Chiều' : 'Tối');
              final st = e['startTime']?.toString() ?? '';
              final et = e['endTime']?.toString() ?? '';
              return Row(
                children: [
                  const Icon(Icons.schedule, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$ds • Ca: $sl • $st–$et',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _validateDiscount() async {
    final code = _discountController.text.trim();
    if (code.isEmpty) return;

    if (!mounted) return;
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

      if (!mounted) return;

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
      if (!mounted) return;
      setState(() {
        if (e is ApiException) {
          _discountError =
              e.message; // Hiển thị lỗi từ Backend (hết hạn, sai gói, v.v.)
        } else {
          _discountError = 'Mã giảm giá không hợp lệ';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
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
            if (widget.package.isPersonalTraining) ...[
              Text(
                'Huấn luyện viên',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Builder(
                  builder: (context) {
                    if (widget.package.defaultTrainerId != null &&
                        widget.package.defaultTrainerId!.isNotEmpty &&
                        !_overrideTrainer) {
                      final match = _trainers.firstWhere(
                        (t) => t.id == widget.package.defaultTrainerId,
                        orElse: () => _trainers.isNotEmpty
                            ? _trainers.first
                            : TrainerModel(
                                id: widget.package.defaultTrainerId!,
                                fullName: 'Huấn luyện viên đã gán',
                                email: '',
                                phone: '',
                                status: 'active',
                              ),
                      );
                      final summaryName = (_trainerScheduleSummary != null)
                          ? (_trainerScheduleSummary!['trainer']?['fullName']
                                    ?.toString() ??
                                '')
                          : '';
                      final displayName = (summaryName.isNotEmpty
                          ? summaryName
                          : (match.fullName.isNotEmpty
                                ? match.fullName
                                : 'Huấn luyện viên đã gán'));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _overrideTrainer = true;
                                  });
                                },
                                child: const Text('Đổi HLV'),
                              ),
                            ],
                          ),
                          _buildTrainerSchedulePreview(),
                        ],
                      );
                    }
                    if (_loadingTrainers) {
                      return const SizedBox(
                        height: 40,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (_trainers.isEmpty) {
                      return Text(
                        'Chưa có huấn luyện viên đang hoạt động',
                        style: TextStyle(color: Colors.grey.shade600),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedTrainerId,
                          items: _trainers
                              .map(
                                (t) => DropdownMenuItem<String>(
                                  value: t.id,
                                  child: Text(
                                    t.fullName.isNotEmpty
                                        ? t.fullName
                                        : (t.email.isNotEmpty
                                              ? t.email
                                              : 'HLV'),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedTrainerId = v);
                            if (v != null && v.isNotEmpty) {
                              _fetchTrainerScheduleSummary(v);
                            }
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                        _buildTrainerSchedulePreview(),
                        if (widget.package.defaultTrainerId != null &&
                            widget.package.defaultTrainerId!.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _overrideTrainer = false;
                                  _selectedTrainerId =
                                      widget.package.defaultTrainerId;
                                });
                                if (widget.package.defaultTrainerId != null &&
                                    widget
                                        .package
                                        .defaultTrainerId!
                                        .isNotEmpty) {
                                  _fetchTrainerScheduleSummary(
                                    widget.package.defaultTrainerId!,
                                  );
                                }
                              },
                              child: const Text('Dùng mặc định'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
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
                  colors: [Colors.orange.shade50, Colors.red.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 1),
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
                          builder: (context) => ActiveDiscountsScreen(
                            packageId: widget.package.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Xem mã'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                    readOnly:
                        _appliedDiscount !=
                        null, // Chỉ readonly khi đã áp dụng, không disable hoàn toàn
                    enabled: true, // Luôn enabled để suffixIcon hoạt động
                    decoration: InputDecoration(
                      hintText: 'Nhập mã giảm giá',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
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
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
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
                      if (_appliedDiscount == null) {
                        // Chỉ cho phép thay đổi khi chưa áp dụng
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

            Text(
              'Hình thức thanh toán',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'vnpay',
                    groupValue: _paymentMethod,
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v ?? 'vnpay'),
                    title: const Text('VNPay'),
                    subtitle: const Text('Thanh toán online qua VNPay'),
                    secondary: const Icon(Icons.credit_card),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'cash',
                    groupValue: _paymentMethod,
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v ?? 'cash'),
                    title: const Text('Tiền mặt'),
                    subtitle: const Text('Thanh toán trực tiếp tại quầy'),
                    secondary: const Icon(Icons.payments_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                    : () {
                        if (widget.package.isPersonalTraining &&
                            (_selectedTrainerId == null ||
                                _selectedTrainerId!.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng chọn huấn luyện viên'),
                            ),
                          );
                          return;
                        }
                        widget.onConfirm(
                          _appliedDiscount?.id,
                          _finalPrice,
                          _paymentMethod,
                          _selectedTrainerId,
                        );
                      },
                child: widget.isCreatingOrder
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _paymentMethod == 'vnpay'
                            ? 'Thanh toán VNPay'
                            : 'Thanh toán tiền mặt',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

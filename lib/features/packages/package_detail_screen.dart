import 'package:flutter/material.dart';
import 'package:gym_frontend/features/packages/package_model.dart';
import 'package:gym_frontend/features/registrations/registration_model.dart';
import 'package:gym_frontend/core/env.dart';
import 'package:intl/intl.dart';
import 'package:gym_frontend/core/api_client.dart';

class PackageDetailScreen extends StatefulWidget {
  final PackageModel package;
  final RegistrationModel? currentRegistration;

  const PackageDetailScreen({
    super.key,
    required this.package,
    this.currentRegistration,
  });

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  Map<String, dynamic>? _trainerInfo;
  bool _loadingTrainer = false;
  RegistrationModel? _currentRegistration;
  bool _loadingRegistration = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo với registration hiện tại
    _currentRegistration = widget.currentRegistration;

    // Nếu đã có thông tin trainer từ populate, dùng luôn
    if (widget.package.defaultTrainer != null) {
      _trainerInfo = widget.package.defaultTrainer;
    } else if (widget.package.defaultTrainerId != null) {
      // Nếu chưa có, fetch từ API
      _fetchTrainerInfo();
    }

    // Fetch lại registration data để đảm bảo có thông tin mới nhất (sau khi gia hạn)
    if (_currentRegistration != null) {
      _refreshRegistration();
    }
  }

  Future<void> _refreshRegistration() async {
    if (_currentRegistration == null) return;

    setState(() => _loadingRegistration = true);
    try {
      final api = ApiClient();
      // Sử dụng endpoint /api/registrations/me/active cho MEMBER
      // Lấy danh sách active packages và tìm registration có ID tương ứng
      try {
        final res = await api.getJson('/api/registrations/me/active');
        if (mounted && res['activePackages'] != null) {
          final activePackages = (res['activePackages'] as List)
              .map((e) => RegistrationModel.fromJson(e))
              .toList();

          // Tìm registration có ID tương ứng
          final updated = activePackages.firstWhere(
            (r) => r.id == _currentRegistration!.id,
            orElse: () => _currentRegistration!,
          );

          if (updated.id == _currentRegistration!.id) {
            setState(() {
              _currentRegistration = updated;
              _loadingRegistration = false;
            });
            print(
              '✅ Đã refresh registration từ /api/registrations/me/active: endDate = ${updated.endDate}, remainingSessions = ${updated.remainingSessions}',
            );
            return;
          }
        }
      } catch (e) {
        print('⚠️ Endpoint /api/registrations/me/active không khả dụng: $e');
      }

      // Fallback: Thử endpoint /api/registrations/me
      try {
        final res = await api.getJson('/api/registrations/me');
        if (mounted && res['registrations'] != null) {
          final registrations = (res['registrations'] as List)
              .map((e) => RegistrationModel.fromJson(e))
              .toList();

          // Tìm registration có ID tương ứng
          final updated = registrations.firstWhere(
            (r) => r.id == _currentRegistration!.id,
            orElse: () => _currentRegistration!,
          );

          if (updated.id == _currentRegistration!.id) {
            setState(() {
              _currentRegistration = updated;
              _loadingRegistration = false;
            });
            print(
              '✅ Đã refresh registration từ /api/registrations/me: endDate = ${updated.endDate}, remainingSessions = ${updated.remainingSessions}',
            );
            return;
          }
        }
      } catch (e) {
        print('⚠️ Endpoint /api/registrations/me không khả dụng: $e');
      }

      // Nếu không tìm thấy, giữ nguyên data cũ
      if (mounted) {
        setState(() => _loadingRegistration = false);
      }
    } catch (e) {
      print('❌ Lỗi khi refresh registration: $e');
      // Nếu không fetch được, giữ nguyên data cũ
      if (mounted) {
        setState(() => _loadingRegistration = false);
      }
    }
  }

  Future<void> _fetchTrainerInfo() async {
    if (widget.package.defaultTrainerId == null) return;

    setState(() => _loadingTrainer = true);
    try {
      final api = ApiClient();
      final res = await api.getJson(
        '/api/employees/${widget.package.defaultTrainerId}',
      );
      if (mounted) {
        setState(() {
          _trainerInfo = res['data'] ?? res;
          _loadingTrainer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTrainer = false);
      }
    }
  }

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final r = raw.trim();
    if (r.startsWith('http://') || r.startsWith('https://')) return r;
    final base = apiBaseUrl();
    if (r.startsWith('/')) return '$base$r';
    return '$base/$r';
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ nhật';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedImage = _resolveImageUrl(widget.package.imageUrl);
    final hasImage = resolvedImage != null;
    String _vnd(num n) => NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(n);
    // Sử dụng _currentRegistration thay vì widget.currentRegistration để có data mới nhất
    final registration = _currentRegistration ?? widget.currentRegistration;
    final renewed = (registration?.statusReason ?? '').toLowerCase().contains(
      'gia hạn',
    );
    final renewDays = _extractRenewDays(registration?.statusReason);
    final renewSessions = _extractRenewSessions(registration?.statusReason);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết gói tập'),
        centerTitle: true,
        actions: [
          if (registration != null)
            IconButton(
              icon: _loadingRegistration
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _loadingRegistration ? null : _refreshRegistration,
              tooltip: 'Làm mới',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: registration != null ? _refreshRegistration : () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (renewed)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.autorenew, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        renewSessions != null
                            ? 'Gói đã gia hạn thêm $renewSessions buổi'
                            : renewDays != null
                            ? 'Gói đã gia hạn thêm $renewDays ngày'
                            : (registration?.statusReason ?? 'Gói đã gia hạn'),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // PACKAGE IMAGE
            if (hasImage)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    resolvedImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),

            // PACKAGE INFO CARD
            Container(
              padding: const EdgeInsets.all(16),
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
                  // PACKAGE NAME
                  Text(
                    widget.package.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // PRICE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _vnd(widget.package.price),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.error,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // DURATION
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thời hạn: ${widget.package.duration} ngày',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),

                  // PERSONAL TRAINING
                  if (widget.package.isPersonalTraining) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bao gồm PT (Huấn luyện viên cá nhân)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    // Hiển thị PT mặc định từ package
                    if (widget.package.defaultTrainerId != null ||
                        widget.package.defaultTrainer != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _loadingTrainer
                                ? const Text(
                                    'Đang tải thông tin PT...',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Text(
                                    'Huấn luyện viên mặc định: ${_trainerInfo?['fullName'] ?? widget.package.defaultTrainer?['fullName'] ?? _trainerInfo?['email'] ?? widget.package.defaultTrainer?['email'] ?? 'Chưa xác định'}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                          ),
                        ],
                      ),
                    ],
                    // Hiển thị PT từ registration nếu có
                    if (widget.currentRegistration?.trainer != null &&
                        widget
                            .currentRegistration!
                            .trainer!
                            .fullName
                            .isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Huấn luyện viên đã gán: ${widget.currentRegistration!.trainer!.fullName}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // LỊCH TẬP CỐ ĐỊNH
                  if (widget.package.hasFixedSchedule == true &&
                      widget.package.schedule != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Lịch tập',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Thứ trong tuần
                    if (widget.package.schedule!['daysOfWeek'] != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Thứ: ${(widget.package.schedule!['daysOfWeek'] as List).map((d) => _getDayName(d as int)).join(', ')}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Khung giờ
                    if (widget.package.schedule!['startTime'] != null &&
                        widget.package.schedule!['startTime']
                            .toString()
                            .isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Khung giờ: ${widget.package.schedule!['startTime']} - ${widget.package.schedule!['endTime'] ?? '--:--'}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // DESCRIPTION
                  if (widget.package.description != null &&
                      widget.package.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.package.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // FEATURES
                  if (widget.package.features.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Tính năng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.package.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // CURRENT REGISTRATION INFO
            if (registration != null) ...[
              if (_loadingRegistration)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đang tải thông tin mới nhất...',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Thông tin đăng ký',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.check_circle_outline,
                      'Trạng thái',
                      _statusVietnamese(registration.status),
                      _statusColor(registration.status),
                    ),
                    if (registration.trainer != null &&
                        registration.trainer!.fullName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.person_outline,
                        'Huấn luyện viên',
                        registration.trainer!.fullName,
                        Colors.grey.shade700,
                      ),
                    ],
                    if (renewed) ...[
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.autorenew,
                        'Gia hạn',
                        renewSessions != null
                            ? 'Thêm $renewSessions buổi'
                            : renewDays != null
                            ? 'Thêm $renewDays ngày'
                            : (registration.statusReason ?? ''),
                        Colors.green.shade700,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.calendar_month,
                      'Từ ngày',
                      _formatDate(registration.startDate),
                      Colors.grey.shade700,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.event,
                      'Đến ngày',
                      _formatDate(registration.endDate),
                      Colors.grey.shade700,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.timelapse,
                      'Tổng thời hạn',
                      '${registration.endDate.difference(registration.startDate).inDays + 1} ngày',
                      Colors.grey.shade700,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.hourglass_bottom,
                      'Còn lại',
                      '${(registration.endDate.difference(DateTime.now()).inDays < 0 ? 0 : registration.endDate.difference(DateTime.now()).inDays + 1)} ngày',
                      Colors.green.shade700,
                    ),
                    // Hiển thị số buổi còn lại nếu có (gói theo buổi)
                    if (registration.remainingSessions != null) ...[
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.fitness_center,
                        'Số buổi còn lại',
                        '${registration.remainingSessions} buổi',
                        Colors.orange.shade700,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.payments,
                      renewed ? 'Giá gia hạn' : 'Giá thanh toán',
                      _vnd(registration.finalPrice),
                      cs.error,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _statusVietnamese(String status) {
    switch (status) {
      case 'active':
        return 'Đang hoạt động';
      case 'pending':
        return 'Chờ duyệt';
      case 'expired':
        return 'Đã hết hạn';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'expired':
        return Colors.grey.shade600;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int? _extractRenewDays(String? reason) {
    if (reason == null) return null;
    final r = reason.toLowerCase();
    // Tìm số ngày: "gia hạn thêm X ngày"
    final dayMatch = RegExp(r'giai? hạn thêm\s*(\d+)\s*ngày').firstMatch(r);
    if (dayMatch != null) {
      final val = int.tryParse(dayMatch.group(1) ?? '');
      if (val != null && val > 0) return val;
    }
    return null;
  }

  int? _extractRenewSessions(String? reason) {
    if (reason == null) return null;
    final r = reason.toLowerCase();
    // Tìm số buổi: "gia hạn thêm X buổi"
    final sessionMatch = RegExp(r'giai? hạn thêm\s*(\d+)\s*buổi').firstMatch(r);
    if (sessionMatch != null) {
      final val = int.tryParse(sessionMatch.group(1) ?? '');
      if (val != null && val > 0) return val;
    }
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/registrations/registration_model.dart';
import 'package:gym_frontend/features/registrations/registration_service.dart';
import 'package:intl/intl.dart';

class MyStudentsScreen extends StatefulWidget {
  const MyStudentsScreen({super.key});

  @override
  State<MyStudentsScreen> createState() => _MyStudentsScreenState();
}

class _MyStudentsScreenState extends State<MyStudentsScreen> {
  final _svc = RegistrationService(ApiClient());
  bool _loading = true;
  String? _error;
  String? _status;
  int _page = 1;
  int _pages = 1;
  int _total = 0;
  List<RegistrationModel> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (list, pageInfo) = await _svc.listMineAsTrainer(
        status: _status,
        page: page,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _items = list;
          _page = pageInfo['page'] ?? 1;
          _pages = pageInfo['pages'] ?? 1;
          _total = pageInfo['total'] ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Không thể tải danh sách học viên';
        if (e.toString().contains('401') ||
            e.toString().contains('chưa đăng nhập')) {
          errorMessage = 'Bạn chưa đăng nhập hoặc phiên đã hết hạn';
        } else if (e.toString().contains('403') ||
            e.toString().contains('quyền')) {
          errorMessage = 'Bạn chưa có quyền xem danh sách học viên';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Không tìm thấy học viên';
        } else if (e.toString().contains('500') ||
            e.toString().contains('Máy chủ')) {
          errorMessage = 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau';
        } else {
          final msg = e.toString();
          if (msg.contains('Exception: ')) {
            errorMessage = msg.split('Exception: ').last;
          } else if (msg.length < 100) {
            errorMessage = msg;
          }
        }
        setState(() => _error = errorMessage);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Học viên của tôi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                HapticFeedback.selectionClick();
                _fetch(page: _page);
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: 'Bỏ lọc',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _status = null);
                _fetch(page: 1);
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + 20),
            _buildFilterSection(),
            Expanded(
              child: _loading
                  ? _buildLoadingWidget()
                  : _error != null
                  ? _buildErrorWidget(_error!)
                  : _items.isEmpty
                  ? _buildEmptyState()
                  : _buildStudentsList(),
            ),
            if (!_loading && _items.isNotEmpty) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF667eea).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: Color(0xFF667eea),
                  size: 14,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_status != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Đang lọc',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          _buildModernFilterDropdown(),
        ],
      ),
    );
  }

  Widget _buildModernFilterDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.08),
            Colors.green.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.green, size: 12),
              SizedBox(width: 2),
              Flexible(
                child: Text(
                  'Trạng thái',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _status,
              isDense: true,
              isExpanded: true,
              hint: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tất cả',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.green, size: 14),
                ],
              ),
              items: _statusOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option['label']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_status == option['value'])
                        Icon(Icons.check, color: Colors.green, size: 12),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _status = value);
                _fetch(page: 1);
              },
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              icon: SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Đang tải danh sách học viên...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                _fetch(page: _page);
              },
              icon: Icon(Icons.refresh),
              label: Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Chưa có học viên',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn chưa có học viên nào đăng ký gói tập.\n'
              'Học viên sẽ xuất hiện ở đây khi họ đăng ký gói tập với bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _status = null);
                _fetch(page: 1);
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Bỏ lọc và tải lại'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    // Sort by date descending (newest first)
    final sortedItems = List<RegistrationModel>.from(_items);
    sortedItems.sort((a, b) {
      final dateA = DateTime(
        a.startDate.year,
        a.startDate.month,
        a.startDate.day,
      );
      final dateB = DateTime(
        b.startDate.year,
        b.startDate.month,
        b.startDate.day,
      );
      return dateB.compareTo(dateA); // Descending
    });

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final registration = sortedItems[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: _buildStudentCard(registration),
        );
      },
    );
  }

  Widget _buildStudentCard(RegistrationModel r) {
    final statusColor = _getStatusColor(r.status);
    final statusText = _statusVi(r.status);

    // Format dates
    final startDate = DateFormat(
      'dd/MM/yyyy',
      'vi_VN',
    ).format(r.startDate.toLocal());
    final endDate = DateFormat(
      'dd/MM/yyyy',
      'vi_VN',
    ).format(r.endDate.toLocal());

    // Format price
    final priceFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final finalPrice = priceFormat.format(r.finalPrice);

    // Get preferred days and shift
    final dayNames = {
      1: 'Thứ 2',
      2: 'Thứ 3',
      3: 'Thứ 4',
      4: 'Thứ 5',
      5: 'Thứ 6',
      6: 'Thứ 7',
      7: 'Chủ nhật',
    };

    String scheduleText = '';
    if (r.memberPreferredDays != null && r.memberPreferredDays!.isNotEmpty) {
      final names = List<int>.from(r.memberPreferredDays!)..sort();
      scheduleText = names.map((d) => dayNames[d] ?? d.toString()).join(', ');
      if (r.memberPreferredShift != null) {
        final shiftText = r.memberPreferredShift == 'afternoon'
            ? 'Trưa'
            : (r.memberPreferredShift == 'evening' ? 'Chiều' : 'Sáng');
        scheduleText += ' • Ca: $shiftText';
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.1),
            Colors.white,
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            // TODO: Navigate to student detail
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor,
                            statusColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.member.fullName.isNotEmpty
                                ? r.member.fullName
                                : '(Không rõ tên)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            r.package.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey[200]),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '$startDate → $endDate',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (scheduleText.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          scheduleText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.grey[600], size: 16),
                    SizedBox(width: 6),
                    Text(
                      finalPrice,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (r.remainingSessions != null) ...[
                      SizedBox(width: 16),
                      Icon(
                        Icons.fitness_center,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Còn ${r.remainingSessions} buổi',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (r.member.phone != null && r.member.phone!.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey[600], size: 16),
                      SizedBox(width: 6),
                      Text(
                        r.member.phone!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tổng: $_total học viên',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1
                    ? () {
                        HapticFeedback.selectionClick();
                        _fetch(page: _page - 1);
                      }
                    : null,
                icon: Icon(Icons.chevron_left),
                color: _page > 1 ? Color(0xFF667eea) : Colors.grey[400],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Trang $_page/$_pages',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667eea),
                  ),
                ),
              ),
              IconButton(
                onPressed: _page < _pages
                    ? () {
                        HapticFeedback.selectionClick();
                        _fetch(page: _page + 1);
                      }
                    : null,
                icon: Icon(Icons.chevron_right),
                color: _page < _pages ? Color(0xFF667eea) : Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusVi(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'active':
        return 'Hoạt động';
      case 'suspended':
        return 'Tạm dừng';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return s;
    }
  }

  List<Map<String, String>> get _statusOptions => [
    {'value': 'pending', 'label': 'Chờ duyệt'},
    {'value': 'active', 'label': 'Hoạt động'},
    {'value': 'suspended', 'label': 'Tạm dừng'},
    {'value': 'cancelled', 'label': 'Đã hủy'},
    {'value': 'expired', 'label': 'Hết hạn'},
  ];
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'work_schedule_provider.dart';
import 'work_schedule_model.dart';
import 'package:intl/intl.dart';

class WorkSchedulesScreen extends StatefulWidget {
  const WorkSchedulesScreen({super.key});

  @override
  State<WorkSchedulesScreen> createState() => _WorkSchedulesScreenState();
}

class _WorkSchedulesScreenState extends State<WorkSchedulesScreen> {
  DateTime? _date;
  String? _status;
  String? _shiftType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<WorkScheduleProvider>().fetchMy(),
    );
  }

  Future<void> _pickDate() async {
    final initial = _date ?? DateTime.now();
    final provider = context.read<WorkScheduleProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final iso = DateTime(
        picked.year,
        picked.month,
        picked.day,
      ).toIso8601String();
      if (!mounted) return;
      setState(() => _date = picked);
      provider.fetchMy(
        date: iso.substring(0, 10),
        status: _status,
        shiftType: _shiftType,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkScheduleProvider>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Lịch làm việc của tôi',
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
                context.read<WorkScheduleProvider>().fetchMy(
                  date: _date != null
                      ? DateTime(
                          _date!.year,
                          _date!.month,
                          _date!.day,
                        ).toIso8601String().substring(0, 10)
                      : null,
                  status: _status,
                  shiftType: _shiftType,
                );
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
                setState(() {
                  _date = null;
                  _status = null;
                  _shiftType = null;
                });
                context.read<WorkScheduleProvider>().fetchMy();
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
            _buildModernFilterSection(),
            Expanded(
              child: vm.isLoading
                  ? _buildLoadingWidget()
                  : vm.error != null
                  ? _buildErrorWidget(vm.error!)
                  : vm.items.isEmpty
                  ? _emptyState()
                  : _buildAnimatedScheduleList(vm.items),
            ),
          ],
        ),
      ),
    );
  }

  String _statusVi(String v) {
    switch (v) {
      case 'scheduled':
        return 'Đã xếp lịch';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'absent':
        return 'Vắng mặt';
      default:
        return v;
    }
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Chưa có lịch làm việc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quản lý cần tạo lịch làm việc cho bạn.\n'
              'Bạn cũng có thể thử bỏ lọc rồi tải lại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _date = null;
                  _status = null;
                  _shiftType = null;
                });
                context.read<WorkScheduleProvider>().fetchMy();
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

  Widget _buildModernFilterSection() {
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
              if (_date != null || _status != null || _shiftType != null)
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
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildModernFilterButton(
                  'Ngày',
                  _date != null ? DateFormat('dd/MM').format(_date!) : null,
                  Icons.calendar_today,
                  Colors.blue,
                  _pickDate,
                ),
              ),
              SizedBox(width: 2),
              Expanded(
                flex: 4,
                child: _buildModernFilterDropdown(
                  'Trạng thái',
                  _status,
                  Icons.info_outline,
                  Colors.green,
                  _statusOptions,
                  (value) {
                    setState(() => _status = value);
                    context.read<WorkScheduleProvider>().fetchMy(
                      date: _date != null
                          ? DateTime(
                              _date!.year,
                              _date!.month,
                              _date!.day,
                            ).toIso8601String().substring(0, 10)
                          : null,
                      status: value,
                      shiftType: _shiftType,
                    );
                  },
                ),
              ),
              SizedBox(width: 2),
              Expanded(
                flex: 3,
                child: _buildModernFilterDropdown(
                  'Ca',
                  _shiftType,
                  Icons.schedule,
                  Colors.orange,
                  _shiftTypeOptions,
                  (value) {
                    setState(() => _shiftType = value);
                    context.read<WorkScheduleProvider>().fetchMy(
                      date: _date != null
                          ? DateTime(
                              _date!.year,
                              _date!.month,
                              _date!.day,
                            ).toIso8601String().substring(0, 10)
                          : null,
                      status: _status,
                      shiftType: value,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterButton(
    String label,
    String? value,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 12),
                SizedBox(width: 2),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              value ?? 'Tất cả',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterDropdown(
    String label,
    String? currentValue,
    IconData icon,
    Color color,
    List<Map<String, String>> options,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 12),
              SizedBox(width: 2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
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
              value: currentValue,
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
                  Icon(Icons.arrow_drop_down, color: color, size: 14),
                ],
              ),
              items: options.map((option) {
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
                      if (currentValue == option['value'])
                        Icon(Icons.check, color: color, size: 12),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                onChanged(value);
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
            'Đang tải lịch làm việc...',
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
                context.read<WorkScheduleProvider>().fetchMy();
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

  Widget _buildAnimatedScheduleList(List<WorkScheduleModel> items) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final schedule = items[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0.0, index * 10.0, 0.0),
          child: Opacity(
            opacity: 1.0 - (index * 0.1),
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              child: _buildModernScheduleCard(schedule),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernScheduleCard(WorkScheduleModel schedule) {
    Color shiftColor;
    IconData shiftIcon;
    String shiftName;

    switch (schedule.shiftType) {
      case 'morning':
        shiftColor = Colors.orange[400]!;
        shiftIcon = Icons.wb_sunny;
        shiftName = 'Sáng';
        break;
      case 'afternoon':
        shiftColor = Colors.blue[400]!;
        shiftIcon = Icons.wb_twilight;
        shiftName = 'Chiều';
        break;
      case 'evening':
        shiftColor = Colors.purple[400]!;
        shiftIcon = Icons.nightlight_round;
        shiftName = 'Tối';
        break;
      case 'night':
        shiftColor = Colors.indigo[400]!;
        shiftIcon = Icons.nightlight_round;
        shiftName = 'Đêm';
        break;
      case 'full-day':
        shiftColor = Colors.green[400]!;
        shiftIcon = Icons.today;
        shiftName = 'Cả ngày';
        break;
      default:
        shiftColor = Colors.grey[400]!;
        shiftIcon = Icons.schedule;
        shiftName = 'Không xác định';
    }

    Color statusColor;
    switch (schedule.status) {
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'absent':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            shiftColor.withValues(alpha: 0.1),
            Colors.white,
            shiftColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shiftColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: shiftColor.withValues(alpha: 0.1),
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
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [shiftColor, shiftColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: shiftColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(shiftIcon, color: Colors.white, size: 20),
                      SizedBox(height: 2),
                      Text(
                        shiftName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'EEEE, dd/MM/yyyy',
                            ).format(schedule.date),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: shiftColor, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '${schedule.startTime} - ${schedule.endTime}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (schedule.employeeName != null) ...[
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              schedule.employeeName!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (schedule.notes != null &&
                          schedule.notes!.isNotEmpty) ...[
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.note_outlined,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                schedule.notes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        _statusVi(schedule.status),
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
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> get _statusOptions => [
    {'value': 'scheduled', 'label': 'Đã xếp lịch'},
    {'value': 'completed', 'label': 'Hoàn thành'},
    {'value': 'cancelled', 'label': 'Đã hủy'},
    {'value': 'absent', 'label': 'Vắng mặt'},
  ];

  List<Map<String, String>> get _shiftTypeOptions => [
    {'value': 'morning', 'label': 'Sáng'},
    {'value': 'afternoon', 'label': 'Chiều'},
    {'value': 'evening', 'label': 'Tối'},
  ];
}

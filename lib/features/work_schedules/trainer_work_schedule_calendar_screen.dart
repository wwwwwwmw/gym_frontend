import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'work_schedule_provider.dart';
import 'work_schedule_model.dart';
import 'package:intl/intl.dart';

class TrainerWorkScheduleCalendarScreen extends StatefulWidget {
  const TrainerWorkScheduleCalendarScreen({super.key});

  @override
  State<TrainerWorkScheduleCalendarScreen> createState() =>
      _TrainerWorkScheduleCalendarScreenState();
}

class _TrainerWorkScheduleCalendarScreenState
    extends State<TrainerWorkScheduleCalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late AnimationController _animationController;
  String _selectedFilter = 'all';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start animations
    _animationController.forward();

    // Load initial schedules
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkScheduleProvider>().fetchMy();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showShiftSelectionDialog(DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Chọn ca làm việc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Ngày ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () => _registerShift(selectedDate, 'morning'),
              icon: Icon(Icons.wb_sunny, color: Colors.orange),
              label: Text('Ca Sáng (06:00-12:00)', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _registerShift(selectedDate, 'afternoon'),
              icon: Icon(Icons.wb_twilight, color: Colors.blue),
              label: Text('Ca Chiều (12:00-18:00)', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _registerShift(selectedDate, 'evening'),
              icon: Icon(Icons.nightlight_round, color: Colors.purple),
              label: Text('Ca Tối (18:00-22:00)', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[100],
                foregroundColor: Colors.purple[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding: EdgeInsets.all(16),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmationDialog(WorkScheduleModel schedule) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('Xác nhận xóa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              content: Text(
                'Bạn có chắc chắn muốn xóa ca làm việc ${DateFormat('dd/MM/yyyy').format(schedule.date)} - ${schedule.shiftType.toUpperCase()}?',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deleteSchedule(WorkScheduleModel schedule) async {
    try {
      final provider = context.read<WorkScheduleProvider>();
      await provider.deleteWorkSchedule(schedule.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa ca làm việc thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi xóa ca làm việc'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _registerShift(DateTime date, String shiftType) async {
    Navigator.pop(context); // Đóng dialog

    try {
      final provider = context.read<WorkScheduleProvider>();
      await provider.registerWorkShift(date, shiftType);

      if (!mounted) return;

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký ca $shiftType thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh lại danh sách lịch
      provider.fetchMy();
    } catch (error) {
      if (!mounted) return;

      // Hiển thị thông báo lỗi
      String errorMessage = 'Có lỗi xảy ra khi đăng ký ca';
      if (error.toString().contains('duplicate') ||
          error.toString().contains('trùng')) {
        errorMessage = 'Đã đăng ký ca này rồi';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  List<WorkScheduleModel> _getSchedulesForDay(DateTime day) {
    try {
      final provider = context.read<WorkScheduleProvider>();
      return provider.schedules.where((schedule) {
        final scheduleDate = DateTime(
          schedule.date.year,
          schedule.date.month,
          schedule.date.day,
        );
        return scheduleDate == day;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkScheduleProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Column(
          children: [
            // Custom App Bar
            SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Lịch làm việc của tôi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => provider.fetchMy(),
                        ),
                        IconButton(
                          icon: Icon(Icons.filter_list, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filter Section
            if (_showFilters) _buildFilterSection(),

            // Main Content
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Calendar Section
                    _buildCalendarSection(),

                    // Legend
                    _buildLegend(),

                    // Schedule List
                    Expanded(child: _buildScheduleList(provider)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.filter_alt, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all'),
                  SizedBox(width: 8),
                  _buildFilterChip('Sáng', 'morning'),
                  SizedBox(width: 8),
                  _buildFilterChip('Chiều', 'afternoon'),
                  SizedBox(width: 8),
                  _buildFilterChip('Tối', 'evening'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Color(0xFF667eea) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Calendar Header
          Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF667eea), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chọn ngày để đăng ký',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667eea),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Modern Calendar
          _buildModernCalendar(),
        ],
      ),
    );
  }

  Widget _buildModernCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(Duration(days: 90)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        eventLoader: _getSchedulesForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red[400]),
          holidayTextStyle: TextStyle(color: Colors.red[400]),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF667eea),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF667eea).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          todayDecoration: BoxDecoration(
            color: Color(0xFF667eea).withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green[400],
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(color: Colors.grey[800]),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: Color(0xFF667eea),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: TextStyle(color: Colors.white, fontSize: 12),
          titleTextStyle: TextStyle(
            color: Color(0xFF667eea),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          // Add haptic feedback
          HapticFeedback.selectionClick();

          // Chỉ cho phép đăng ký từ hôm nay trở đi
          if (selectedDay.isAfter(DateTime.now().subtract(Duration(days: 1)))) {
            _showShiftSelectionDialog(selectedDay);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể đăng ký lịch cho ngày đã qua'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Sáng', Colors.orange[400]!),
          _buildLegendItem('Chiều', Colors.blue[400]!),
          _buildLegendItem('Tối', Colors.purple[400]!),
          _buildLegendItem('Đã đăng ký', Colors.green[400]!),
        ],
      ),
    );
  }

  Widget _buildScheduleList(WorkScheduleProvider provider) {
    final filteredSchedules = _getFilteredSchedules(provider.schedules);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF667eea), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lịch đã đăng ký',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667eea),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${filteredSchedules.length} ca',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 12),
          Expanded(
            child: provider.error != null
                ? _buildErrorWidget(provider.error!)
                : provider.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF667eea),
                      ),
                    ),
                  )
                : filteredSchedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredSchedules.length,
                    padding: EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final schedule = filteredSchedules[index];
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              (1 - _animationController.value) * 50,
                            ),
                            child: Opacity(
                              opacity: _animationController.value,
                              child: Dismissible(
                                key: Key(schedule.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await _showDeleteConfirmationDialog(
                                    schedule,
                                  );
                                },
                                onDismissed: (direction) {
                                  _deleteSchedule(schedule);
                                },
                                child: _buildModernScheduleCard(schedule),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<WorkScheduleModel> _getFilteredSchedules(
    List<WorkScheduleModel> schedules,
  ) {
    if (schedules.isEmpty) return [];
    if (_selectedFilter == 'all') return schedules;
    return schedules
        .where((schedule) => schedule.shiftType == _selectedFilter)
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Chưa có lịch làm việc nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy đăng ký ca làm việc để bắt đầu',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
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
              onPressed: () => context.read<WorkScheduleProvider>().fetchMy(),
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

  Widget _buildModernScheduleCard(WorkScheduleModel schedule) {
    Color shiftColor;
    IconData shiftIcon;
    String shiftName;

    switch (schedule.shiftType) {
      case 'morning':
        shiftColor = Colors.orange[400]!;
        shiftIcon = Icons.wb_sunny;
        shiftName = 'Ca Sáng';
        break;
      case 'afternoon':
        shiftColor = Colors.blue[400]!;
        shiftIcon = Icons.wb_twilight;
        shiftName = 'Ca Chiều';
        break;
      case 'evening':
        shiftColor = Colors.purple[400]!;
        shiftIcon = Icons.nightlight_round;
        shiftName = 'Ca Tối';
        break;
      default:
        shiftColor = Colors.grey[400]!;
        shiftIcon = Icons.schedule;
        shiftName = 'Ca Làm';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            shiftColor.withValues(alpha: 0.1),
            shiftColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shiftColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: shiftColor.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [shiftColor, shiftColor.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(shiftIcon, color: Colors.white, size: 24),
        ),
        title: Text(
          '${DateFormat('dd/MM/yyyy').format(schedule.date)} - $shiftName',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '${schedule.startTime} - ${schedule.endTime}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(schedule.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(schedule.status).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            _getStatusText(schedule.status),
            style: TextStyle(
              color: _getStatusColor(schedule.status),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Đã lên lịch';
      case 'completed':
        return 'Đã hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'absent':
        return 'Vắng mặt';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'absent':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

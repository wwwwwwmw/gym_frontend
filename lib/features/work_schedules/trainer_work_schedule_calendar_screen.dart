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

  

  List<WorkScheduleModel> _getSchedulesForDay(DateTime day) {
    try {
      final provider = context.read<WorkScheduleProvider>();
      // Normalize the input day to local date (year, month, day only)
      final normalizedDay = DateTime(day.year, day.month, day.day);
      
      return provider.schedules.where((schedule) {
        // Normalize schedule date to local date (year, month, day only)
        final scheduleDate = DateTime(
          schedule.date.year,
          schedule.date.month,
          schedule.date.day,
        );
        // Compare normalized dates
        return scheduleDate.year == normalizedDay.year &&
               scheduleDate.month == normalizedDay.month &&
               scheduleDate.day == normalizedDay.day;
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
                          icon: Icon(Icons.people, color: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/trainer/my-students'),
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
                  _buildFilterChip('Trưa', 'afternoon'),
                  SizedBox(width: 8),
                  _buildFilterChip('Chiều', 'evening'),
                  SizedBox(width: 8),
                  _buildFilterChip('Đêm', 'night'),
                  SizedBox(width: 8),
                  _buildFilterChip('Cả ngày', 'full-day'),
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
                  'Lịch làm việc theo ngày',
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
      child:       TableCalendar(
        firstDay: DateTime.now().subtract(Duration(days: 30)),
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
          HapticFeedback.selectionClick();
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          // Note: Không tự động fetch khi chuyển trang để tránh spam API
          // User có thể dùng nút refresh nếu cần
        },
      ),
    );
  }

  Widget _buildScheduleList(WorkScheduleProvider provider) {
    final filteredSchedules = _getFilteredSchedules(provider.schedules);
    
    // Sort schedules by date ascending (oldest to newest)
    final sortedSchedules = List<WorkScheduleModel>.from(filteredSchedules);
    sortedSchedules.sort((a, b) {
      // Compare dates: earlier dates first
      final dateA = DateTime(a.date.year, a.date.month, a.date.day);
      final dateB = DateTime(b.date.year, b.date.month, b.date.day);
      final dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;
      // If same date, sort by startTime
      return a.startTime.compareTo(b.startTime);
    });

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
                '${sortedSchedules.length} ca',
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
                : sortedSchedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: sortedSchedules.length,
                    padding: EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final schedule = sortedSchedules[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: _buildModernScheduleCard(schedule),
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
        .where((schedule) => schedule.shiftType.toLowerCase() == _selectedFilter.toLowerCase())
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
            'Bạn chưa có lịch trong khoảng này',
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

    switch (schedule.shiftType.toLowerCase()) {
      case 'morning':
        shiftColor = Colors.orange[400]!;
        shiftIcon = Icons.wb_sunny;
        shiftName = 'Ca Sáng';
        break;
      case 'afternoon':
        shiftColor = Colors.blue[400]!;
        shiftIcon = Icons.wb_twilight;
        shiftName = 'Ca Trưa';
        break;
      case 'evening':
        shiftColor = Colors.purple[400]!;
        shiftIcon = Icons.nightlight_round;
        shiftName = 'Ca Chiều';
        break;
      case 'night':
        shiftColor = Colors.indigo[400]!;
        shiftIcon = Icons.nightlight_round;
        shiftName = 'Ca Đêm';
        break;
      case 'full-day':
        shiftColor = Colors.green[400]!;
        shiftIcon = Icons.today;
        shiftName = 'Ca Cả Ngày';
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
          '${DateFormat('dd/MM/yyyy', 'vi_VN').format(schedule.date)} - $shiftName',
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
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
    switch (status.toLowerCase()) {
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

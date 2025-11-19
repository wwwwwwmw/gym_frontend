import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/api_client.dart';
import '../../core/env.dart'; // <--- THÊM IMPORT NÀY

class MemberScheduleScreen extends StatefulWidget {
  const MemberScheduleScreen({super.key});

  @override
  State<MemberScheduleScreen> createState() => _MemberScheduleScreenState();
}

class _MemberScheduleScreenState extends State<MemberScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isLoading = true;
  String? _error;

  // Dữ liệu gói tập từ API
  Map<String, dynamic>? _scheduleData;
  List<int> _targetWeekDays = []; // Ví dụ: [1, 3, 5] (Thứ 2, 4, 6)
  DateTime? _pkgStartDate;
  DateTime? _pkgEndDate;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchMySchedule();
  }

  Future<void> _fetchMySchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ApiClient();
      final response = await client.getJson('/api/members/my-schedule');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final schedule = data['schedule'];

        setState(() {
          _scheduleData = data;

          // Parse ngày bắt đầu/kết thúc
          if (data['startDate'] != null) {
            _pkgStartDate = DateTime.parse(data['startDate']);
          }
          if (data['endDate'] != null) {
            _pkgEndDate = DateTime.parse(data['endDate']);
          }

          // Parse thứ trong tuần (Backend trả về 1..7, TableCalendar cũng dùng 1..7)
          if (schedule != null && schedule['daysOfWeek'] != null) {
            _targetWeekDays = List<int>.from(schedule['daysOfWeek']);
          } else {
            _targetWeekDays = [];
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _scheduleData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy lịch tập (có thể do chưa đăng ký): $e");

      setState(() {
        _scheduleData = null;
        _error = null;
        _isLoading = false;
      });
    }
  }

  // Logic kiểm tra xem 1 ngày cụ thể có phải ngày tập không
  bool _isWorkoutDay(DateTime day) {
    if (_pkgStartDate == null || _pkgEndDate == null) return false;
    if (_targetWeekDays.isEmpty) return false;

    // 1. So sánh ngày (bỏ qua giờ phút) để xem có nằm trong hạn gói tập không
    final dateToCheck = DateTime(day.year, day.month, day.day);
    final start = DateTime(
      _pkgStartDate!.year,
      _pkgStartDate!.month,
      _pkgStartDate!.day,
    );
    final end = DateTime(
      _pkgEndDate!.year,
      _pkgEndDate!.month,
      _pkgEndDate!.day,
    );

    if (dateToCheck.isBefore(start) || dateToCheck.isAfter(end)) {
      return false;
    }

    // 2. Kiểm tra thứ (weekday: 1=Mon, 7=Sun)
    return _targetWeekDays.contains(day.weekday);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Tập Của Tôi'), centerTitle: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: _fetchMySchedule,
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    if (_scheduleData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              "Bạn chưa đăng ký gói tập nào\nhoặc gói tập đã hết hạn.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Đăng ký gói tập mới"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTableCalendar(),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: _buildSelectedDayDetails(),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
      locale: 'vi_VN',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,

      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),

      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),

      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },

      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
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

      eventLoader: (day) {
        if (_isWorkoutDay(day)) {
          return ['Workout'];
        }
        return [];
      },
    );
  }

  Widget _buildSelectedDayDetails() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final isWorkout = _isWorkoutDay(_selectedDay!);
    final dateStr = DateFormat(
      'EEEE, dd/MM/yyyy',
      'vi_VN',
    ).format(_selectedDay!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          dateStr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        if (isWorkout) _buildWorkoutCard() else _buildRestDayWidget(),
      ],
    );
  }

  Widget _buildWorkoutCard() {
    final pkgName = _scheduleData?['packageName'] ?? 'Gói tập';
    final schedule = _scheduleData?['schedule'] ?? {};
    final startTime = schedule['startTime'] ?? '--:--';
    final endTime = schedule['endTime'] ?? '--:--';

    // --- PHẦN THÊM MỚI: Xử lý hiển thị Ảnh ---
    final relativeImageUrl = _scheduleData?['imageUrl'] as String?;
    final imageUrl = relativeImageUrl != null && relativeImageUrl.isNotEmpty
        ? apiBaseUrl() +
              relativeImageUrl // Ghép Base URL + relative path
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Thay thế icon bằng ảnh
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.blue.shade50,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.blue,
                              size: 30,
                            ),
                      )
                    : const Icon(
                        Icons.fitness_center,
                        color: Colors.blue,
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkgName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$startTime - $endTime",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayWidget() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.nightlight_round,
            size: 60,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            "Không có lịch tập",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hôm nay là ngày nghỉ ngơi của bạn.\nHãy thư giãn để cơ bắp phục hồi nhé!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

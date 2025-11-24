import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/api_client.dart';
import '../../core/env.dart';
import '../registrations/registration_service.dart';
import '../registrations/registration_model.dart';

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
  final _registrationService = RegistrationService(ApiClient());

  // Danh sách các ngày tập (đã tính toán sẵn) - dùng String key để so sánh chính xác
  final Set<String> _workoutDays = {};

  // Mapping ngày -> index của gói (để phân biệt màu)
  final Map<String, int> _dayToPackageIndex = {};

  // Thông tin gói tập - giữ lại cho hiển thị chi tiết
  DateTime? _pkgStartDate;
  DateTime? _pkgEndDate;
  List<int> _targetWeekDays =
      []; // [1, 3, 5] = Thứ 2, 4, 6 - tổng hợp từ tất cả gói
  int? _remainingSessions;
  final Map<DateTime, int> _requiredWorkoutOrder = {};

  // Danh sách tất cả các gói active
  List<RegistrationModel> _activeRegistrations = [];

  // Danh sách màu cho các gói (mỗi gói một màu) - dùng MaterialColor để có shade
  static final List<MaterialColor> _packageColors = [
    Colors.green, // Gói 1: xanh lá
    Colors.blue, // Gói 2: xanh dương
    Colors.orange, // Gói 3: cam
    Colors.purple, // Gói 4: tím
    Colors.teal, // Gói 5: xanh ngọc
    Colors.pink, // Gói 6: hồng
    Colors.amber, // Gói 7: vàng
    Colors.indigo, // Gói 8: chàm
  ];

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  String _getDayName(int weekday) {
    switch (weekday) {
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
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchMySchedule();
  }

  // Tính toán tất cả các ngày tập từ TẤT CẢ các gói active
  void _calculateWorkoutDays() {
    _workoutDays.clear();
    _dayToPackageIndex.clear();

    // Thu thập tất cả các ngày trong tuần từ tất cả các gói active
    final allWeekDays = <int>{};
    DateTime? earliestStart;
    DateTime? latestEnd;

    // Nếu có active registrations, tính toán từ chúng
    if (_activeRegistrations.isNotEmpty) {
      debugPrint(
        '🔄 Calculating workout days from ${_activeRegistrations.length} active package(s)...',
      );

      for (final reg in _activeRegistrations) {
        final pkg = reg.package;
        if (pkg == null) continue;

        // Lấy daysOfWeek từ package schedule
        if (pkg.hasFixedSchedule == true && pkg.schedule != null) {
          final scheduleDays = pkg.schedule!['daysOfWeek'] as List?;
          if (scheduleDays != null && scheduleDays.isNotEmpty) {
            for (var d in scheduleDays) {
              int? dayNum;
              if (d is int) {
                dayNum = d;
              } else if (d is String) {
                dayNum = int.tryParse(d);
              } else if (d is num) {
                dayNum = d.toInt();
              }
              if (dayNum != null && dayNum >= 1 && dayNum <= 7) {
                allWeekDays.add(dayNum);
                debugPrint('  ✅ Added day $dayNum from package: ${pkg.name}');
              }
            }
          }
        }

        // Cập nhật khoảng thời gian
        final startDate = _normalize(reg.startDate);
        final endDate = _normalize(reg.endDate);

        if (earliestStart == null || startDate.isBefore(earliestStart)) {
          earliestStart = startDate;
        }
        if (latestEnd == null || endDate.isAfter(latestEnd)) {
          latestEnd = endDate;
        }
      }
    }

    // Fallback: Nếu không có active registrations hoặc không có daysOfWeek, dùng dữ liệu từ API
    if (allWeekDays.isEmpty && _targetWeekDays.isNotEmpty) {
      allWeekDays.addAll(_targetWeekDays);
      debugPrint('  📋 Using daysOfWeek from API response: $_targetWeekDays');
    }

    // Nếu vẫn không có khoảng thời gian, dùng từ API
    if (earliestStart == null || latestEnd == null) {
      if (_pkgStartDate != null && _pkgEndDate != null) {
        earliestStart = _pkgStartDate;
        latestEnd = _pkgEndDate;
        debugPrint(
          '  📅 Using date range from API: $_pkgStartDate to $_pkgEndDate',
        );
      } else {
        debugPrint('⚠️ Cannot calculate workout days: no valid date range');
        return;
      }
    }

    _targetWeekDays = allWeekDays.toList()..sort();
    _pkgStartDate = earliestStart;
    _pkgEndDate = latestEnd;

    debugPrint('  📅 Date range: $_pkgStartDate to $_pkgEndDate');
    debugPrint('  📋 Combined days of week: $_targetWeekDays');

    if (_targetWeekDays.isEmpty) {
      debugPrint('⚠️ No target week days to calculate');
      return;
    }

    // Tính toán ngày tập cho TỪNG GÓI trong khoảng thời gian của nó
    if (_activeRegistrations.isNotEmpty) {
      for (
        int packageIndex = 0;
        packageIndex < _activeRegistrations.length;
        packageIndex++
      ) {
        final reg = _activeRegistrations[packageIndex];
        final pkg = reg.package;
        if (pkg == null) continue;

        // Lấy daysOfWeek của gói này
        List<int> packageDays = [];
        if (pkg.hasFixedSchedule == true && pkg.schedule != null) {
          final scheduleDays = pkg.schedule!['daysOfWeek'] as List?;
          if (scheduleDays != null && scheduleDays.isNotEmpty) {
            for (var d in scheduleDays) {
              int? dayNum;
              if (d is int) {
                dayNum = d;
              } else if (d is String) {
                dayNum = int.tryParse(d);
              } else if (d is num) {
                dayNum = d.toInt();
              }
              if (dayNum != null && dayNum >= 1 && dayNum <= 7) {
                packageDays.add(dayNum);
              }
            }
          }
        }

        if (packageDays.isEmpty) continue;

        // Tính toán ngày tập trong khoảng thời gian của gói này
        final startDate = _normalize(reg.startDate);
        final endDate = _normalize(reg.endDate);
        var currentDate = startDate;
        int count = 0;

        while (currentDate.isBefore(endDate) ||
            currentDate.isAtSameMomentAs(endDate)) {
          if (packageDays.contains(currentDate.weekday)) {
            final normalized = _normalize(currentDate);
            final key =
                '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
            _workoutDays.add(key);
            // Lưu mapping ngày -> index gói
            // Chỉ lưu nếu ngày chưa có gói nào (mỗi ngày chỉ thuộc 1 gói)
            // Nếu ngày trùng lịch giữa các gói, ưu tiên gói đầu tiên (packageIndex nhỏ hơn)
            if (!_dayToPackageIndex.containsKey(key)) {
              _dayToPackageIndex[key] = packageIndex;
              debugPrint(
                '  📌 Mapped day $key -> Package $packageIndex (${pkg.name})',
              );
            } else {
              // Nếu ngày đã có gói, giữ nguyên gói đầu tiên
              debugPrint(
                '  ⚠️ Day $key already mapped to Package ${_dayToPackageIndex[key]}, skipping Package $packageIndex',
              );
            }
            count++;
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }

        debugPrint(
          '  ✅ Package "${pkg.name}": Added $count workout days (${packageDays.join(", ")})',
        );
      }
    } else {
      // Fallback: Tính toán từ _targetWeekDays và _pkgStartDate/_pkgEndDate
      if (_pkgStartDate != null &&
          _pkgEndDate != null &&
          _targetWeekDays.isNotEmpty) {
        var currentDate = _normalize(_pkgStartDate!);
        final endDate = _normalize(_pkgEndDate!);
        int count = 0;

        while (currentDate.isBefore(endDate) ||
            currentDate.isAtSameMomentAs(endDate)) {
          if (_targetWeekDays.contains(currentDate.weekday)) {
            final normalized = _normalize(currentDate);
            final key =
                '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
            _workoutDays.add(key);
            count++;
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
        debugPrint('  ✅ Calculated $count workout days from API data');
      }
    }

    debugPrint('✅ Total unique workout days: ${_workoutDays.length}');
    debugPrint('✅ Total day-to-package mappings: ${_dayToPackageIndex.length}');
    // Debug: In ra một số mapping mẫu
    if (_dayToPackageIndex.isNotEmpty) {
      debugPrint('📋 Sample day-to-package mappings (first 10):');
      final sortedEntries = _dayToPackageIndex.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (var i = 0; i < sortedEntries.length && i < 10; i++) {
        final entry = sortedEntries[i];
        final pkgName = entry.value < _activeRegistrations.length
            ? _activeRegistrations[entry.value].package.name
            : 'Unknown';
        debugPrint('  - ${entry.key} -> Package ${entry.value} ($pkgName)');
      }
    }
  }

  // Kiểm tra xem một ngày có phải ngày tập không
  bool _isWorkoutDay(DateTime day) {
    final normalized = _normalize(day);
    final key =
        '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';

    // Debug cho một số ngày cụ thể
    if (day.month == 11 &&
        day.year == 2025 &&
        (day.day == 24 || day.day == 25 || day.day == 26 || day.day == 27)) {
      debugPrint('🔍 Checking ${day.day}/11/2025:');
      debugPrint('  key: $key');
      debugPrint('  weekday: ${day.weekday}');
      debugPrint('  _workoutDays size: ${_workoutDays.length}');
      debugPrint('  contains: ${_workoutDays.contains(key)}');
      if (_workoutDays.isNotEmpty) {
        debugPrint('  sample keys: ${_workoutDays.take(5).join(", ")}');
      }
    }

    return _workoutDays.contains(key);
  }

  // Lấy màu của gói dựa trên ngày
  MaterialColor _getPackageColorForDay(DateTime day) {
    final normalized = _normalize(day);
    final key =
        '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';

    final packageIndex = _dayToPackageIndex[key];
    if (packageIndex != null && packageIndex < _packageColors.length) {
      return _packageColors[packageIndex];
    }

    // Fallback: màu xanh lá mặc định
    return Colors.green;
  }

  Future<void> _fetchMySchedule() async {
    debugPrint('🚀 _fetchMySchedule CALLED');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ApiClient();

      // Lấy tất cả các gói active trước
      debugPrint('🌐 Fetching all active packages...');
      try {
        final activeRegs = await _registrationService.getSelfActive();
        if (mounted) {
          setState(() {
            _activeRegistrations = activeRegs;
          });
          debugPrint('✅ Found ${activeRegs.length} active package(s)');
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching active packages: $e');
        // Continue với API cũ
      }

      debugPrint('🌐 Calling API: /api/members/my-schedule');
      final response = await client.getJson('/api/members/my-schedule');

      debugPrint('=== FULL API RESPONSE ===');
      debugPrint('Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final schedule = data['schedule'];

        debugPrint('📦 Package Name: ${data['packageName']}');
        debugPrint('📅 Start Date (raw): ${data['startDate']}');
        debugPrint('📅 End Date (raw): ${data['endDate']}');
        debugPrint('🗓️ Schedule object: $schedule');
        debugPrint('🗓️ Days of Week (raw): ${schedule?['daysOfWeek']}');

        setState(() {
          _scheduleData = data;

          // Parse ngày bắt đầu/kết thúc
          if (data['startDate'] != null) {
            try {
              final startDateStr = data['startDate'].toString();
              _pkgStartDate = DateTime.parse(startDateStr).toLocal();
              _pkgStartDate = DateTime(
                _pkgStartDate!.year,
                _pkgStartDate!.month,
                _pkgStartDate!.day,
              );
              debugPrint('✅ Parsed startDate: $_pkgStartDate');
            } catch (e) {
              debugPrint('❌ Error parsing startDate: $e');
              _pkgStartDate = null;
            }
          }

          if (data['endDate'] != null) {
            try {
              final endDateStr = data['endDate'].toString();
              _pkgEndDate = DateTime.parse(endDateStr).toLocal();
              _pkgEndDate = DateTime(
                _pkgEndDate!.year,
                _pkgEndDate!.month,
                _pkgEndDate!.day,
              );
              debugPrint('✅ Parsed endDate: $_pkgEndDate');
            } catch (e) {
              debugPrint('❌ Error parsing endDate: $e');
              _pkgEndDate = null;
            }
          }

          // Parse thứ trong tuần - FIX: Kiểm tra kỹ hơn
          _targetWeekDays = [];

          debugPrint('🔍 Parsing daysOfWeek:');
          debugPrint('  schedule is null: ${schedule == null}');
          debugPrint('  schedule type: ${schedule?.runtimeType}');
          debugPrint('  schedule: $schedule');

          if (schedule != null) {
            // Try multiple ways to access daysOfWeek
            dynamic rawDays;

            // Method 1: Direct access as Map
            if (schedule is Map<String, dynamic>) {
              rawDays = schedule['daysOfWeek'];
              debugPrint('  ✅ Found daysOfWeek via Map<String, dynamic>');
            }
            // Method 2: Try as generic Map
            else if (schedule is Map) {
              rawDays = schedule['daysOfWeek'];
              debugPrint('  ✅ Found daysOfWeek via Map');
            }
            // Method 3: Try dynamic access
            else {
              try {
                // Convert to Map if possible
                final scheduleMap = schedule as Map<String, dynamic>?;
                if (scheduleMap != null) {
                  rawDays = scheduleMap['daysOfWeek'];
                  debugPrint('  ✅ Found daysOfWeek via cast to Map');
                } else {
                  debugPrint('  ❌ Could not cast schedule to Map');
                }
              } catch (e) {
                debugPrint('  ❌ Error accessing daysOfWeek: $e');
              }
            }

            debugPrint('  rawDays: $rawDays');
            debugPrint('  rawDays is null: ${rawDays == null}');
            if (rawDays != null) {
              debugPrint('  rawDays type: ${rawDays.runtimeType}');
              debugPrint('  rawDays is List: ${rawDays is List}');

              if (rawDays is List) {
                debugPrint('  Processing List with ${rawDays.length} items');
                for (var i = 0; i < rawDays.length; i++) {
                  final d = rawDays[i];
                  debugPrint('    Item $i: $d (type: ${d.runtimeType})');

                  int? dayNum;
                  if (d is int) {
                    dayNum = d;
                  } else if (d is String) {
                    dayNum = int.tryParse(d);
                  } else if (d is num) {
                    dayNum = d.toInt();
                  }

                  if (dayNum != null && dayNum >= 1 && dayNum <= 7) {
                    _targetWeekDays.add(dayNum);
                    debugPrint('      ✅ Added: $dayNum');
                  } else {
                    debugPrint('      ❌ Skipped: $dayNum (invalid)');
                  }
                }
                _targetWeekDays.sort();
                debugPrint('✅ Parsed _targetWeekDays: $_targetWeekDays');
              } else {
                debugPrint(
                  '⚠️ daysOfWeek is not a List! Type: ${rawDays.runtimeType}',
                );
              }
            } else {
              debugPrint('⚠️ rawDays is null!');
            }
          } else {
            _targetWeekDays = [];
            debugPrint('⚠️ WARNING: schedule is null!');
          }

          if (_targetWeekDays.isEmpty) {
            debugPrint(
              '❌ CRITICAL: _targetWeekDays is still empty after parsing!',
            );
            debugPrint('  Full data object: $data');
            debugPrint('  Full schedule: $schedule');
          }

          _remainingSessions = data['remainingSessions'] is int
              ? data['remainingSessions'] as int
              : null;

          // Parse nextWorkoutDates
          _requiredWorkoutOrder.clear();
          final nextDates =
              (data['nextWorkoutDates'] as List?)
                  ?.whereType<String>()
                  .map((s) => DateTime.parse(s).toLocal())
                  .toList() ??
              [];

          for (var i = 0; i < nextDates.length; i++) {
            _requiredWorkoutOrder[_normalize(nextDates[i])] = i + 1;
          }

          // TÍNH TOÁN CÁC NGÀY TẬP từ tất cả gói active
          // Merge daysOfWeek từ tất cả các gói active
          final allDays = <int>{};

          // Thêm daysOfWeek từ API response (gói mới nhất)
          allDays.addAll(_targetWeekDays);

          // Thêm daysOfWeek từ tất cả các gói active khác
          for (final reg in _activeRegistrations) {
            final pkg = reg.package;
            if (pkg == null ||
                pkg.hasFixedSchedule != true ||
                pkg.schedule == null)
              continue;
            final scheduleDays = pkg.schedule!['daysOfWeek'] as List?;
            if (scheduleDays != null) {
              for (var d in scheduleDays) {
                int? dayNum;
                if (d is int) {
                  dayNum = d;
                } else if (d is String) {
                  dayNum = int.tryParse(d);
                } else if (d is num) {
                  dayNum = d.toInt();
                }
                if (dayNum != null && dayNum >= 1 && dayNum <= 7) {
                  allDays.add(dayNum);
                  debugPrint('  ✅ Added day $dayNum from package: ${pkg.name}');
                }
              }
            }
          }

          _targetWeekDays = allDays.toList()..sort();
          debugPrint('✅ Merged daysOfWeek from all packages: $_targetWeekDays');

          _calculateWorkoutDays();

          // Debug: In ra một số ngày tập mẫu
          if (_workoutDays.isNotEmpty) {
            debugPrint('📋 Sample workout days (first 10):');
            final sortedKeys = _workoutDays.toList()..sort();
            for (var i = 0; i < sortedKeys.length && i < 10; i++) {
              debugPrint('  - ${sortedKeys[i]}');
            }
          }

          _isLoading = false;
        });

        // Force rebuild sau khi tính toán xong
        if (mounted) {
          setState(() {});
        }
      } else {
        debugPrint('⚠️ No schedule data returned');
        setState(() {
          _scheduleData = null;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("❌ LỖI LẤY LỊCH TẬP: $e");
      debugPrint("❌ STACK TRACE: $stackTrace");

      setState(() {
        _scheduleData = null;
        _error = e.toString();
        _isLoading = false;
      });
    }
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
              const SizedBox(height: 20),
              ElevatedButton(
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
        // Phần lịch - tăng không gian để không bị che
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(child: _buildTableCalendar()),
              ),
              // Info banner - Thu gọn lại (chỉ hiển thị thông tin lịch tập)
              if (_targetWeekDays.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade50, Colors.orange.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade100,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lịch tập: ${_targetWeekDays.map((d) => _getDayName(d)).join(", ")} | ${_workoutDays.length} ngày',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        // Phần chi tiết ngày được chọn - giảm xuống để không che phần trên
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Legend cho các gói - đặt ở đây để không che calendar
                if (_activeRegistrations.length > 1)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        for (
                          int i = 0;
                          i < _activeRegistrations.length &&
                              i < _packageColors.length;
                          i++
                        )
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _packageColors[i].shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _packageColors[i].shade800,
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _activeRegistrations[i].package.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                // Chi tiết ngày được chọn
                Expanded(child: _buildSelectedDayDetails()),
              ],
            ),
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

      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
        leftChevronIcon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_left, size: 18),
        ),
        rightChevronIcon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_right, size: 18),
        ),
        formatButtonShowsNext: false,
        leftChevronMargin: const EdgeInsets.only(left: 8),
        rightChevronMargin: const EdgeInsets.only(right: 8),
        headerPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      ),

      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, focusedDay) {
          final isSelected = isSameDay(date, _selectedDay);
          final isToday = isSameDay(date, DateTime.now());
          final isWorkout = _isWorkoutDay(date);

          // Lấy màu của gói cho ngày này
          final packageColor = isWorkout
              ? _getPackageColorForDay(date)
              : Colors.green;

          // Quyết định màu nền
          Color baseColor;
          Color textColor;

          if (isSelected && isWorkout) {
            baseColor = packageColor.shade600;
            textColor = Colors.white;
          } else if (isSelected) {
            baseColor = Colors.blue;
            textColor = Colors.white;
          } else if (isWorkout) {
            // Ngày tập theo lịch -> màu của gói tương ứng
            baseColor = packageColor.shade100;
            textColor = packageColor.shade900;
          } else if (isToday) {
            baseColor = Colors.orange.withOpacity(0.15);
            textColor = Colors.black87;
          } else {
            baseColor = Colors.transparent;
            textColor = Colors.black87;
          }

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                  border: isWorkout && !isSelected
                      ? Border.all(color: packageColor.shade400, width: 2.5)
                      : null,
                  boxShadow: isWorkout && !isSelected
                      ? [
                          BoxShadow(
                            color: packageColor.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected || isWorkout
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: isWorkout ? 15 : 14,
                  ),
                ),
              ),
              if (isWorkout)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: packageColor.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        todayBuilder: (context, date, focusedDay) {
          final isWorkout = _isWorkoutDay(date);
          final packageColor = isWorkout
              ? _getPackageColorForDay(date)
              : Colors.green;

          Color baseColor;
          if (isWorkout) {
            baseColor = packageColor.withOpacity(0.3);
          } else {
            baseColor = Colors.orange.withOpacity(0.15);
          }

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                  border: isWorkout
                      ? Border.all(color: packageColor.shade500, width: 2.5)
                      : Border.all(color: Colors.orange, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: isWorkout ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
              if (isWorkout)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: packageColor.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
        selectedBuilder: (context, date, focusedDay) {
          final isWorkout = _isWorkoutDay(date);
          final packageColor = isWorkout
              ? _getPackageColorForDay(date)
              : Colors.green;

          final bgColor = isWorkout ? packageColor.shade600 : Colors.blue;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isWorkout)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          // Dùng màu trắng khi selected để nổi bật trên nền đậm
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
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
    );
  }

  Widget _buildSelectedDayDetails() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final isWorkout = _isWorkoutDay(_selectedDay!);
    final dateStr = DateFormat(
      'EEEE, dd/MM/yyyy',
      'vi_VN',
    ).format(_selectedDay!);

    // Lấy màu của gói cho ngày được chọn
    MaterialColor packageColor = Colors.green;
    if (isWorkout && _selectedDay != null) {
      packageColor = _getPackageColorForDay(_selectedDay!);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header với ngày được chọn
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.indigo.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWorkout ? Icons.fitness_center : Icons.nightlight_round,
                  color: isWorkout
                      ? (packageColor.shade700)
                      : Colors.blueGrey.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWorkout ? 'Ngày tập của bạn' : 'Ngày nghỉ ngơi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isWorkout)
          _buildWorkoutCard(packageColor)
        else
          _buildRestDayWidget(),
        if (_pkgStartDate != null && _pkgEndDate != null) ...[
          const SizedBox(height: 16),
          _buildPackageDurationCard(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildWorkoutCard(MaterialColor packageColor) {
    // Lấy gói tập tương ứng với ngày được chọn
    RegistrationModel? selectedPackage;

    if (_selectedDay != null && _activeRegistrations.isNotEmpty) {
      final normalized = _normalize(_selectedDay!);
      final key =
          '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';

      final packageIndex = _dayToPackageIndex[key];
      if (packageIndex != null &&
          packageIndex < _activeRegistrations.length &&
          packageIndex < _packageColors.length) {
        selectedPackage = _activeRegistrations[packageIndex];
        packageColor = _packageColors[packageIndex];
      }
    }

    // Fallback: dùng dữ liệu từ API nếu không tìm thấy gói
    final pkg = selectedPackage?.package;
    final pkgName = pkg?.name ?? _scheduleData?['packageName'] ?? 'Gói tập';

    // Lấy schedule từ gói được chọn
    Map<String, dynamic> schedule = {};
    if (pkg != null && pkg.hasFixedSchedule == true && pkg.schedule != null) {
      schedule = pkg.schedule!;
    } else {
      schedule = _scheduleData?['schedule'] ?? {};
    }

    final startTime = schedule['startTime'] ?? '--:--';
    final endTime = schedule['endTime'] ?? '--:--';
    final daysOfWeek = schedule['daysOfWeek'] as List?;

    String getDayName(int day) {
      switch (day) {
        case 1:
          return 'T2';
        case 2:
          return 'T3';
        case 3:
          return 'T4';
        case 4:
          return 'T5';
        case 5:
          return 'T6';
        case 6:
          return 'T7';
        case 7:
          return 'CN';
        default:
          return '';
      }
    }

    final daysText = daysOfWeek != null && daysOfWeek.isNotEmpty
        ? daysOfWeek.map((d) => getDayName(d as int)).join(', ')
        : 'Chưa xác định';

    // Lấy image URL từ gói được chọn
    String? relativeImageUrl;
    if (pkg != null && pkg.imageUrl != null && pkg.imageUrl!.isNotEmpty) {
      relativeImageUrl = pkg.imageUrl;
    } else {
      relativeImageUrl = _scheduleData?['imageUrl'] as String?;
    }
    final imageUrl = relativeImageUrl != null && relativeImageUrl.isNotEmpty
        ? apiBaseUrl() + relativeImageUrl
        : null;

    // Lấy trainer từ registration được chọn
    String? trainerName;
    if (selectedPackage != null && selectedPackage.trainer != null) {
      trainerName = selectedPackage.trainer!.fullName;
    } else {
      final trainer = _scheduleData?['trainer'] as Map<String, dynamic>?;
      trainerName = trainer?['fullName'] as String?;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [packageColor.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: packageColor.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: packageColor.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: packageColor.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: packageColor.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: packageColor.shade100,
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: packageColor,
                                    size: 40,
                                  ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    packageColor.shade200,
                                    packageColor.shade100,
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                color: packageColor,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              packageColor.shade600,
                              packageColor.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: packageColor.shade200,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'NGÀY TẬP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pkgName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    packageColor.shade200,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildInfoRow(
              Icons.calendar_today,
              'Lịch tập',
              daysText,
              Colors.blue,
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              Icons.access_time_filled,
              'Khung giờ',
              '$startTime - $endTime',
              Colors.green,
            ),
            if (trainerName != null && trainerName.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildInfoRow(
                Icons.person,
                'Huấn luyện viên',
                trainerName,
                Colors.purple,
              ),
            ],
            if (_remainingSessions != null) ...[
              const SizedBox(height: 14),
              _buildInfoRow(
                Icons.confirmation_number,
                'Buổi còn lại',
                '$_remainingSessions buổi',
                Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayWidget() {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.shade50,
            Colors.white,
            Colors.blueGrey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.blueGrey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade100, Colors.blueGrey.shade50],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.nightlight_round,
              size: 64,
              color: Colors.blueGrey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Ngày nghỉ ngơi",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Hôm nay là ngày nghỉ ngơi của bạn.\nHãy thư giãn để cơ bắp phục hồi nhé!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDurationCard() {
    final startStr = DateFormat('dd/MM/yyyy').format(_pkgStartDate!);
    final endStr = DateFormat('dd/MM/yyyy').format(_pkgEndDate!);
    final now = DateTime.now();
    final isExpired = _pkgEndDate!.isBefore(now);
    final daysRemaining = _pkgEndDate!.difference(now).inDays;

    final statusColor = isExpired
        ? Colors.red
        : daysRemaining <= 7
        ? Colors.orange
        : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [statusColor.shade50, Colors.white, statusColor.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: statusColor.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.shade100,
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.shade200, statusColor.shade100],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: statusColor.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Thời hạn gói tập',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: statusColor.shade800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, size: 18, color: statusColor.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$startStr - $endStr',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: statusColor.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isExpired && daysRemaining >= 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.shade400, statusColor.shade300],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    daysRemaining == 0
                        ? 'Còn lại: Hôm nay'
                        : daysRemaining == 1
                        ? 'Còn lại: 1 ngày'
                        : 'Còn lại: $daysRemaining ngày',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

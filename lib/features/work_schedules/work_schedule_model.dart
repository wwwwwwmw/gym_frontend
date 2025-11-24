class WorkScheduleModel {
  final String id;
  final String employeeId;
  final DateTime date;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String shiftType; // morning|afternoon|evening|night|full-day
  final String status; // scheduled|completed|cancelled|absent
  final String? notes;
  final String? employeeName;

  WorkScheduleModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shiftType,
    required this.status,
    required this.notes,
    required this.employeeName,
  });

  factory WorkScheduleModel.fromMap(Map<String, dynamic> m) {
    // Handle employeeId: can be string, ObjectId, or populated object
    String employeeIdValue;
    String? employeeNameValue;
    
    if (m['employeeId'] == null) {
      // Fallback to 'employee' field for legacy support
      if (m['employee'] != null) {
        if (m['employee'] is String) {
          employeeIdValue = m['employee'] as String;
        } else if (m['employee'] is Map<String, dynamic>) {
          employeeIdValue = m['employee']['_id']?.toString() ?? '';
          employeeNameValue = m['employee']['fullName'] as String?;
        } else {
          employeeIdValue = m['employee'].toString();
        }
      } else {
        employeeIdValue = '';
      }
    } else if (m['employeeId'] is String) {
      employeeIdValue = m['employeeId'] as String;
    } else if (m['employeeId'] is Map<String, dynamic>) {
      employeeIdValue = m['employeeId']['_id']?.toString() ?? 
                       m['employeeId']['id']?.toString() ?? '';
      employeeNameValue = m['employeeId']['fullName'] as String?;
    } else {
      // Handle ObjectId or other types
      employeeIdValue = m['employeeId'].toString();
    }

    // Handle date: can be string or DateTime
    // IMPORTANT: Normalize to local date (year, month, day only) to avoid timezone issues
    DateTime dateValue;
    if (m['date'] is String) {
      final dateStr = m['date'] as String;
      // If date string is in format "YYYY-MM-DD", parse it directly as local date
      if (dateStr.length == 10 && dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          dateValue = DateTime(year, month, day);
        } else {
          final parsed = DateTime.parse(dateStr);
          // Convert to local timezone first, then normalize
          final local = parsed.toLocal();
          dateValue = DateTime(local.year, local.month, local.day);
        }
      } else {
        final parsed = DateTime.parse(dateStr);
        // Convert to local timezone first, then normalize
        final local = parsed.toLocal();
        dateValue = DateTime(local.year, local.month, local.day);
      }
    } else if (m['date'] is DateTime) {
      final dt = m['date'] as DateTime;
      // Convert to local timezone first, then normalize
      final local = dt.toLocal();
      dateValue = DateTime(local.year, local.month, local.day);
    } else {
      // Try to parse as ISO string
      final parsed = DateTime.parse(m['date'].toString());
      // Convert to local timezone first, then normalize
      final local = parsed.toLocal();
      dateValue = DateTime(local.year, local.month, local.day);
    }

    // Handle shiftType: normalize to lowercase
    String shiftTypeValue = (m['shiftType'] ?? m['shift'] ?? '').toString().toLowerCase();
    
    // Handle status: default to 'scheduled' if not provided
    String statusValue = (m['status'] ?? 'scheduled').toString().toLowerCase();

    return WorkScheduleModel(
      id: m['_id']?.toString() ?? '',
      employeeId: employeeIdValue,
      date: dateValue,
      startTime: (m['startTime'] ?? '').toString(),
      endTime: (m['endTime'] ?? '').toString(),
      shiftType: shiftTypeValue,
      status: statusValue,
      notes: m['notes']?.toString(),
      employeeName: employeeNameValue ?? m['employeeName']?.toString(),
    );
  }
}

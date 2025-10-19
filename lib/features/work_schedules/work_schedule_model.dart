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

  factory WorkScheduleModel.fromMap(Map<String, dynamic> m) =>
      WorkScheduleModel(
        id: m['_id'] as String,
        employeeId: m['employeeId'] is String
            ? m['employeeId'] as String
            : (m['employeeId']?['_id'] as String),
        date: DateTime.parse(m['date'] as String),
        startTime: (m['startTime'] ?? '') as String,
        endTime: (m['endTime'] ?? '') as String,
        shiftType: (m['shiftType'] ?? '') as String,
        status: (m['status'] ?? '') as String,
        notes: m['notes'] as String?,
        employeeName: m['employeeId'] is Map<String, dynamic>
            ? m['employeeId']['fullName'] as String?
            : null,
      );
}

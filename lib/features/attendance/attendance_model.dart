class AttendanceModel {
  final String id;
  final String memberId;
  final String? memberName;
  final DateTime checkinTime;
  final DateTime? checkoutTime;
  final int? workoutDurationMinutes;
  final String status;
  final String? note;

  AttendanceModel({
    required this.id,
    required this.memberId,
    this.memberName,
    required this.checkinTime,
    this.checkoutTime,
    this.workoutDurationMinutes,
    required this.status,
    this.note,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> j) {
    final member = j['member_id'];
    return AttendanceModel(
      id: j['_id'] ?? j['id'],
      memberId: member is Map
          ? (member['_id'] ?? member['id'] ?? '')
          : (j['member_id'] ?? ''),
      memberName: member is Map ? (member['fullName'] ?? member['name']) : null,
      checkinTime: DateTime.parse(j['checkin_time']),
      checkoutTime: j['checkout_time'] != null
          ? DateTime.parse(j['checkout_time'])
          : null,
      workoutDurationMinutes: j['workout_duration'],
      status: j['status'] ?? 'checked_in',
      note: j['note'],
    );
  }
}

class AttendanceOverview {
  final int totalCheckins;
  final int totalCheckouts;
  final int currentlyInGym;
  final int avgWorkoutDuration;

  AttendanceOverview({
    required this.totalCheckins,
    required this.totalCheckouts,
    required this.currentlyInGym,
    required this.avgWorkoutDuration,
  });

  factory AttendanceOverview.fromJson(Map<String, dynamic> j) {
    final data = j['data']?['today'] ?? j['today'] ?? j;
    return AttendanceOverview(
      totalCheckins: data['totalCheckins'] ?? 0,
      totalCheckouts: data['totalCheckouts'] ?? 0,
      currentlyInGym: data['currentlyInGym'] ?? 0,
      avgWorkoutDuration: data['avgWorkoutDuration'] ?? 0,
    );
  }
}

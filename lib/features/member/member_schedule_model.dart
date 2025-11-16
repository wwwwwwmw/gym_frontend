class MemberScheduleItem {
  final String id;
  final DateTime date;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String shiftType; // morning/afternoon/...
  final String status; // scheduled/...
  final String? note;
  final String? packageName;
  final String? trainerName;

  MemberScheduleItem({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shiftType,
    required this.status,
    this.note,
    this.packageName,
    this.trainerName,
  });

  factory MemberScheduleItem.fromJson(Map<String, dynamic> json) {
    return MemberScheduleItem(
      id: json['_id']?.toString() ?? '',
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      shiftType: json['shiftType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'scheduled',
      note: json['note']?.toString(),
      packageName: (json['package'] is Map)
          ? (json['package']['name']?.toString())
          : null,
      trainerName: (json['trainer'] is Map)
          ? (json['trainer']['fullName']?.toString())
          : null,
    );
  }
}

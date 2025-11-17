class MemberModel {
  final String id;
  final String? userId;
  final String fullName;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? membershipNumber;
  final DateTime? joinDate;
  final String status;
  final EmergencyContact? emergencyContact;
  final String? notes;
  final String? profileImage;
  final DateTime? lastVisit;
  final int totalVisits;
  final SchedulePreferences? schedulePreferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MemberModel({
    required this.id,
    this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.membershipNumber,
    this.joinDate,
    required this.status,
    this.emergencyContact,
    this.notes,
    this.profileImage,
    this.lastVisit,
    required this.totalVisits,
    this.schedulePreferences,
    this.createdAt,
    this.updatedAt,
  });

  factory MemberModel.fromMap(Map<String, dynamic> m) {
    return MemberModel(
      id: m['_id'] as String,
      userId: m['user_id'] as String?,
      fullName: (m['fullName'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      dateOfBirth: m['dateOfBirth'] != null
          ? DateTime.tryParse(m['dateOfBirth'].toString())
          : null,
      gender: m['gender'] as String?,
      address: m['address'] as String?,
      membershipNumber: m['membershipNumber'] as String?,
      joinDate: m['joinDate'] != null
          ? DateTime.tryParse(m['joinDate'].toString())
          : null,
      status: (m['status'] ?? 'Hoạt động') as String,
      emergencyContact: m['emergencyContact'] != null
          ? EmergencyContact.fromMap(
              Map<String, dynamic>.from(m['emergencyContact'] as Map),
            )
          : null,
      notes: m['notes'] as String?,
      profileImage: m['profileImage'] as String?,
      lastVisit: m['lastVisit'] != null
          ? DateTime.tryParse(m['lastVisit'].toString())
          : null,
      totalVisits: (m['totalVisits'] ?? 0) as int,
      schedulePreferences: m['schedulePreferences'] != null
          ? SchedulePreferences.fromMap(
              Map<String, dynamic>.from(m['schedulePreferences'] as Map),
            )
          : null,
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'].toString())
          : null,
      updatedAt: m['updatedAt'] != null
          ? DateTime.tryParse(m['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (address != null) 'address': address,
      'status': status,
      if (emergencyContact != null)
        'emergencyContact': emergencyContact!.toMap(),
      if (notes != null) 'notes': notes,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }
}

class EmergencyContact {
  final String? name;
  final String? phone;
  final String? relationship;

  EmergencyContact({this.name, this.phone, this.relationship});

  factory EmergencyContact.fromMap(Map<String, dynamic> m) {
    return EmergencyContact(
      name: m['name'] as String?,
      phone: m['phone'] as String?,
      relationship: m['relationship'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (relationship != null) 'relationship': relationship,
    };
  }
}

class SchedulePreferences {
  final List<int>? days;
  final String? shift;
  final List<WeeklyPreference>? weekly;
  final DateTime? updatedAt;

  SchedulePreferences({this.days, this.shift, this.weekly, this.updatedAt});

  factory SchedulePreferences.fromMap(Map<String, dynamic> m) {
    return SchedulePreferences(
      days: m['days'] != null
          ? (m['days'] as List).map((e) => e as int).toList()
          : null,
      shift: m['shift'] as String?,
      weekly: m['weekly'] != null
          ? (m['weekly'] as List)
                .map(
                  (e) => WeeklyPreference.fromMap(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
          : null,
      updatedAt: m['updatedAt'] != null
          ? DateTime.tryParse(m['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (days != null) 'days': days,
      if (shift != null) 'shift': shift,
      if (weekly != null) 'weekly': weekly!.map((e) => e.toMap()).toList(),
    };
  }
}

class WeeklyPreference {
  final int day;
  final String shift;

  WeeklyPreference({required this.day, required this.shift});

  factory WeeklyPreference.fromMap(Map<String, dynamic> m) {
    return WeeklyPreference(day: m['day'] as int, shift: m['shift'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'day': day, 'shift': shift};
  }
}

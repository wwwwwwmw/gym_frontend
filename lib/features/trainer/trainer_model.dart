class TrainerModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? position;
  final String? department;
  final String? specialty;
  final String? bio;
  final String? profileImage;
  final String status;
  final DateTime? createdAt;

  TrainerModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.position,
    this.department,
    this.specialty,
    this.bio,
    this.profileImage,
    required this.status,
    this.createdAt,
  });

  factory TrainerModel.fromMap(Map<String, dynamic> m) {
    return TrainerModel(
      id: m['_id'] as String,
      fullName: (m['fullName'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      position: m['position'] as String?,
      department: m['department'] as String?,
      specialty: m['specialty'] as String?,
      bio: m['bio'] as String?,
      profileImage: m['profileImage'] as String?,
      status: (m['status'] ?? 'active') as String,
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'].toString())
          : null,
    );
  }
}

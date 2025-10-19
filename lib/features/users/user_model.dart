class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isEmailVerified;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isEmailVerified,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: j['_id'] ?? j['id'],
      fullName: j['fullName'] ?? '',
      email: j['email'] ?? '',
      role: j['role'] ?? 'MEMBER',
      isEmailVerified: j['isEmailVerified'] ?? false,
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'])
          : null,
    );
  }
}

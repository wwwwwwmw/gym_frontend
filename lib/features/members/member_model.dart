class MemberModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String status;

  MemberModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory MemberModel.fromMap(Map<String, dynamic> m) => MemberModel(
    id: m['_id'] as String,
    fullName: (m['fullName'] ?? '') as String,
    email: (m['email'] ?? '') as String,
    phone: (m['phone'] ?? '') as String,
    status: (m['status'] ?? '') as String,
  );
}

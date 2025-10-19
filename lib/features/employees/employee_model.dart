class EmployeeModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String position;
  final String? department;
  final num? salary;
  final DateTime? hireDate;
  final String status; // active|inactive|terminated

  EmployeeModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.position,
    required this.department,
    required this.salary,
    required this.hireDate,
    required this.status,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> m) => EmployeeModel(
    id: m['_id'] as String,
    fullName: (m['fullName'] ?? '') as String,
    email: (m['email'] ?? '') as String,
    phone: (m['phone'] ?? '') as String,
    position: (m['position'] ?? '') as String,
    department: m['department'] as String?,
    salary: m['salary'] as num?,
    hireDate: m['hireDate'] != null
        ? DateTime.tryParse(m['hireDate'] as String)
        : null,
    status: ((m['status'] ?? 'active') as String).toLowerCase(),
  );

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'position': position,
    if (department != null && department!.isNotEmpty) 'department': department,
    if (salary != null) 'salary': salary,
    if (hireDate != null) 'hireDate': hireDate!.toIso8601String(),
    'status': status,
  };
}

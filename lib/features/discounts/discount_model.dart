class DiscountModel {
  final String id;
  final String name;
  final String? description;
  final String type; // percentage|fixed
  final num value;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active|inactive|expired
  final List<String> applicablePackageIds;
  final num? minPurchaseAmount;
  final int? maxUsageCount;
  final int currentUsageCount;

  DiscountModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.applicablePackageIds,
    required this.minPurchaseAmount,
    required this.maxUsageCount,
    required this.currentUsageCount,
  });

  factory DiscountModel.fromMap(Map<String, dynamic> m) => DiscountModel(
    id: m['_id'] as String,
    name: (m['name'] ?? '') as String,
    description: m['description'] as String?,
    type: (m['type'] ?? 'percentage') as String,
    value: (m['value'] ?? 0) as num,
    startDate: DateTime.parse(m['startDate'] as String),
    endDate: DateTime.parse(m['endDate'] as String),
    status: (m['status'] ?? 'active') as String,
    applicablePackageIds: ((m['applicablePackages'] as List?) ?? [])
        .map((e) => e is String ? e : (e['_id'] as String))
        .toList(),
    minPurchaseAmount: m['minPurchaseAmount'] as num?,
    maxUsageCount: m['maxUsageCount'] as int?,
    currentUsageCount: (m['currentUsageCount'] ?? 0) as int,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    if (description != null) 'description': description,
    'type': type,
    'value': value,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status,
    'applicablePackages': applicablePackageIds,
    if (minPurchaseAmount != null) 'minPurchaseAmount': minPurchaseAmount,
    if (maxUsageCount != null) 'maxUsageCount': maxUsageCount,
  };
}

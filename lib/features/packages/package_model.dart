class PackageModel {
  final String id;
  final String name;
  final String? description;
  final int duration; // days
  final num price; // VND
  final List<String> features;
  final String status; // active|inactive|discontinued
  final int? maxSessions;
  final bool isPersonalTraining; // includes PT sessions / requires trainer

  PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    required this.features,
    required this.status,
    required this.maxSessions,
    required this.isPersonalTraining,
  });

  factory PackageModel.fromMap(Map<String, dynamic> m) => PackageModel(
    id: m['_id'] as String,
    name: (m['name'] ?? '') as String,
    description: m['description'] as String?,
    duration: (m['duration'] ?? 0) as int,
    price: (m['price'] ?? 0) as num,
    features: ((m['features'] as List?) ?? [])
        .map((e) => e.toString())
        .toList(),
    status: (m['status'] ?? 'active') as String,
    maxSessions: m['maxSessions'] as int?,
    isPersonalTraining: (m['isPersonalTraining'] ?? false) as bool,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    if (description != null) 'description': description,
    'duration': duration,
    'price': price,
    'features': features,
    'status': status,
    if (maxSessions != null) 'maxSessions': maxSessions,
    'isPersonalTraining': isPersonalTraining,
  };
}

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
  final String? imageUrl; // optional image URL from backend
  final bool? hasFixedSchedule; // có lịch tập cố định
  final Map<String, dynamic>?
  schedule; // lịch tập: {daysOfWeek: [1,3,5], startTime: "18:00", endTime: "19:30"}
  final String? defaultTrainerId; // ID của PT mặc định
  final Map<String, dynamic>?
  defaultTrainer; // Thông tin PT mặc định (nếu được populate)

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
    this.imageUrl,
    this.hasFixedSchedule,
    this.schedule,
    this.defaultTrainerId,
    this.defaultTrainer,
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
    imageUrl: m['imageUrl'] as String?,
    hasFixedSchedule: m['hasFixedSchedule'] is bool
        ? m['hasFixedSchedule'] as bool
        : (m['hasFixedSchedule'] == 'true' || m['hasFixedSchedule'] == true),
    schedule: m['schedule'] is Map
        ? Map<String, dynamic>.from(m['schedule'] as Map)
        : null,
    defaultTrainerId: m['defaultTrainerId'] is Map
        ? (m['defaultTrainerId']['_id'] ?? m['defaultTrainerId']['id'])
              ?.toString()
        : m['defaultTrainerId']?.toString(),
    defaultTrainer: m['defaultTrainerId'] is Map
        ? Map<String, dynamic>.from(m['defaultTrainerId'] as Map)
        : null,
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
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

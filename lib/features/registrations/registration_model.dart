class RegistrationModel {
  final String id;
  final MemberRef member;
  final PackageRef package;
  final DiscountRef? discount;
  final TrainerRef? trainer;
  final DateTime startDate;
  final DateTime endDate;
  final String paymentMethod;
  final num originalPrice;
  final num discountAmount;
  final num finalPrice;
  final String status;
  final String? statusReason;
  final List<int>? memberPreferredDays;
  final String? memberPreferredShift;

  RegistrationModel({
    required this.id,
    required this.member,
    required this.package,
    required this.discount,
    required this.startDate,
    required this.endDate,
    required this.paymentMethod,
    required this.originalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.status,
    this.statusReason,
    this.memberPreferredDays,
    this.memberPreferredShift,
    this.trainer,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> j) {
    final startRaw = j['start_date'] ?? j['startDate'];
    final endRaw = j['end_date'] ?? j['endDate'];
    final payRaw = j['payment_method'] ?? j['paymentMethod'];
    final origRaw = j['original_price'] ?? j['originalPrice'];
    final discRaw = j['discount_amount'] ?? j['discountAmount'];
    final finalRaw = j['final_price'] ?? j['finalPrice'];
    final statusRaw = j['status'];
    final statusReasonRaw = j['status_reason'] ?? j['statusReason'];
    final memberMap = _ensureMap(j['member_id']);
    final trainerMap = _ensureMap(j['trainer_id']);
    final prefs = memberMap['schedulePreferences'] as Map<String, dynamic>?;
    return RegistrationModel(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      member: MemberRef.fromJson(memberMap),
      package: PackageRef.fromJson(_ensureMap(j['package_id'])),
      discount: j['discount_id'] != null
          ? DiscountRef.fromJson(_ensureMap(j['discount_id']))
          : null,
      trainer: trainerMap.isNotEmpty ? TrainerRef.fromJson(trainerMap) : null,
      startDate: startRaw != null
          ? DateTime.parse(startRaw)
          : DateTime.fromMillisecondsSinceEpoch(0),
      endDate: endRaw != null
          ? DateTime.parse(endRaw)
          : DateTime.fromMillisecondsSinceEpoch(0),
      paymentMethod: (payRaw ?? 'cash').toString(),
      originalPrice: origRaw ?? 0,
      discountAmount: discRaw ?? 0,
      finalPrice: finalRaw ?? 0,
      status: (statusRaw ?? 'active').toString(),
      statusReason: statusReasonRaw?.toString(),
      memberPreferredDays: (prefs?['days'] as List?)
          ?.map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList(),
      memberPreferredShift: prefs?['shift']?.toString(),
    );
  }

  static Map<String, dynamic> _ensureMap(dynamic v) {
    if (v == null) return {};
    if (v is Map<String, dynamic>) return v;
    if (v is String) return {'_id': v, 'name': v, 'fullName': v};
    return {};
  }
}

class TrainerRef {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  TrainerRef({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
  });
  factory TrainerRef.fromJson(Map<String, dynamic> j) => TrainerRef(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    fullName: (j['fullName'] ?? '').toString(),
    email: j['email']?.toString(),
    phone: j['phone']?.toString(),
  );
}

class MemberRef {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;

  MemberRef({required this.id, required this.fullName, this.email, this.phone});

  factory MemberRef.fromJson(Map<String, dynamic> j) {
    return MemberRef(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      fullName: (j['fullName'] ?? '').toString(),
      email: j['email'],
      phone: j['phone'],
    );
  }
}

class PackageRef {
  final String id;
  final String name;
  final int? duration;
  final num? price;
  final String? description;
  final List<String>? features;
  final String? imageUrl;

  PackageRef({
    required this.id,
    required this.name,
    this.duration,
    this.price,
    this.description,
    this.features,
    this.imageUrl,
  });

  factory PackageRef.fromJson(Map<String, dynamic> j) {
    return PackageRef(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      duration: j['duration'],
      price: j['price'],
      description: j['description']?.toString(),
      features: (j['features'] as List?)?.map((e) => e.toString()).toList(),
      imageUrl: j['imageUrl']?.toString(),
    );
  }
}

class DiscountRef {
  final String id;
  final String name;
  final String type;
  final num value;

  DiscountRef({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
  });

  factory DiscountRef.fromJson(Map<String, dynamic> j) {
    return DiscountRef(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      type: (j['type'] ?? 'percentage').toString(),
      value: j['value'] ?? 0,
    );
  }
}

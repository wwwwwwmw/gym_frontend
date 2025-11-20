class CampaignModel {
  final String id;
  final String name;
  final String? description;
  final String type; // percentage|fixed|buy_x_get_y|bundle|seasonal
  final DateTime startDate;
  final DateTime endDate;
  final String status; // draft|active|paused|ended|expired
  final String targetAudience; // all|new_users|existing_users|premium_users|specific_packages
  final List<String> applicablePackageIds;
  final num? minPurchaseAmount;
  final num? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;
  final int userUsageLimit;
  final int priority;
  final bool isAutoApply;
  final CampaignConditions? conditions;
  final CampaignMetadata? metadata;
  final List<String> discountIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CampaignModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.targetAudience,
    required this.applicablePackageIds,
    required this.minPurchaseAmount,
    required this.maxDiscountAmount,
    required this.usageLimit,
    required this.usedCount,
    required this.userUsageLimit,
    required this.priority,
    required this.isAutoApply,
    this.conditions,
    this.metadata,
    required this.discountIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CampaignModel.fromMap(Map<String, dynamic> m) => CampaignModel(
    id: m['_id'] as String,
    name: (m['name'] ?? '') as String,
    description: m['description'] as String?,
    type: (m['type'] ?? 'percentage') as String,
    startDate: DateTime.parse(m['startDate'] as String),
    endDate: DateTime.parse(m['endDate'] as String),
    status: (m['status'] ?? 'draft') as String,
    targetAudience: (m['targetAudience'] ?? 'all') as String,
    applicablePackageIds: ((m['applicablePackages'] as List?) ?? [])
        .map((e) => e is String ? e : (e['_id'] as String))
        .toList(),
    minPurchaseAmount: m['minPurchaseAmount'] as num?,
    maxDiscountAmount: m['maxDiscountAmount'] as num?,
    usageLimit: m['usageLimit'] as int?,
    usedCount: (m['usedCount'] ?? 0) as int,
    userUsageLimit: (m['userUsageLimit'] ?? 1) as int,
    priority: (m['priority'] ?? 0) as int,
    isAutoApply: (m['isAutoApply'] ?? true) as bool,
    conditions: m['conditions'] != null 
        ? CampaignConditions.fromMap(m['conditions'] as Map<String, dynamic>)
        : null,
    metadata: m['metadata'] != null
        ? CampaignMetadata.fromMap(m['metadata'] as Map<String, dynamic>)
        : null,
    discountIds: ((m['discounts'] as List?) ?? [])
        .map((e) => e is String ? e : (e['_id'] as String))
        .toList(),
    createdBy: (m['createdBy'] is String 
        ? m['createdBy'] 
        : (m['createdBy']?['_id'] ?? '')) as String,
    createdAt: DateTime.parse(m['createdAt'] as String),
    updatedAt: DateTime.parse(m['updatedAt'] as String),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    if (description != null) 'description': description,
    'type': type,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'status': status,
    'targetAudience': targetAudience,
    'applicablePackages': applicablePackageIds,
    if (minPurchaseAmount != null) 'minPurchaseAmount': minPurchaseAmount,
    if (maxDiscountAmount != null) 'maxDiscountAmount': maxDiscountAmount,
    if (usageLimit != null) 'usageLimit': usageLimit,
    'userUsageLimit': userUsageLimit,
    'priority': priority,
    'isAutoApply': isAutoApply,
    if (conditions != null) 'conditions': conditions!.toMap(),
    if (metadata != null) 'metadata': metadata!.toMap(),
    'discounts': discountIds,
  };

  // Helper methods
  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
  
  bool get isExpired => endDate.isBefore(DateTime.now()) || status == 'expired';
  
  bool get isAvailable {
    final now = DateTime.now();
    return status == 'active' && 
           startDate.isBefore(now) && 
           endDate.isAfter(now) &&
           (usageLimit == null || usedCount < usageLimit!);
  }

  String get campaignText {
    switch (type) {
      case 'percentage':
        return 'Giảm giá %';
      case 'fixed':
        return 'Giảm giá cố định';
      case 'buy_x_get_y':
        return 'Mua X tặng Y';
      case 'bundle':
        return 'Gói combo';
      case 'seasonal':
        return 'Theo mùa';
      default:
        return 'Khuyến mãi';
    }
  }

  String get targetAudienceText {
    switch (targetAudience) {
      case 'new_users':
        return 'Người dùng mới';
      case 'existing_users':
        return 'Người dùng hiện tại';
      case 'premium_users':
        return 'Người dùng cao cấp';
      case 'specific_packages':
        return 'Gói cụ thể';
      default:
        return 'Tất cả người dùng';
    }
  }
}

class CampaignConditions {
  final int? minSessions;
  final int? maxSessions;
  final int? membershipDuration;
  final UserAgeRange? userAgeRange;

  CampaignConditions({
    this.minSessions,
    this.maxSessions,
    this.membershipDuration,
    this.userAgeRange,
  });

  factory CampaignConditions.fromMap(Map<String, dynamic> m) => CampaignConditions(
    minSessions: m['minSessions'] as int?,
    maxSessions: m['maxSessions'] as int?,
    membershipDuration: m['membershipDuration'] as int?,
    userAgeRange: m['userAgeRange'] != null
        ? UserAgeRange.fromMap(m['userAgeRange'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toMap() => {
    if (minSessions != null) 'minSessions': minSessions,
    if (maxSessions != null) 'maxSessions': maxSessions,
    if (membershipDuration != null) 'membershipDuration': membershipDuration,
    if (userAgeRange != null) 'userAgeRange': userAgeRange!.toMap(),
  };
}

class UserAgeRange {
  final int? min;
  final int? max;

  UserAgeRange({
    this.min,
    this.max,
  });

  factory UserAgeRange.fromMap(Map<String, dynamic> m) => UserAgeRange(
    min: m['min'] as int?,
    max: m['max'] as int?,
  );

  Map<String, dynamic> toMap() => {
    if (min != null) 'min': min,
    if (max != null) 'max': max,
  };
}

class CampaignMetadata {
  final String? bannerImage;
  final String? termsAndConditions;
  final String? highlightText;
  final ColorScheme? colorScheme;

  CampaignMetadata({
    this.bannerImage,
    this.termsAndConditions,
    this.highlightText,
    this.colorScheme,
  });

  factory CampaignMetadata.fromMap(Map<String, dynamic> m) => CampaignMetadata(
    bannerImage: m['bannerImage'] as String?,
    termsAndConditions: m['termsAndConditions'] as String?,
    highlightText: m['highlightText'] as String?,
    colorScheme: m['colorScheme'] != null
        ? ColorScheme.fromMap(m['colorScheme'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toMap() => {
    if (bannerImage != null) 'bannerImage': bannerImage,
    if (termsAndConditions != null) 'termsAndConditions': termsAndConditions,
    if (highlightText != null) 'highlightText': highlightText,
    if (colorScheme != null) 'colorScheme': colorScheme!.toMap(),
  };
}

class ColorScheme {
  final String? primary;
  final String? secondary;

  ColorScheme({
    this.primary,
    this.secondary,
  });

  factory ColorScheme.fromMap(Map<String, dynamic> m) => ColorScheme(
    primary: m['primary'] as String?,
    secondary: m['secondary'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (primary != null) 'primary': primary,
    if (secondary != null) 'secondary': secondary,
  };
}
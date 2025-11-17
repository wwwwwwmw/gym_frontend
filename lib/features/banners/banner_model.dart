class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String position; // home, packages, both
  final int displayOrder;
  final String status;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.position,
    required this.displayOrder,
    required this.status,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      position: (json['position'] ?? 'home').toString(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final int price;
  final String? image;
  final int stock;
  final String status;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    this.stock = 0,
    this.status = 'Hoạt động',
  });

  // Helper method để kiểm tra sản phẩm có còn hàng không
  bool get isAvailable => stock > 0 && status == 'Hoạt động';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Sản phẩm',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      image: json['imageUrl'],
      stock: json['stock'] ?? 0,
      status: json['status'] ?? 'Hoạt động',
    );
  }
}

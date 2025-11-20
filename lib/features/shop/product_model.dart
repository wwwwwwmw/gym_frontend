class Product {
  final String id;
  final String name;
  final String description;
  final int price;
  final String? image;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Sản phẩm',
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      image: json['imageUrl'],
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gym_frontend/core/env.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/features/shop/product_model.dart';

class ProductService {
  final TokenStorage _tokenStorage = TokenStorage();

  // Lấy danh sách sản phẩm
  Future<List<Product>> getProducts() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      final String baseUrl = apiBaseUrl();

      final response = await http.get(
        Uri.parse('$baseUrl/api/products'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final List products = data['data'];
          return products.map((e) => Product.fromJson(e)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Lỗi tải sản phẩm: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi ProductService: $e');
      return [];
    }
  }

  // ✅ HÀM MỚI: Gọi API tạo đơn hàng
  Future<String> createOrder(String productId) async {
    final token = await _tokenStorage.getAccessToken();
    final String baseUrl = apiBaseUrl();

    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/create'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({'productId': productId}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      // Trả về orderId thật từ server
      return data['orderId'];
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Không thể tạo đơn hàng');
    }
  }
}

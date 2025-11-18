import 'package:flutter/material.dart';
import 'package:gym_frontend/features/banners/banner_model.dart';
import 'package:gym_frontend/features/banners/banner_service.dart';

class BannerProvider extends ChangeNotifier {
  final BannerService _service;

  BannerProvider(this._service);

  List<BannerModel> _homeBanners = [];
  bool _isLoading = false;
  String? _error;

  List<BannerModel> get homeBanners => _homeBanners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHomeBanners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Lấy banner hiển thị ở trang chủ
      final banners = await _service.getBanners(position: 'home');
      _homeBanners = banners;
    } catch (e) {
      debugPrint('Lỗi tải banner: $e');
      _error = e.toString();
      _homeBanners = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import '../../core/api_client.dart';
import 'banner_model.dart';

class BannerService {
  final ApiClient api;

  BannerService(this.api);

  Future<List<BannerModel>> getBanners({
    String? position,
    String? status = 'active',
  }) async {
    final query = {
      if (position != null) 'position': position,
      if (status != null) 'status': status,
      'limit': '20',
    };

    final res = await api.getJson('/api/banners', query: query);
    final list = (res['banners'] as List<dynamic>)
        .map((e) => BannerModel.fromJson(e))
        .toList();
    return list;
  }
}

import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'member_model.dart';
import 'member_service.dart';

class MemberProvider extends ChangeNotifier {
  MemberProvider() : _service = MemberService(ApiClient());

  final MemberService _service;

  bool loading = false;
  String? error;
  List<MemberModel> items = [];
  Pagination? pagination;

  Future<void> fetch({String? search, int page = 1}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final (list, pg) = await _service.list(search: search, page: page);
      items = list;
      pagination = pg;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

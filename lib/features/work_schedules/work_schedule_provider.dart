import 'package:flutter/foundation.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'work_schedule_model.dart';
import 'work_schedule_service.dart';

class WorkScheduleProvider extends ChangeNotifier {
  WorkScheduleProvider() : _service = WorkScheduleService(ApiClient());
  final WorkScheduleService _service;

  bool isLoading = false;
  String? error;
  List<WorkScheduleModel> items = [];
  Pagination? pagination;

  // Getter for backward compatibility
  List<WorkScheduleModel> get schedules => items;

  Future<void> fetchMy({
    String? date,
    String? status,
    String? shiftType,
    int page = 1,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final (list, pg) = await _service.listMy(
        date: date,
        status: status,
        shiftType: shiftType,
        page: page,
      );
      items = list;
      pagination = pg;
      error = null; // Clear any previous errors
    } catch (e) {
      // Extract meaningful error message
      String errorMessage = 'Không thể tải lịch làm việc';
      if (e.toString().contains('401') || e.toString().contains('chưa đăng nhập')) {
        errorMessage = 'Bạn chưa đăng nhập hoặc phiên đã hết hạn';
      } else if (e.toString().contains('403') || e.toString().contains('quyền')) {
        errorMessage = 'Bạn chưa có quyền xem lịch làm việc này';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Không tìm thấy lịch làm việc';
      } else if (e.toString().contains('500') || e.toString().contains('Máy chủ')) {
        errorMessage = 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau';
      } else {
        // Try to extract message from exception
        final msg = e.toString();
        if (msg.contains('Exception: ')) {
          errorMessage = msg.split('Exception: ').last;
        } else if (msg.length < 100) {
          errorMessage = msg;
        }
      }
      error = errorMessage;
      items = []; // Clear items on error
      pagination = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

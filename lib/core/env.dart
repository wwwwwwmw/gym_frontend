import 'package:flutter/foundation.dart';

const String _apiBaseFromDefine = String.fromEnvironment(
  'API_BASE',
  defaultValue: '',
);

String apiBaseUrl() {
  if (_apiBaseFromDefine.isNotEmpty) return _apiBaseFromDefine;
  if (kIsWeb) return 'http://localhost:3001';

  // ✅ CẬP NHẬT: IP máy tính của bạn và Port 3001
  return 'http://192.168.1.2:3001';
}

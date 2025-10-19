import 'package:flutter/foundation.dart';

/// API base URL (platform-aware)
/// - Web/Chrome: http://localhost:3001
/// - Android emulator: http://10.0.2.2:3001
/// - iOS simulator/desktop: http://localhost:3001
/// - Physical device: pass --dart-define=API_BASE=http://PC-IP:3001 when running
const String _apiBaseFromDefine = String.fromEnvironment(
  'API_BASE',
  defaultValue: '',
);

String apiBaseUrl() {
  if (_apiBaseFromDefine.isNotEmpty) return _apiBaseFromDefine;
  if (kIsWeb) return 'http://localhost:3001';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:3001';
    default:
      return 'http://localhost:3001';
  }
}

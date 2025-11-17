class AppConfig {
  // Base API (use --dart-define to override at build/run)
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:3001',
  );

  // Web Admin URL (use --dart-define to override at build/run)
  static const adminWeb = String.fromEnvironment(
    'ADMIN_WEB',
    defaultValue: 'http://10.0.2.2:4000/admin',
  );
}

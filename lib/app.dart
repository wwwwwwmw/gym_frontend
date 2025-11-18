import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';

// Import ApiClient và Banner services
import 'core/api_client.dart';
import 'features/banners/banner_service.dart';
import 'features/banners/banner_provider.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_provider.dart';

import 'features/auth/signup_screen.dart' as signupScreen;
import 'features/auth/verify_email_screen.dart';

import 'features/dashboards/trainer_dashboard.dart';

import 'features/member/member_home_screen.dart';

import 'features/discounts/discount_provider.dart';

import 'features/work_schedules/work_schedule_provider.dart';
import 'features/work_schedules/work_schedules_screen.dart';

import 'features/registrations/registration_provider.dart';

import 'features/attendance/attendance_provider.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/attendance/qr_checkin_screen.dart';

import 'features/member/member_register_package_screen.dart';
import 'features/discounts/active_discounts_screen.dart';
import 'features/member/member_current_package_screen.dart';
import 'features/member/member_schedule_screen.dart';
import 'features/trainer/my_students_screen.dart';
import 'features/member/payment_result_screen.dart';
import 'features/packages/packages_screen.dart';
import 'features/member/member_profile_screen.dart';
import 'features/payments/payment_history_screen.dart';
import 'features/trainer/trainers_screen.dart';

class GymApp extends StatefulWidget {
  const GymApp({super.key});

  @override
  State<GymApp> createState() => _GymAppState();
}

class _GymAppState extends State<GymApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (_) {}
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    }, onError: (err) {});
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'gymapp' && uri.host == 'payment-result') {
      final successStr = uri.queryParameters['success'];
      final code = uri.queryParameters['code'] ?? 'N/A';
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      final routeName =
          '/payment-result?success=${successStr ?? ''}&code=$code';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.pushNamed(routeName);
      });
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => DiscountProvider()),
        ChangeNotifierProvider(create: (_) => WorkScheduleProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        // ✅ Thêm BannerProvider vào đây
        ChangeNotifierProvider(
          create: (_) => BannerProvider(BannerService(ApiClient())),
        ),
      ],
      child: MaterialApp(
        title: 'Gym Manager',
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        navigatorKey: _navigatorKey,
        onGenerateRoute: (settings) {
          final Uri uri = Uri.parse(settings.name ?? '');
          switch (uri.path) {
            case '/payment-result':
              {
                final successStr = uri.queryParameters['success'];
                final code = uri.queryParameters['code'];
                return MaterialPageRoute(
                  builder: (_) =>
                      PaymentResultScreen(success: successStr, code: code),
                );
              }
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/signup':
              return MaterialPageRoute(
                builder: (_) => const signupScreen.SignupScreen(),
              );
            case '/verify':
              return MaterialPageRoute(
                builder: (_) => const VerifyEmailScreen(),
              );
            case '/dash/trainer':
              return MaterialPageRoute(
                builder: (_) => const TrainerDashboard(),
              );
            case '/dash/member':
              return MaterialPageRoute(
                builder: (_) => const MemberHomeScreen(),
              );

            case '/member/register-package':
              return MaterialPageRoute(
                builder: (_) => const MemberRegisterPackageScreen(),
              );
            case '/member/current-package':
              return MaterialPageRoute(
                builder: (_) => const MemberCurrentPackageScreen(),
              );
            case '/member/schedule':
              return MaterialPageRoute(
                builder: (_) => const MemberScheduleScreen(),
              );
            case '/member/profile':
              return MaterialPageRoute(
                builder: (_) => const MemberProfileScreen(),
              );
            case '/packages':
              return MaterialPageRoute(builder: (_) => const PackagesScreen());
            case '/trainers':
              return MaterialPageRoute(builder: (_) => const TrainersScreen());
            case '/payments/history':
              return MaterialPageRoute(
                builder: (_) => const PaymentHistoryScreen(),
              );
            case '/work-schedules':
              return MaterialPageRoute(
                builder: (_) => const WorkSchedulesScreen(),
              );
            case '/trainer/my-students':
              return MaterialPageRoute(
                builder: (_) => const MyStudentsScreen(),
              );
            case '/attendance':
              return MaterialPageRoute(
                builder: (_) => const AttendanceScreen(),
              );
            case '/attendance/qr-scan':
              return MaterialPageRoute(builder: (_) => const QrCheckInScreen());
            case '/discounts/active':
              return MaterialPageRoute(
                builder: (_) => const ActiveDiscountsScreen(),
              );
            default:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        },
      ),
    );
  }
}
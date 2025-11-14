// app.dart

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_provider.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/dashboards/admin_dashboard.dart';
import 'features/dashboards/manager_dashboard.dart';
import 'features/dashboards/trainer_dashboard.dart';
import 'features/dashboards/reception_dashboard.dart';
import 'features/dashboards/member_dashboard.dart';
import 'features/members/member_provider.dart';
import 'features/members/members_screen.dart';
import 'features/packages/package_provider.dart';
import 'features/packages/packages_screen.dart';
import 'features/employees/employee_provider.dart';
import 'features/employees/employees_screen.dart';
import 'features/discounts/discount_provider.dart';
import 'features/discounts/discounts_screen.dart';
import 'features/work_schedules/work_schedule_provider.dart';
import 'features/work_schedules/work_schedules_screen.dart';
import 'features/reception/member_create_screen.dart';
import 'features/reception/registration_create_screen.dart';
import 'features/registrations/registration_provider.dart';
import 'features/registrations/registrations_screen.dart';
import 'features/attendance/attendance_provider.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/users/users_screen.dart';
import 'features/users/user_provider.dart';
import 'features/member/member_register_package_screen.dart';
import 'features/discounts/active_discounts_screen.dart';
import 'features/member/member_current_package_screen.dart';
import 'features/member/member_schedule_screen.dart';
import 'features/trainer/my_students_screen.dart';
import 'features/member/payment_result_screen.dart';

class GymApp extends StatefulWidget {
  const GymApp({super.key});

  @override
  State<GymApp> createState() => _GymAppState();
}

class _GymAppState extends State<GymApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  // Dùng key để điều hướng thay vì context
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Khi app mở lần đầu qua deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (_) {
      // ignore
    }

    // Khi app đang mở và nhận deep link
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri);
      },
      onError: (err) {
        // ignore
      },
    );
  }

  void _handleUri(Uri uri) {
    // gymapp://payment-result?success=true&code=00
    if (uri.scheme == 'gymapp' && uri.host == 'payment-result') {
      final successStr = uri.queryParameters['success'];
      final code = uri.queryParameters['code'] ?? 'N/A';

      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;

      // Route name chứa query, để onGenerateRoute parse ra
      final routeName =
          '/payment-result?success=${successStr ?? ''}&code=$code';

      // Đợi xong frame đầu (MaterialApp đã tạo Navigator và push /login)
      // rồi mới push màn kết quả để nó luôn nằm trên cùng.
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
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => PackageProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => DiscountProvider()),
        ChangeNotifierProvider(create: (_) => WorkScheduleProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Gym Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
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
              return MaterialPageRoute(builder: (_) => const SignupScreen());
            case '/verify':
              return MaterialPageRoute(
                builder: (_) => const VerifyEmailScreen(),
              );
            case '/members':
              return MaterialPageRoute(builder: (_) => const MembersScreen());
            case '/packages':
              return MaterialPageRoute(builder: (_) => const PackagesScreen());
            case '/employees':
              return MaterialPageRoute(builder: (_) => const EmployeesScreen());
            case '/discounts':
              return MaterialPageRoute(builder: (_) => const DiscountsScreen());
            case '/dash/admin':
              return MaterialPageRoute(builder: (_) => const AdminDashboard());
            case '/dash/manager':
              return MaterialPageRoute(
                builder: (_) => const ManagerDashboard(),
              );
            case '/dash/trainer':
              return MaterialPageRoute(
                builder: (_) => const TrainerDashboard(),
              );
            case '/dash/reception':
              return MaterialPageRoute(
                builder: (_) => const ReceptionDashboard(),
              );
            case '/dash/member':
              return MaterialPageRoute(builder: (_) => const MemberDashboard());
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
            case '/work-schedules':
              return MaterialPageRoute(
                builder: (_) => const WorkSchedulesScreen(),
              );
            case '/trainer/my-students':
              return MaterialPageRoute(
                builder: (_) => const MyStudentsScreen(),
              );
            case '/members/create':
              return MaterialPageRoute(
                builder: (_) => const MemberCreateScreen(),
              );
            case '/registrations/create':
              return MaterialPageRoute(
                builder: (_) => const RegistrationCreateScreen(),
              );
            case '/registrations':
              return MaterialPageRoute(
                builder: (_) => const RegistrationsScreen(),
              );
            case '/attendance':
              return MaterialPageRoute(
                builder: (_) => const AttendanceScreen(),
              );
            case '/users':
              return MaterialPageRoute(builder: (_) => const UsersScreen());
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

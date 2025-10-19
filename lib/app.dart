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

class GymApp extends StatelessWidget {
  const GymApp({super.key});

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
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/verify': (_) => const VerifyEmailScreen(),
          '/members': (_) => const MembersScreen(),
          '/packages': (_) => const PackagesScreen(),
          '/employees': (_) => const EmployeesScreen(),
          '/discounts': (_) => const DiscountsScreen(),
          '/dash/admin': (_) => const AdminDashboard(),
          '/dash/manager': (_) => const ManagerDashboard(),
          '/dash/trainer': (_) => const TrainerDashboard(),
          '/dash/reception': (_) => const ReceptionDashboard(),
          '/dash/member': (_) => const MemberDashboard(),
          // Member flows
          '/member/register-package': (_) =>
              const MemberRegisterPackageScreen(),
          '/member/current-package': (_) => const MemberCurrentPackageScreen(),
          '/member/schedule': (_) => const MemberScheduleScreen(),
          '/work-schedules': (_) => const WorkSchedulesScreen(),
          '/trainer/my-students': (_) => const MyStudentsScreen(),
          '/members/create': (_) => const MemberCreateScreen(),
          '/registrations/create': (_) => const RegistrationCreateScreen(),
          '/registrations': (_) => const RegistrationsScreen(),
          '/attendance': (_) => const AttendanceScreen(),
          '/users': (_) => const UsersScreen(),
          // Member-specific
          '/discounts/active': (_) => const ActiveDiscountsScreen(),
        },
      ),
    );
  }
}

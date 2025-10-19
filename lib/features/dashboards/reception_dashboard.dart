import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_frontend/features/auth/auth_provider.dart';

class ReceptionDashboard extends StatelessWidget {
  const ReceptionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lễ tân'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _tile(
            context,
            Icons.person_add,
            'Tạo hội viên',
            () => Navigator.pushNamed(context, '/members/create'),
          ),
          _tile(
            context,
            Icons.app_registration,
            'Tạo đăng ký gói',
            () => Navigator.pushNamed(context, '/registrations/create'),
          ),
          _tile(
            context,
            Icons.group,
            'Hội viên',
            () => Navigator.pushNamed(context, '/members'),
          ),
          _tile(
            context,
            Icons.receipt_long,
            'Đăng ký gói',
            () => Navigator.pushNamed(context, '/registrations'),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext ctx,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    child: Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    ),
  );
}

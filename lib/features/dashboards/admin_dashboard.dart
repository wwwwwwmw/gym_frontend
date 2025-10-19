import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_frontend/features/auth/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị hệ thống'),
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
            Icons.fitness_center,
            'Gói tập',
            () => Navigator.pushNamed(context, '/packages'),
          ),
          _tile(
            context,
            Icons.people,
            'Nhân viên',
            () => Navigator.pushNamed(context, '/employees'),
          ),
          _tile(
            context,
            Icons.local_offer,
            'Mã giảm giá',
            () => Navigator.pushNamed(context, '/discounts'),
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

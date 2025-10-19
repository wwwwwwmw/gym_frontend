import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_frontend/features/auth/auth_provider.dart';

class TrainerDashboard extends StatelessWidget {
  const TrainerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Huấn luyện viên'),
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
            Icons.schedule,
            'Lịch làm việc',
            () => Navigator.pushNamed(context, '/work-schedules'),
          ),
          _tile(
            context,
            Icons.group,
            'Học viên của tôi',
            () => Navigator.pushNamed(context, '/trainer/my-students'),
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

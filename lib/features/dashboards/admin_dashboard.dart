import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../attendance/attendance_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().fetchOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final overview = context.watch<AttendanceProvider>().overview;

    return Scaffold(
      appBar: AppBar(title: const Text("Quản trị hệ thống"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===================== DASHBOARD OVERVIEW =====================
          if (overview != null) ...[
            const Text(
              "Tổng quan hôm nay",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoCard("Check-in", overview.totalCheckins, Colors.green),
                _infoCard("Đang tập", overview.currentlyInGym, Colors.orange),
                _infoCard("Phút TB", overview.avgWorkoutDuration, Colors.blue),
              ],
            ),

            const SizedBox(height: 28),
          ],

          // ===================== FUNCTION GRID =====================
          const Text(
            "Chức năng quản lý",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _menuCard(
                icon: Icons.fitness_center,
                label: "Gói tập",
                onTap: () => Navigator.pushNamed(context, "/packages"),
              ),
              _menuCard(
                icon: Icons.people_alt_rounded,
                label: "Nhân viên",
                onTap: () => Navigator.pushNamed(context, "/employees"),
              ),
              _menuCard(
                icon: Icons.local_offer,
                label: "Mã giảm giá",
                onTap: () => Navigator.pushNamed(context, "/discounts"),
              ),
              _menuCard(
                icon: Icons.receipt_long,
                label: "Đăng ký gói",
                onTap: () => Navigator.pushNamed(context, "/registrations"),
              ),
              _menuCard(
                icon: Icons.qr_code_scanner,
                label: "Điểm danh",
                onTap: () => Navigator.pushNamed(context, "/attendance"),
              ),
              _menuCard(
                icon: Icons.supervised_user_circle,
                label: "Người dùng",
                onTap: () => Navigator.pushNamed(context, "/users"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFEF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black87),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

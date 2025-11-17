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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Quản trị hệ thống",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =============== HEADER CARD ===============
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB9B9), Color(0xFFFFDCDC)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_rounded,
                        size: 28,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Xin chào, Admin",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Quản lý gói tập, nhân viên, người dùng và điểm danh trong một màn hình.",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =============== OVERVIEW ===============
              if (overview != null) ...[
                Row(
                  children: [
                    Text(
                      "Tổng quan hôm nay",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.today_rounded,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _infoCard(
                      title: "Check-in",
                      value: overview.totalCheckins,
                      color: const Color(0xFF22C55E),
                      icon: Icons.login_rounded,
                    ),
                    const SizedBox(width: 10),
                    _infoCard(
                      title: "Đang tập",
                      value: overview.currentlyInGym,
                      color: const Color(0xFFF97316),
                      icon: Icons.fitness_center_rounded,
                    ),
                    const SizedBox(width: 10),
                    _infoCard(
                      title: "Phút TB",
                      value: overview.avgWorkoutDuration,
                      color: const Color(0xFF3B82F6),
                      icon: Icons.timer_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],

              // =============== FUNCTION GRID ===============
              Text(
                "Chức năng quản lý",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 1.15,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
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
                    icon: Icons.local_offer_rounded,
                    label: "Mã giảm giá",
                    onTap: () => Navigator.pushNamed(context, "/discounts"),
                  ),
                  _menuCard(
                    icon: Icons.receipt_long_rounded,
                    label: "Đăng ký gói",
                    onTap: () => Navigator.pushNamed(context, "/registrations"),
                  ),

                  // ======== THÊM MỚI ========
                  _menuCard(
                    icon: Icons.person_add_alt_1_rounded,
                    label: "Tạo hội viên",
                    onTap: () =>
                        Navigator.pushNamed(context, "/members/create"),
                  ),
                  _menuCard(
                    icon: Icons.post_add_rounded,
                    label: "Tạo đăng ký",
                    onTap: () =>
                        Navigator.pushNamed(context, "/registrations/create"),
                  ),

                  // ======== KẾT THÚC THÊM MỚI ========
                  _menuCard(
                    icon: Icons.qr_code_scanner_rounded,
                    label: "Điểm danh",
                    onTap: () => Navigator.pushNamed(context, "/attendance"),
                  ),
                  _menuCard(
                    icon: Icons.supervised_user_circle_rounded,
                    label: "Người dùng",
                    onTap: () => Navigator.pushNamed(context, "/users"),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFEF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: Colors.black87),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Xem chi tiết & quản lý",
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

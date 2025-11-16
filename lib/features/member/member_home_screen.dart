import 'package:flutter/material.dart';
import 'package:gym_frontend/features/member/member_register_package_screen.dart';

class MemberHomeScreen extends StatelessWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ========================= HEADER =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 32,
                  bottom: 32,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      "Xin chào quý khách hàng!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onError,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2 NÚT ĐĂNG NHẬP / ĐĂNG KÝ
                    Row(
                      children: [
                        Expanded(
                          child: _headerButton(
                            colorScheme,
                            icon: Icons.fitness_center,
                            text: "Đăng ký gói tập",
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MemberRegisterPackageScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _headerButton(
                            colorScheme,
                            icon: Icons.shopping_cart_outlined,
                            text: "Mua dịch vụ",
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ========================= ICON FEATURE LIST =========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 20,
                  children: [
                    _featureItem(
                      icon: Icons.calendar_month,
                      label: "Đặt lịch tập luyện",
                      onTap: () {},
                    ),
                    _featureItem(
                      icon: Icons.person_pin,
                      label: "Đặt lịch HLV",
                      onTap: () {},
                    ),
                    _featureItem(
                      icon: Icons.event_note,
                      label: "Lịch học",
                      onTap: () {
                        Navigator.pushNamed(context, "/member/schedule");
                      },
                    ),

                    _featureItem(
                      icon: Icons.card_membership_outlined,
                      label: "Gói tập hiện tại",
                      onTap: () {
                        Navigator.pushNamed(context, "/member/current-package");
                      },
                    ),
                    _featureItem(
                      icon: Icons.local_offer,
                      label: "Mã giảm giá",
                      onTap: () {
                        Navigator.pushNamed(context, '/discounts/active');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ========================= CATEGORY BUTTONS =========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _categoryButton("Gym", colorScheme),
                    _categoryButton("Cycling", colorScheme),
                    _categoryButton("Yoga", colorScheme),
                    _categoryButton("Dance", colorScheme),
                    _categoryButton("GroupX", colorScheme),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ========================= BANNER =========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 160,
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Text(
                        "Banner quảng cáo",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // ========================= BOTTOM NAVIGATION =========================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorScheme.error,
          unselectedItemColor: Colors.grey.shade600,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: "Đặt lịch",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: "Quét mã",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: "Hộp thư",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Tài khoản",
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPONENTS
  // ============================================================

  Widget _headerButton(
    ColorScheme scheme, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFFFEAEA),
              child: Icon(icon, size: 28, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryButton(String text, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: scheme.onError,
        ),
      ),
    );
  }
}

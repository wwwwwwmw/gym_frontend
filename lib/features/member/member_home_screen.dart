import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_frontend/core/env.dart';
import 'package:gym_frontend/features/banners/banner_provider.dart';
import 'package:gym_frontend/features/member/member_register_package_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  // Khởi tạo page lớn để tạo cảm giác vòng lặp vô tận
  final PageController _pageController = PageController(initialPage: 1000);
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BannerProvider>().fetchHomeBanners().then((_) {
        _startAutoScroll();
      });
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _getImageUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    final base = apiBaseUrl();
    return '$base$relativePath';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Lấy chiều rộng màn hình để chia lưới cho đều
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 48) / 3; // Trừ padding 2 bên, chia 3 cột

    return Scaffold(
      backgroundColor: Colors.grey[50], // Màu nền xám rất nhạt cho sang
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================= HEADER =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.error.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Xin chào,",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Quý Hội Viên",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Avatar nhỏ hoặc icon thông báo góc phải
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Nút Đăng Ký Nổi Bật
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MemberRegisterPackageScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Đăng ký gói tập mới",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Nhận ưu đãi ngay hôm nay",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ========================= MAIN MENU (ĐÃ SỬA) =========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tiện ích của bạn",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Grid 3 cột gọn gàng
                    Wrap(
                      spacing: 12,
                      runSpacing: 20,
                      children: [
                        // --- HÀNG 1: QUẢN LÝ TẬP LUYỆN ---
                        _featureItem(
                          width: itemWidth,
                          icon: Icons.calendar_today,
                          color: Colors.blue,
                          label: "Lịch học",
                          onTap: () =>
                              Navigator.pushNamed(context, "/member/schedule"),
                        ),
                        _featureItem(
                          width: itemWidth,
                          icon: Icons.card_membership,
                          color: Colors.orange,
                          label: "Gói của tôi",
                          onTap: () => Navigator.pushNamed(
                            context,
                            "/member/current-package",
                          ),
                        ),
                        _featureItem(
                          width: itemWidth,
                          icon: Icons.person_pin_circle,
                          color: Colors.purple,
                          label: "HLV",
                          onTap: () =>
                              Navigator.pushNamed(context, "/trainers"),
                        ),

                        // --- HÀNG 2: DỊCH VỤ & ƯU ĐÃI ---
                        _featureItem(
                          width: itemWidth,
                          icon: Icons.storefront_outlined,
                          color: Colors.green,
                          label: "Mua gói tập",
                          onTap: () =>
                              Navigator.pushNamed(context, "/packages"),
                        ),
                        _featureItem(
                          width: itemWidth,
                          icon: Icons.local_offer_outlined,
                          color: Colors.pink,
                          label: "Khuyến mãi",
                          onTap: () =>
                              Navigator.pushNamed(context, '/discounts/active'),
                        ),
                        _featureItem(
                          width: itemWidth,
                          icon: Icons.receipt_long_outlined,
                          color: Colors.teal,
                          label: "Lịch sử",
                          onTap: () =>
                              Navigator.pushNamed(context, '/payments/history'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ========================= BANNER (VÒNG LẶP) =========================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Tin tức & Sự kiện",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              SizedBox(
                height: 160,
                child: Consumer<BannerProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.error,
                        ),
                      );
                    }
                    if (provider.homeBanners.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: Text("Chưa có banner")),
                      );
                    }
                    return PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index % provider.homeBanners.length;
                        });
                      },
                      itemBuilder: (context, index) {
                        final realIndex = index % provider.homeBanners.length;
                        final banner = provider.homeBanners[realIndex];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ), // Margin 2 bên để hở
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(
                                _getImageUrl(banner.imageUrl),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Indicator (Dấu chấm)
              const SizedBox(height: 10),
              Consumer<BannerProvider>(
                builder: (context, provider, _) {
                  if (provider.homeBanners.isEmpty) return const SizedBox();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(provider.homeBanners.length, (
                      index,
                    ) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index
                            ? 20
                            : 8, // Dấu chấm dài ra khi active
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? colorScheme.error
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // ========================= BOTTOM NAVBAR =========================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.05)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: colorScheme.error,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          showUnselectedLabels: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          onTap: (index) {
            if (index == 1)
              Navigator.pushNamed(
                context,
                '/member/schedule',
              ); // Calendar shortcut
            if (index == 2)
              Navigator.pushNamed(
                context,
                '/attendance/qr-scan',
              ); // QR shortcut
            if (index == 4)
              Navigator.pushNamed(
                context,
                '/member/profile',
              ); // Profile shortcut
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Trang chủ",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: "Lịch tập",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.error.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              ),
              label: "", // Nút giữa không cần label, chỉ cần icon nổi bật
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_outlined),
              label: "Hộp thư",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Tài khoản",
            ),
          ],
        ),
      ),
    );
  }

  // Widget Icon Feature đã được tinh chỉnh
  Widget _featureItem({
    required double width,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width - 10, // Trừ khoảng cách nhỏ để không bị tràn
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

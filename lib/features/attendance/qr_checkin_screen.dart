import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/features/member/member_service.dart';
import 'attendance_service.dart';
import 'attendance_model.dart';

class QrCheckInScreen extends StatefulWidget {
  const QrCheckInScreen({super.key});

  @override
  State<QrCheckInScreen> createState() => _QrCheckInScreenState();
}

class _QrCheckInScreenState extends State<QrCheckInScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQrCode(String raw) async {
    if (_processing) return;

    setState(() {
      _processing = true;
      _error = null;
      _successMessage = null;
    });

    try {
      // Parse QR data
      final data = jsonDecode(raw) as Map<String, dynamic>;

      if (data['type'] != 'attendance') {
        throw Exception('Mã QR không hợp lệ cho điểm danh');
      }

      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Mã QR thiếu token');
      }

      final endpoint = data['endpoint'] as String?;

      // Lấy member ID từ profile
      final memberService = MemberService(ApiClient(storage: TokenStorage()));
      final member = await memberService.getMyProfile();

      // Có thể dùng ID, email hoặc membershipNumber
      final memberIdentifier = member.id;

      // Check-in qua QR
      final attendanceService = AttendanceService(
        ApiClient(storage: TokenStorage()),
      );
      final attendance = await attendanceService.qrCheckIn(
        token: token,
        memberIdentifier: memberIdentifier,
        endpoint: endpoint,
      );

      if (!mounted) return;

      // Hiển thị kết quả thành công
      setState(() {
        _successMessage =
            'Check-in thành công!\n${attendance.memberName ?? ''}';
      });

      // Đợi 2 giây rồi đóng màn hình
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
      // Clear error sau 3 giây để có thể quét lại
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _error = null;
            _processing = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR điểm danh'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _handleQrCode(raw);
            },
          ),

          // Overlay hướng dẫn
          if (!_processing && _error == null && _successMessage == null)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Hướng dẫn
          if (!_processing && _error == null && _successMessage == null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đưa mã QR vào khung để điểm danh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (_processing && _error == null && _successMessage == null)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Success message
          if (_successMessage != null)
            Container(
              color: Colors.green.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _successMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error message
          if (_error != null)
            Container(
              color: Colors.red.withOpacity(0.9),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Quét lại sau 3 giây...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Torch/Flash button
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              onPressed: () => _controller.toggleTorch(),
              backgroundColor: Colors.white,
              child: Icon(Icons.flash_on, color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

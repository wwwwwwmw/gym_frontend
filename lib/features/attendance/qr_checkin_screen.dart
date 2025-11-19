import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/features/member/member_service.dart';
import 'attendance_service.dart';

class QrCheckInScreen extends StatefulWidget {
  const QrCheckInScreen({super.key});

  @override
  State<QrCheckInScreen> createState() => _QrCheckInScreenState();
}

class _QrCheckInScreenState extends State<QrCheckInScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  
  // Trạng thái hiển thị kết quả
  String? _error;
  String? _successMessage;
  String? _subMessage; // Dùng cho thông tin phụ (VD: thời gian tập)
  Color _statusColor = Colors.green;
  IconData _statusIcon = Icons.check_circle;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQrCode(String raw) async {
    if (_processing) return;
    if (raw.isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
      _successMessage = null;
      _subMessage = null;
    });

    try {
      final token = raw;

      // Refresh profile (optional)
      final memberService = MemberService(ApiClient(storage: TokenStorage()));
      await memberService.getMyProfile();

      final attendanceService = AttendanceService(
        ApiClient(storage: TokenStorage()),
      );

      // Gọi API (lấy về Map full data)
      final res = await attendanceService.checkInWithQr(token);
      
      final message = res['message'] as String? ?? 'Thành công!';
      final type = res['type'] as String? ?? 'CHECK_IN';
      final summary = res['workoutSummary'] as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        _successMessage = message;
        
        // Xử lý giao diện dựa trên TYPE trả về từ Server
        switch (type) {
          case 'CHECK_OUT':
            _statusColor = Colors.orange.shade800; // Màu cam cho Check-out
            _statusIcon = Icons.logout;
            if (summary != null) {
               final minutes = summary['durationMinutes'];
               _subMessage = 'Tổng thời gian: $minutes phút';
            }
            break;
            
          case 'WARNING_TOO_SOON':
            _statusColor = Colors.amber.shade700; // Màu vàng cảnh báo
            _statusIcon = Icons.warning_amber_rounded;
            break;
            
          case 'CHECK_IN':
          default:
            _statusColor = Colors.green.shade700; // Màu xanh mặc định
            _statusIcon = Icons.check_circle;
            break;
        }
      });

      // Đợi lâu hơn xíu (2.5s) để người dùng kịp đọc thông báo
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
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

          // Khung ngắm (Overlay) - Ẩn khi đang hiện kết quả
          if (!_processing && _error == null && _successMessage == null)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.5),
                       spreadRadius: 1000, // Làm tối phần xung quanh
                     )
                  ]
                ),
              ),
            ),

          // Hướng dẫn text
          if (!_processing && _error == null && _successMessage == null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Đưa mã QR vào khung để Check-in / Check-out',
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

          // Success/Info/Warning Message Overlay
          if (_successMessage != null)
            Container(
              color: _statusColor.withOpacity(0.95), // Dùng màu động
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon, // Icon động
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _successMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_subMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                            _subMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),

          // Error message overlay
          if (_error != null)
            Container(
              color: Colors.red.withOpacity(0.95),
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
                        'Thử lại sau 3 giây...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Nút bật đèn Flash
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
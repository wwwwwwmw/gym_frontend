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
  bool _cameraInitialized = false;
  String? _cameraError;
  
  // ✅ Thêm debounce để tránh quét QR liên tục
  DateTime? _lastScanTime;
  String? _lastScannedCode;
  static const Duration _scanCooldown = Duration(seconds: 3); // Cooldown 3 giây giữa các lần quét
  
  // Trạng thái hiển thị kết quả
  String? _error;
  String? _successMessage;
  String? _subMessage; // Dùng cho thông tin phụ (VD: thời gian tập)
  Color _statusColor = Colors.green;
  IconData _statusIcon = Icons.check_circle;

  @override
  void initState() {
    super.initState();
    // ✅ Khởi động camera khi màn hình được tạo
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // ✅ Start camera
      await _controller.start();
      
      // Đợi một chút để camera khởi động hoàn toàn
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _cameraInitialized = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Không thể khởi động camera';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('permission')) {
          errorMsg = 'Vui lòng cấp quyền truy cập camera trong Cài đặt';
        } else if (errorStr.contains('camera')) {
          errorMsg = 'Không thể truy cập camera. Vui lòng kiểm tra lại.';
        } else {
          errorMsg = 'Lỗi camera: ${e.toString()}';
        }
        
        setState(() {
          _cameraInitialized = false;
          _cameraError = errorMsg;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQrCode(String raw) async {
    // ✅ Kiểm tra debounce: Không cho quét liên tục
    if (_processing) {
      return; // Đang xử lý, bỏ qua
    }
    
    if (raw.isEmpty) return;
    
    // ✅ Kiểm tra cooldown: Nếu vừa quét gần đây (< 3 giây) và cùng mã QR, bỏ qua
    final now = DateTime.now();
    if (_lastScanTime != null && 
        _lastScannedCode == raw &&
        now.difference(_lastScanTime!) < _scanCooldown) {
      // Đang trong cooldown, bỏ qua
      return;
    }
    
    // ✅ Lưu thời gian và mã QR vừa quét
    _lastScanTime = now;
    _lastScannedCode = raw;

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
      
      // ✅ Kiểm tra success flag từ response
      if (res['success'] == false) {
        throw Exception(res['message'] as String? ?? 'Thao tác thất bại');
      }
      
      final message = res['message'] as String? ?? 'Thành công!';
      final type = res['type'] as String? ?? 'CHECK_IN';
      final summary = res['workoutSummary'] as Map<String, dynamic>?;
      final remaining = res['remainingSessionsLeft'] as int?;
      // final packageType = res['packageType'] as String?; // Loại gói: "session" hoặc "daily" (có thể dùng sau)

      if (!mounted) return;

      setState(() {
        _successMessage = message;
        _processing = false; // ✅ Reset processing state khi thành công
        
        // Xử lý giao diện dựa trên TYPE trả về từ Server
        switch (type) {
          case 'CHECK_OUT':
            _statusColor = Colors.orange.shade800; // Màu cam cho Check-out
            _statusIcon = Icons.logout;
            if (summary != null) {
               final minutes = summary['durationMinutes'];
               final sessionsText = remaining != null
                   ? ' · Số buổi còn lại: $remaining'
                   : '';
               _subMessage = 'Tổng thời gian: $minutes phút$sessionsText';
            } else if (remaining != null) {
               _subMessage = 'Số buổi còn lại: $remaining';
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
            // Hiển thị thông tin buổi còn lại cho gói theo buổi
            if (remaining != null) {
              _subMessage = 'Số buổi còn lại: $remaining';
            }
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
        // ✅ Cải thiện xử lý lỗi: Extract message từ exception và làm thân thiện hơn
        String errorMessage = 'Đã xảy ra lỗi';
        try {
          final errorStr = e.toString();
          
          // Thử extract message từ format "Exception: message" hoặc "Error: message"
          String rawMessage = errorStr;
          if (errorStr.contains('Exception: ')) {
            rawMessage = errorStr.split('Exception: ').last;
          } else if (errorStr.contains('Error: ')) {
            rawMessage = errorStr.split('Error: ').last;
          }
          
          // ✅ Làm thông báo thân thiện hơn
          if (rawMessage.contains('đã sử dụng buổi tập hôm nay')) {
            errorMessage = 'Bạn đã sử dụng buổi tập hôm nay rồi.\nGói tập theo buổi chỉ cho phép 1 buổi/ngày.';
          } else if (rawMessage.contains('đang trong buổi tập')) {
            errorMessage = 'Bạn đang trong buổi tập.\nVui lòng check-out trước khi bắt đầu buổi tập mới.';
          } else if (rawMessage.contains('không có gói tập đang hoạt động')) {
            errorMessage = 'Bạn chưa có gói tập đang hoạt động.\nVui lòng đăng ký gói tập trước khi check-in.';
          } else if (rawMessage.contains('đã hết số buổi')) {
            errorMessage = 'Gói tập của bạn đã hết số buổi.\nVui lòng đăng ký gói tập mới.';
          } else if (rawMessage.contains('đã check-in rồi')) {
            errorMessage = 'Bạn đã check-in rồi.\nVui lòng check-out trước khi check-in lại.';
          } else {
            errorMessage = rawMessage;
          }
        } catch (_) {
          errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
        }
        
        setState(() {
          _error = errorMessage;
          _processing = false; // ✅ Reset processing state ngay khi có lỗi
        });
        
        // ✅ Tự động ẩn lỗi sau 5 giây (tăng từ 3 giây) và cho phép quét lại
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _error = null;
              // Reset last scan time để cho phép quét lại
              _lastScanTime = null;
              _lastScannedCode = null;
            });
          }
        });
      }
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
          // Camera scanner - Chỉ hiển thị khi camera đã khởi động và không đang xử lý
          if (_cameraInitialized && _cameraError == null && !_processing)
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                // ✅ Chỉ xử lý khi không đang processing
                if (_processing) return;
                
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final raw = barcodes.first.rawValue;
                if (raw == null || raw.isEmpty) return;
                
                _handleQrCode(raw);
              },
            )
          else if (_cameraError != null)
            // Hiển thị lỗi camera
            Container(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 80,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _cameraError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _initializeCamera();
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Loading camera
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Đang khởi động camera...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
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
                          height: 1.5, // ✅ Tăng line height để dễ đọc hơn
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Vui lòng đợi 5 giây trước khi quét lại...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _lastScanTime = null;
                            _lastScannedCode = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Đóng'),
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
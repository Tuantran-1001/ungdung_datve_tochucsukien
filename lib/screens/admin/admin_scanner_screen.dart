import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/settings_service.dart';

class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({super.key});

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen> {
  bool _isProcessing = false;
  final TextEditingController _manualController = TextEditingController();
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _processTicket(String ticketId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('id', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isEmpty) {
        await _showResultDialog(
          icon: Icons.error_outline,
          color: Colors.red,
          title: AppSettings.isEnglish ? 'Invalid QR code!' : 'Mã QR không hợp lệ!',
          subtitle: AppSettings.isEnglish
              ? 'No ticket found with this code.'
              : 'Không tìm thấy vé với mã này.',
        );
      } else {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final status = data['status'] ?? '';

        if (status == 'Chưa sử dụng') {
          await doc.reference.update({'status': 'Đã check-in'});

          if (!mounted) return;

          final eventTitle = data['eventTitle'] ?? data['event_title'] ?? '';
          final seatNumber = data['seatNumber'] ?? data['seat_number'] ?? '';

          await _showResultDialog(
            icon: Icons.check_circle_outline,
            color: Colors.green,
            title: 'Check-in thành công!',
            subtitle: eventTitle.toString().isNotEmpty
                ? '${AppSettings.isEnglish ? 'Event' : 'Sự kiện'}: $eventTitle\n'
                  '${AppSettings.isEnglish ? 'Seat' : 'Ghế'}: $seatNumber'
                : '',
          );
        } else if (status == 'Đã check-in') {
          await _showResultDialog(
            icon: Icons.warning_amber_outlined,
            color: Colors.orange,
            title: AppSettings.isEnglish
                ? 'Ticket already used!'
                : 'Vé đã được sử dụng!',
            subtitle: AppSettings.isEnglish
                ? 'This ticket has already been checked in.'
                : 'Vé này đã được check-in trước đó.',
          );
        } else {
          await _showResultDialog(
            icon: Icons.info_outline,
            color: Colors.blue,
            title: AppSettings.isEnglish ? 'Invalid status' : 'Trạng thái không hợp lệ',
            subtitle: '${AppSettings.isEnglish ? 'Current status' : 'Trạng thái hiện tại'}: $status',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      await _showResultDialog(
        icon: Icons.error_outline,
        color: Colors.red,
        title: AppSettings.isEnglish ? 'Error' : 'Lỗi',
        subtitle: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showResultDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = AppSettings.isDark;
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 64),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showManualInputDialog() {
    _manualController.clear();
    final isDark = AppSettings.isDark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppSettings.isEnglish ? 'Enter Ticket ID' : 'Nhập mã vé',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: TextField(
            controller: _manualController,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: AppSettings.isEnglish ? 'Ticket ID...' : 'Mã vé...',
              hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppSettings.isEnglish ? 'Cancel' : 'Hủy',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final ticketId = _manualController.text.trim();
                Navigator.of(ctx).pop();
                if (ticketId.isNotEmpty) {
                  _processTicket(ticketId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(AppSettings.isEnglish ? 'Check' : 'Kiểm tra'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.languageNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettings.themeNotifier,
          builder: (context, themeMode, _) {
            final isDark = themeMode == ThemeMode.dark;

            return Scaffold(
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
              appBar: AppBar(
                title: Text(
                  AppSettings.translate('qr_scanner'),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                iconTheme: IconThemeData(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                elevation: 1,
              ),
              body: Stack(
                children: [
                  // Scanner area - takes most of the screen
                  Positioned.fill(
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null && !_isProcessing) {
                            _processTicket(barcode.rawValue!);
                          }
                        }
                      },
                    ),
                  ),

                  // Scan overlay frame
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScanOverlayPainter(
                        borderColor: isDark ? Colors.white70 : Colors.white,
                      ),
                    ),
                  ),

                  // Processing indicator
                  if (_isProcessing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),

                  // Instruction text at top
                  Positioned(
                    top: 32,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lang == 'en'
                            ? 'Point camera at QR code to scan'
                            : 'Hướng camera vào mã QR để quét',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  // Manual input button at the bottom
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: SafeArea(
                      child: ElevatedButton.icon(
                        onPressed: _showManualInputDialog,
                        icon: const Icon(Icons.keyboard, size: 20),
                        label: Text(
                          lang == 'en' ? 'Manual Input' : 'Nhập thủ công',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Color borderColor;

  _ScanOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.65;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2 - 30;
    final Rect scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Dark overlay outside scan area
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final scanPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, scanPath);

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Corner lines
    const double cornerLength = 30;
    const double cornerWidth = 4;
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double r = 16;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLength)
        ..lineTo(scanRect.left, scanRect.top + r)
        ..quadraticBezierTo(scanRect.left, scanRect.top, scanRect.left + r, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right - r, scanRect.top)
        ..quadraticBezierTo(scanRect.right, scanRect.top, scanRect.right, scanRect.top + r)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.left, scanRect.bottom - r)
        ..quadraticBezierTo(scanRect.left, scanRect.bottom, scanRect.left + r, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
        ..lineTo(scanRect.right - r, scanRect.bottom)
        ..quadraticBezierTo(scanRect.right, scanRect.bottom, scanRect.right, scanRect.bottom - r)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/db_helper.dart';

class TicketViewScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const TicketViewScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Nền Gradient cao cấp mang lại chiều sâu huyền ảo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0C20), // Xanh đen sâu thẳm
                  Color(0xFF15102A), // Chàm đậm
                  Color(0xFF090615), // Đen vũ trụ
                ],
              ),
            ),
          ),

          // 2. Các đốm sáng Ambient Glow mềm mại
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.amber.withOpacity(0.1),
                    Colors.amber.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepOrange.withOpacity(0.08),
                    Colors.deepOrange.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Nội dung chính
          SafeArea(
            child: Column(
              children: [
                // Custom Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Vé Điện Tử (E-Ticket)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Để cân bằng với nút back
                    ],
                  ),
                ),

                // Thẻ Vé Premium
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A3C).withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'VÉ VÀO CỬA CHÍNH THỨC',
                            style: TextStyle(
                              letterSpacing: 2.0,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ticket['eventTitle'] ?? 'Sự kiện',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ticket['eventDate']?.split(' ')?.first ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          
                          // Phân cách nét đứt giả lập
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Row(
                              children: List.generate(
                                15,
                                (index) => Expanded(
                                  child: Container(
                                    color: index % 2 == 0 ? Colors.transparent : Colors.white.withOpacity(0.15),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Khung QR Code phát sáng hổ phách
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: QrImageView(
                              data: ticket['id'] ?? 'Mã vé',
                              version: QrVersions.auto,
                              size: 180.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF0F0C20),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF0F0C20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Mã vé: ${ticket['id']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Row(
                              children: List.generate(
                                15,
                                (index) => Expanded(
                                  child: Container(
                                    color: index % 2 == 0 ? Colors.transparent : Colors.white.withOpacity(0.15),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Chi tiết thông tin vé
                          _buildDetailRow(Icons.calendar_today_rounded, 'Thời gian', ticket['eventDate']),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.location_on_rounded, 'Địa điểm', ticket['eventLocation']),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.chair_alt_rounded, 'Vị trí ghế', ticket['seatNumber'], isHighlight: true),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.info_outline_rounded, 
                            'Trạng thái', 
                            ticket['status'], 
                            statusColor: ticket['status'] == 'Đã check-in' ? Colors.greenAccent : Colors.redAccent
                          ),

                          if (ticket['status'] != 'Đã check-in') ...[
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.green.withOpacity(0.3),
                                ),
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                                label: const Text(
                                  'QUÉT MÃ KIỂM SOÁT TẠI CỬA',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                                ),
                                onPressed: () async {
                                  await DbHelper.instance.checkInTicket(ticket['id']);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Xác thực quét thành công! Vé đã được Check-In.'), 
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isHighlight = false, Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.amber),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: statusColor ?? (isHighlight ? Colors.amberAccent : Colors.white),
              fontWeight: (isHighlight || statusColor != null) ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
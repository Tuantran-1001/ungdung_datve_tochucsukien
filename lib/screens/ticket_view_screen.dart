import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/db_helper.dart';

class TicketViewScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const TicketViewScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vé Điện Tử (E-Ticket)'), backgroundColor: Colors.amber),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.4), blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('VÉ VÀO CỬA CHÍNH THỨC', style: TextStyle(letterSpacing: 1.5, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(ticket['eventTitle'] ?? 'Sự kiện', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(height: 30),

              QrImageView(
                data: ticket['id'] ?? 'Mã vé',
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 8),
              Text('Mã vé: ${ticket['id']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              Text('Thời gian: ${ticket['eventDate']}'),
              Text('Địa điểm: ${ticket['eventLocation']}', textAlign: TextAlign.center),
              Text('Vị trí ghế: ${ticket['seatNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 10),
              Text('Trạng thái: ${ticket['status']}', style: TextStyle(fontWeight: FontWeight.bold, color: ticket['status'] == 'Đã check-in' ? Colors.green : Colors.red)),

              if (ticket['status'] != 'Đã check-in') ...[
                const Divider(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('QUÉT MÃ KIỂM SOÁT TẠI CỬA'),
                  onPressed: () async {
                    await DbHelper.instance.checkInTicket(ticket['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xác thực quét thành công! Vé đã được Check-In.'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  },
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
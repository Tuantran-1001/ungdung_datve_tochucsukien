import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../main.dart'; // Thêm dòng này để nhận diện được lớp MainNavigation

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String _selectedSeat = 'A1'; // Mặc định chọn ghế A1

  void _processBooking() async {
    final String ticketId = 'EP-${widget.event['id']}-${DateTime.now().millisecondsSinceEpoch % 10000}';

    await DbHelper.instance.insertTicket({
      'id': ticketId,
      'eventId': widget.event['id'],
      'eventTitle': widget.event['title'],
      'eventDate': widget.event['date'],
      'eventLocation': widget.event['location'],
      'seatNumber': _selectedSeat,
      'status': 'Chưa sử dụng',
    });

    // Đảm bảo Widget vẫn còn mount trong cây trước khi dùng BuildContext bất đồng bộ
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đặt vé thành công! Vé đã lưu vào kho.'), backgroundColor: Colors.green),
    );

    Navigator.pushAndRemoveUntil(
      context,
      // Đã loại bỏ các dòng chữ ghi chú bị gõ nhầm lồng vào code
      // Đã XÓA chữ "const" trước MainNavigation() để sửa triệt để lỗi "Not a constant expression"
      MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi Tiết Sự Kiện'), backgroundColor: Colors.amber),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(widget.event['imageUrl'], height: 220, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.event['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Thời gian: ${widget.event['date']}', style: const TextStyle(fontSize: 15, color: Colors.blueGrey)),
                  Text('Địa điểm: ${widget.event['location']}', style: const TextStyle(fontSize: 15, color: Colors.blueGrey)),
                  const Divider(height: 30),
                  const Text('Giới thiệu:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(widget.event['description'], style: const TextStyle(fontSize: 15, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${widget.event['price'].toStringAsFixed(0)} VND', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: _processBooking,
              child: const Text('ĐẶT VÉ NGAY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import 'ticket_view_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final data = await DbHelper.instance.queryAllTickets();
    setState(() {
      _tickets = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vé Đã Đặt'), backgroundColor: Colors.amber, centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
          ? const Center(child: Text('Bạn chưa sở hữu tấm vé nào.'))
          : ListView.builder(
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];

          // Giả lập tính năng nhắc nhở (Yêu cầu 6)
          bool isUpcoming = index == 0; // Giả lập phần tử đầu sắp diễn ra

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.qr_code_2, size: 40, color: Colors.amber),
              title: Text(ticket['eventTitle'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thời gian: ${ticket['eventDate']}\nGhế: ${ticket['seatNumber']} | Trạng thái: ${ticket['status']}'),
                  if (isUpcoming && ticket['status'] == 'Chưa sử dụng')
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                      child: const Text('⚠️ Sắp diễn ra!', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TicketViewScreen(ticket: ticket)),
                ).then((_) => _loadTickets());
              },
            ),
          );
        },
      ),
    );
  }
}
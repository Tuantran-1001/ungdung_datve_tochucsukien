import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import 'ticket_view_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Luôn ưu tiên hiển thị trạng thái tải nếu danh sách trống để tăng trải nghiệm người dùng
    if (_tickets.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    List<Map<String, dynamic>> ticketsList = [];

    // 1. Tải dữ liệu từ SQLite cục bộ trước (Offline-First)
    try {
      final localData = await DbHelper.instance.queryAllTickets(userId ?? 'anonymous');
      ticketsList = List<Map<String, dynamic>>.from(localData);
    } catch (e) {
      debugPrint('Error loading local tickets: $e');
    }

    // Cập nhật giao diện nhanh với dữ liệu cục bộ trước để tránh trễ
    if (mounted) {
      setState(() {
        _tickets = List.from(ticketsList);
        if (userId == null) _isLoading = false;
      });
    }

    // 2. Đồng bộ hóa kéo dữ liệu vé đám mây từ Firebase Firestore (nếu đã đăng nhập)
    if (userId != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: userId)
            .get();

        final List<Map<String, dynamic>> cloudTickets = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': data['id'] ?? doc.id,
            'userId': userId,
            'eventId': data['eventId'] ?? '',
            'eventTitle': data['eventTitle'] ?? '',
            'eventDate': data['eventDate'] ?? '',
            'eventLocation': data['eventLocation'] ?? '',
            'seatNumber': data['seatNumber'] ?? '',
            'status': data['status'] ?? 'Chưa sử dụng',
            'bookingTime': data['bookingTime'] ?? '',
          };
        }).toList();

        // Hợp nhất thông tin từ đám mây (tránh trùng lặp vé)
        bool hasChanges = false;
        for (var cloudTicket in cloudTickets) {
          final exists = ticketsList.any((t) => t['id'] == cloudTicket['id']);
          if (!exists) {
            ticketsList.add(cloudTicket);
            hasChanges = true;
            // Đồng bộ ngược lại lưu xuống SQLite cục bộ để có thể xem offline
            try {
              await DbHelper.instance.insertTicket(cloudTicket);
            } catch (e) {
              debugPrint('Error sync-saving cloud ticket to local: $e');
            }
          } else {
            // Đồng bộ cập nhật trạng thái nếu đã check-in trên đám mây
            final localIndex = ticketsList.indexWhere((t) => t['id'] == cloudTicket['id']);
            if (localIndex != -1 && ticketsList[localIndex]['status'] != cloudTicket['status']) {
              ticketsList[localIndex] = Map<String, dynamic>.from(ticketsList[localIndex]);
              ticketsList[localIndex]['status'] = cloudTicket['status'];
              hasChanges = true;
            }
          }
        }

        if (hasChanges && mounted) {
          ticketsList.sort((a, b) => (b['id'] ?? '').toString().compareTo((a['id'] ?? '').toString()));
          setState(() {
            _tickets = ticketsList;
          });
        }
      } catch (e) {
        debugPrint('Error syncing tickets from Firestore: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.amber.withOpacity(0.12),
                    Colors.amber.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepOrange.withOpacity(0.1),
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
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.confirmation_num_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Vé Đã Đặt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Nội dung danh sách
                Expanded(
                  child: RefreshIndicator(
                    color: Colors.amber,
                    backgroundColor: const Color(0xFF1E1A3C),
                    onRefresh: _loadTickets,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.amber,
                            ),
                          )
                        : _tickets.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.receipt_long_outlined,
                                            size: 80,
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Bạn chưa sở hữu tấm vé nào.',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Kéo xuống để làm mới danh sách',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.3),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(bottom: 24, top: 8),
                                itemCount: _tickets.length,
                                itemBuilder: (context, index) {
                                final ticket = _tickets[index];

                                // Giả lập tính năng nhắc nhở (Yêu cầu 6)
                                bool isUpcoming = index == 0; // Giả lập phần tử đầu sắp diễn ra

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1A3C).withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        highlightColor: Colors.amber.withOpacity(0.1),
                                        splashColor: Colors.amber.withOpacity(0.1),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.amber.withOpacity(0.05),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              )
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 30,
                                            color: Colors.amber,
                                          ),
                                        ),
                                        title: Text(
                                          ticket['eventTitle'] ?? 'Sự kiện',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 13,
                                                  color: Colors.white.withOpacity(0.5),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Thời gian: ${ticket['eventDate']}',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.chair_alt_rounded,
                                                  size: 13,
                                                  color: Colors.white.withOpacity(0.5),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Ghế: ${ticket['seatNumber']}',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: ticket['status'] == 'Đã check-in'
                                                        ? Colors.greenAccent.withOpacity(0.12)
                                                        : Colors.amber.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: ticket['status'] == 'Đã check-in'
                                                          ? Colors.greenAccent.withOpacity(0.2)
                                                          : Colors.amber.withOpacity(0.2),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    ticket['status'] ?? 'Chưa sử dụng',
                                                    style: TextStyle(
                                                      color: ticket['status'] == 'Đã check-in'
                                                          ? Colors.greenAccent
                                                          : Colors.amber,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isUpcoming && ticket['status'] == 'Chưa sử dụng') ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.redAccent.withOpacity(0.3),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.warning_amber_rounded,
                                                      color: Colors.redAccent,
                                                      size: 13,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Sắp diễn ra!',
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TicketViewScreen(ticket: ticket),
                                            ),
                                          ).then((_) => _loadTickets());
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
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
}
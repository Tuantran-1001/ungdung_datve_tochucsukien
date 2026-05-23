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
    if (_tickets.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    List<Map<String, dynamic>> ticketsList = [];

    try {
      final localData = await DbHelper.instance.queryAllTickets(userId ?? 'anonymous');
      ticketsList = List<Map<String, dynamic>>.from(localData);
    } catch (e) {
      debugPrint('Error loading local tickets: $e');
    }

    if (mounted) {
      setState(() {
        _tickets = List.from(ticketsList);
        if (userId == null) _isLoading = false;
      });
    }

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

        bool hasChanges = false;
        for (var cloudTicket in cloudTickets) {
          final exists = ticketsList.any((t) => t['id'] == cloudTicket['id']);
          if (!exists) {
            ticketsList.add(cloudTicket);
            hasChanges = true;
            try {
              await DbHelper.instance.insertTicket(cloudTicket);
            } catch (e) {
              debugPrint('Error sync-saving cloud ticket to local: $e');
            }
          } else {
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header đơn giản
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_num_rounded, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Vé Đã Đặt',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: Colors.blue,
                backgroundColor: Colors.white,
                onRefresh: _loadTickets,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue,
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
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Bạn chưa sở hữu tấm vé nào.',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Kéo xuống để làm mới danh sách',
                                        style: TextStyle(
                                          color: Colors.grey[500],
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
                              bool isUpcoming = index == 0; // Giả lập phần tử đầu sắp diễn ra

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: Colors.white,
                                elevation: 2,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 30,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  title: Text(
                                    ticket['eventTitle'] ?? 'Sự kiện',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
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
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Thời gian: ${ticket['eventDate']}',
                                              style: TextStyle(
                                                color: Colors.grey[700],
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
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Ghế: ${ticket['seatNumber']}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: ticket['status'] == 'Đã check-in'
                                                  ? Colors.green.withOpacity(0.12)
                                                  : Colors.blue.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: ticket['status'] == 'Đã check-in'
                                                    ? Colors.green.withOpacity(0.2)
                                                    : Colors.blue.withOpacity(0.2),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              ticket['status'] ?? 'Chưa sử dụng',
                                              style: TextStyle(
                                                color: ticket['status'] == 'Đã check-in'
                                                    ? Colors.green
                                                    : Colors.blue,
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
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(0.2),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 13,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Sắp diễn ra!',
                                                style: TextStyle(
                                                  color: Colors.red,
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
                                    color: Colors.grey[400],
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
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
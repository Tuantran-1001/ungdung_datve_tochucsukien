import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/settings_service.dart';

class AdminEventSeatsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const AdminEventSeatsScreen({
    super.key,
    required this.event,
  });

  @override
  State<AdminEventSeatsScreen> createState() => _AdminEventSeatsScreenState();
}

class _AdminEventSeatsScreenState extends State<AdminEventSeatsScreen> {
  // Thay đổi trạng thái sử dụng của vé (Đã sử dụng <=> Chưa sử dụng)
  Future<void> _toggleTicketStatus(String ticketId, String currentStatus) async {
    final String newStatus = currentStatus == 'Chưa sử dụng' ? 'Đã sử dụng' : 'Chưa sử dụng';
    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(ticketId)
          .update({'status': newStatus});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái vé sang: $newStatus'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật trạng thái thất bại: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Hủy vé đặt (Giải phóng ghế ngồi)
  Future<void> _deleteTicket(BuildContext context, String ticketId, String seatNumber) async {
    final isEn = AppSettings.languageNotifier.value == 'en';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = AppSettings.themeNotifier.value == ThemeMode.dark;
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEn ? 'Cancel Booking' : 'Hủy đặt vé',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isEn 
                ? 'Are you sure you want to cancel the booking for seat "$seatNumber"? This will release the seat.'
                : 'Bạn có chắc chắn muốn hủy đặt vé cho ghế "$seatNumber" không? Thao tác này sẽ giải phóng ghế ngồi.',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                isEn ? 'Close' : 'Đóng',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                isEn ? 'Confirm' : 'Xác nhận hủy',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('tickets')
            .doc(ticketId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn ? 'Successfully cancelled ticket.' : 'Đã hủy vé và giải phóng ghế thành công.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting ticket: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEn ? 'Failed to cancel: $e' : 'Hủy vé thất bại: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String eventId = widget.event['originalIdField'] ?? widget.event['id'] ?? '';
    final String eventTitle = widget.event['title'] ?? '';
    final String eventDate = widget.event['date'] ?? '';

    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.languageNotifier,
      builder: (context, lang, _) {
        final isEn = lang == 'en';

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettings.themeNotifier,
          builder: (context, themeMode, _) {
            final isDark = themeMode == ThemeMode.dark;

            return Scaffold(
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
              appBar: AppBar(
                elevation: 0,
                backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: isDark ? Colors.white : Colors.black87, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  isEn ? 'Manage Seats' : 'Quản Lý Ghế Ngồi',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event summary panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              eventDate,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Real-time seats list
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tickets')
                          .where('eventId', isEqualTo: eventId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              isEn ? 'Error loading booked seats' : 'Lỗi khi tải danh sách ghế đặt',
                              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_seat_outlined,
                                  size: 64,
                                  color: isDark ? Colors.grey[750] : Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isEn ? 'No seats booked yet' : 'Chưa có ghế nào được đặt',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Sắp xếp vé theo mã số ghế ngồi (A1, A2, B1...)
                        final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
                        sortedDocs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final String aSeat = aData['seatNumber'] ?? '';
                          final String bSeat = bData['seatNumber'] ?? '';
                          return aSeat.compareTo(bSeat);
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                              child: Text(
                                '${isEn ? "Booked count" : "Tổng số ghế đã đặt"}: ${sortedDocs.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: sortedDocs.length,
                                itemBuilder: (context, index) {
                                  final doc = sortedDocs[index];
                                  final Map<String, dynamic> ticket = doc.data() as Map<String, dynamic>;
                                  final String ticketId = doc.id;
                                  final String seatNumber = ticket['seatNumber'] ?? 'Chưa rõ';
                                  final String userId = ticket['userId'] ?? 'anonymous';
                                  final String status = ticket['status'] ?? 'Chưa sử dụng';
                                  final String bookingTime = ticket['bookingTime'] ?? 'Chưa rõ';

                                  final bool isUsed = status == 'Đã sử dụng';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    color: isDark ? Colors.grey[850] : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          // Seat Badge
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isUsed 
                                                  ? Colors.grey.withOpacity(0.12)
                                                  : Colors.blue.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                seatNumber,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isUsed ? Colors.grey : Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Ticket details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'User ID: $userId',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${isEn ? "Time" : "Đặt lúc"}: $bookingTime',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),

                                                // Status indicator chip
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isUsed 
                                                        ? Colors.green.withOpacity(0.12)
                                                        : Colors.orange.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isUsed ? Colors.green : Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Action Buttons
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Toggle status button
                                              IconButton(
                                                icon: Icon(
                                                  isUsed 
                                                      ? Icons.check_circle_rounded 
                                                      : Icons.radio_button_unchecked_rounded,
                                                  color: isUsed ? Colors.green : Colors.grey[500],
                                                  size: 22,
                                                ),
                                                tooltip: isEn ? 'Toggle utilization status' : 'Đổi trạng thái sử dụng',
                                                onPressed: () => _toggleTicketStatus(ticketId, status),
                                              ),
                                              
                                              // Delete booking button
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.redAccent,
                                                  size: 22,
                                                ),
                                                tooltip: isEn ? 'Cancel booking' : 'Hủy đặt vé',
                                                onPressed: () => _deleteTicket(context, ticketId, seatNumber),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
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

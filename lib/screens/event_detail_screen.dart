import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final List<String> _selectedSeats = [];
  List<String> _bookedSeats = [];
  bool _isLoadingBookedSeats = true;

  @override
  void initState() {
    super.initState();
    _fetchBookedSeats();
  }

  Future<void> _fetchBookedSeats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('eventId', isEqualTo: widget.event['id'])
          .get();

      final List<String> booked = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String? seat = data['seatNumber'];
        if (seat != null && seat.isNotEmpty) {
          if (seat.contains(',')) {
            final parts = seat.split(',').map((s) => s.trim()).toList();
            for (var p in parts) {
              if (!booked.contains(p)) {
                booked.add(p);
              }
            }
          } else {
            if (!booked.contains(seat)) {
              booked.add(seat);
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _bookedSeats = booked;
          _isLoadingBookedSeats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching booked seats: $e');
      if (mounted) {
        setState(() {
          _bookedSeats = [];
          _isLoadingBookedSeats = false;
        });
      }
    }
  }

  void _processBooking() {
    if (_selectedSeats.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          event: widget.event,
          selectedSeats: _selectedSeats,
        ),
      ),
    ).then((_) {
      // Làm mới danh sách ghế đã đặt sau khi quay lại từ màn hình thanh toán
      setState(() {
        _isLoadingBookedSeats = true;
        _selectedSeats.clear(); // Xóa các ghế vừa chọn để tránh chọn trùng
      });
      _fetchBookedSeats();
    });
  }

  Widget _buildLegendItem(String label, Color bgColor, Color borderColor, bool isBooked) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: isBooked
              ? Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 8,
                    color: Colors.white.withOpacity(0.2),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
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
            top: 250,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.amber.withOpacity(0.08),
                    Colors.amber.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepOrange.withOpacity(0.06),
                    Colors.deepOrange.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Nội dung chính cuộn mượt mà
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phần ảnh sự kiện với đốm mờ gradient
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      child: Image.network(
                        widget.event['imageUrl'] ?? '',
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 280,
                            color: const Color(0xFF1E1A3C),
                            child: const Center(
                              child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                    // Lớp phủ Gradient mờ ở chân ảnh
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              const Color(0xFF0F0C20).withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Nút Back tròn premium
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0C20).withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),

                // Chi tiết nội dung
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề sự kiện
                      Text(
                        widget.event['title'] ?? 'Sự kiện',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Hộp thông tin thời gian & địa điểm sang trọng
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_today_rounded, color: Colors.amber, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Thời gian', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  widget.event['date'] ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Colors.amber, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Địa điểm', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  widget.event['location'] ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: Colors.white10),
                      ),

                      // Chọn Vị Trí Ghế - Sơ đồ ghế rạp chiếu phim (Cinema Seat Map Grid)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A3C).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.chair_alt_rounded, color: Colors.amber, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Sơ đồ ghế ngồi rạp phim:',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isLoadingBookedSeats)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.amber,
                                  ),
                                ),
                              )
                            else ...[
                              // MÀN HÌNH SÂN KHẤU
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      height: 5,
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.amber.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'MÀN HÌNH SÂN KHẤU',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // LƯỚI GHẾ 2D (5 hàng x 6 cột)
                              Column(
                                children: [
                                  for (String row in ['A', 'B', 'C', 'D', 'E'])
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            child: Text(
                                              row,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.4),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          for (String col in ['1', '2', '3', '4', '5', '6'])
                                            Builder(
                                              builder: (context) {
                                                final String seatId = '$row$col';
                                                final bool isBooked = _bookedSeats.contains(seatId);
                                                final bool isSelected = _selectedSeats.contains(seatId);

                                                return GestureDetector(
                                                  onTap: () {
                                                    if (isBooked) return;
                                                    setState(() {
                                                      if (isSelected) {
                                                        _selectedSeats.remove(seatId);
                                                      } else {
                                                        _selectedSeats.add(seatId);
                                                      }
                                                    });
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? Colors.amber
                                                          : isBooked
                                                              ? Colors.white.withOpacity(0.04)
                                                              : const Color(0xFF1E1A3C).withOpacity(0.4),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? Colors.amber
                                                            : isBooked
                                                                ? Colors.white.withOpacity(0.02)
                                                                : Colors.white.withOpacity(0.1),
                                                        width: 1,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: Colors.amber.withOpacity(0.3),
                                                                blurRadius: 6,
                                                                spreadRadius: 1,
                                                              )
                                                            ]
                                                          : null,
                                                    ),
                                                    child: Center(
                                                      child: isBooked
                                                          ? Icon(
                                                              Icons.close_rounded,
                                                              size: 13,
                                                              color: Colors.white.withOpacity(0.2),
                                                            )
                                                          : Text(
                                                              seatId,
                                                              style: TextStyle(
                                                                color: isSelected
                                                                    ? const Color(0xFF0F0C20)
                                                                    : Colors.white.withOpacity(0.8),
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          const SizedBox(width: 20),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              // CHÚ DẪN TRẠNG THÁI GHẾ
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegendItem('Trống', const Color(0xFF1E1A3C).withOpacity(0.4), Colors.white.withOpacity(0.1), false),
                                    const SizedBox(width: 16),
                                    _buildLegendItem('Đang chọn', Colors.amber, Colors.amber, false),
                                    const SizedBox(width: 16),
                                    _buildLegendItem('Đã đặt', Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.02), true),
                                  ],
                                ),
                              ),

                              const Divider(color: Colors.white10, height: 24),

                              // THỐNG KÊ GHẾ ĐÃ CHỌN & GIÁ TẠM TÍNH
                              if (_selectedSeats.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ghế đã chọn: ${_selectedSeats.join(', ')}',
                                            style: const TextStyle(
                                              color: Colors.amberAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Số lượng: ${_selectedSeats.length} ghế',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.4),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '+${((widget.event['price'] as num) * _selectedSeats.length).toStringAsFixed(0)} VND',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Center(
                                  child: Text(
                                    'Vui lòng nhấp chọn ghế trên sơ đồ để đặt vé',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.35),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: Colors.white10),
                      ),

                      // Giới thiệu sự kiện
                      const Text(
                        'Giới thiệu sự kiện',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.event['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14, 
                          height: 1.6, 
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 120), // Khoảng trống tránh chèn ép bởi thanh bottomNavigationBar
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131026),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TỔNG CỘNG', 
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4), 
                      fontSize: 10, 
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${((widget.event['price'] as num) * (_selectedSeats.isNotEmpty ? _selectedSeats.length : 0)).toStringAsFixed(0)} VND', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedSeats.isNotEmpty ? Colors.amber : Colors.white12,
                  foregroundColor: _selectedSeats.isNotEmpty ? const Color(0xFF0F0C20) : Colors.white30,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _selectedSeats.isNotEmpty ? 6 : 0,
                  shadowColor: Colors.amber.withOpacity(0.3),
                ),
                icon: const Icon(Icons.confirmation_num_rounded, size: 18),
                label: const Text(
                  'ĐẶT VÉ NGAY', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                ),
                onPressed: _selectedSeats.isNotEmpty ? _processBooking : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
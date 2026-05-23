import 'package:flutter/material.dart';
import 'event_detail_screen.dart';
import '../data/mock_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  // =========================================================================
  // 1. HÀM ĐẨY DỮ LIỆU LÊN FIREBASE
  // =========================================================================
  Future<void> _uploadMockDataToFirebase() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore.collection('events').get();
      if (snapshot.docs.isNotEmpty) {
        print("Dữ liệu đã tồn tại trên Firebase, không cần đẩy lại.");
        return;
      }

      print("Đang tiến hành đẩy dữ liệu mẫu lên Firebase...");

      for (var event in MockData.initialEvents) {
        await firestore.collection('events').add({
          'id': event['id'],
          'title': event['title'],
          'category': event['category'],
          'date': event['date'],
          'time': event['time'],
          'location': event['location'],
          'price': event['price'],
          'imageUrl': event['imageUrl'],
          'description': event['description'],
        });
      }

      print("Đã đẩy toàn bộ dữ liệu mẫu lên Firebase thành công!");
    } catch (e) {
      print("Có lỗi xảy ra khi đẩy dữ liệu: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 2. GỌI HÀM ĐẨY DỮ LIỆU KHI MỞ APP
    _uploadMockDataToFirebase();

    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Tạm thời hiển thị dữ liệu trực tiếp từ MockData
    setState(() {
      _events = MockData.initialEvents;
      _isLoading = false;
    });
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
                    Colors.amber.withOpacity(0.15),
                    Colors.amber.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepOrange.withOpacity(0.12),
                    Colors.deepOrange.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Nội dung Scaffold thực tế sử dụng lướt cuộn êm ái
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  snap: true,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: const Color(0xFF0F0C20).withOpacity(innerBoxIsScrolled ? 0.9 : 0.0),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Event Pro',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Xin chào, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Khách'} 👋',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        color: const Color(0xFF1E1A3C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        icon: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
                          ),
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF131026),
                            radius: 16,
                            child: Icon(Icons.person, color: Colors.amber[400], size: 18),
                          ),
                        ),
                        onSelected: (value) async {
                          if (value == 'profile') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang phát triển: Xem hồ sơ'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (value == 'password') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đang phát triển: Đổi mật khẩu'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (value == 'logout') {
                            await FirebaseAuth.instance.signOut();
                            if (!context.mounted) return;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: ListTile(
                              leading: Icon(Icons.person_outline, color: Colors.white70),
                              title: Text('Xem thông tin hồ sơ', style: TextStyle(color: Colors.white70)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'password',
                            child: ListTile(
                              leading: Icon(Icons.lock_outline, color: Colors.white70),
                              title: Text('Đổi mật khẩu', style: TextStyle(color: Colors.white70)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuDivider(color: Colors.white10),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: ListTile(
                              leading: Icon(Icons.logout, color: Colors.redAccent),
                              title: Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(55),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.amber,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.white.withOpacity(0.65),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
                        dividerColor: Colors.transparent,
                        indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        tabs: const [
                          Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Tất cả'))),
                          Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Âm nhạc'))),
                          Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Thể thao'))),
                          Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Workshop'))),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventList(_events),
                      _buildEventList(_events.where((e) => e['category'] == 'Âm nhạc').toList()),
                      _buildEventList(_events.where((e) => e['category'] == 'Thể thao').toList()),
                      _buildEventList(_events.where((e) => e['category'] == 'Workshop').toList()),
                    ],
                  ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent, // Scaffold trong suốt để lộ hình nền
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có sự kiện nào thuộc chủ đề này.',
          style: TextStyle(color: Colors.white60, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1E1A3C).withOpacity(0.7),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventDetailScreen(event: item)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bọc ảnh để bo tròn và thêm độ sâu
                Stack(
                  children: [
                    Image.network(
                      item['imageUrl'],
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Thêm bóng gradient nhẹ đè lên ảnh
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Giá tiền hoặc Tag thể loại ở góc ảnh
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item['price'] == 0 || item['price'] == 'Miễn phí' ? 'Miễn phí' : '${item['price']}đ',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            '${item['date']} - ${item['time'] ?? ''}',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['location'],
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
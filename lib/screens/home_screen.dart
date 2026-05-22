import 'package:flutter/material.dart';
import '../services/db_helper.dart';
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
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Event Pro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1.2)),
                Text(
                    'Xin chào, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Khách'} 👋',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black87)
                ),
              ],
            ),
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              icon: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(Icons.person, color: Colors.amber[800], size: 20),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang phát triển: Xem hồ sơ')));
                } else if (value == 'password') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang phát triển: Đổi mật khẩu')));
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
                    leading: Icon(Icons.person_outline),
                    title: Text('Xem thông tin hồ sơ'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'password',
                  child: ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Đổi mật khẩu'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.amber,
        // 3. PHỤC HỒI LẠI THANH TABBAR BỊ MẤT Ở BƯỚC TRƯỚC
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Âm nhạc'),
            Tab(text: 'Thể thao'),
            Tab(text: 'Workshop'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildEventList(_events),
          _buildEventList(_events.where((e) => e['category'] == 'Âm nhạc').toList()),
          _buildEventList(_events.where((e) => e['category'] == 'Thể thao').toList()),
          _buildEventList(_events.where((e) => e['category'] == 'Workshop').toList()),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Chưa có sự kiện nào thuộc chủ đề này.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Image.network(item['imageUrl'], height: 160, width: double.infinity, fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${item['date']} - ${item['time'] ?? ''}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(item['location'], style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
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
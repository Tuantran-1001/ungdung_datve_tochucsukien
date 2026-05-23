import 'package:flutter/material.dart';
import 'event_detail_screen.dart';
import '../data/mock_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'change_password_screen.dart';
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

  // Các biến quản lý bộ lọc và tìm kiếm sự kiện
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPriceRange = 'Tất cả';
  String _selectedLocation = 'Tất cả';
  String _selectedSort = 'Gần nhất';

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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

  // =========================================================================
  // 3. CÁC HÀM XỬ LÝ LỌC & SẮP XẾP SỰ KIỆN THỜI GIAN THỰC
  // =========================================================================
  List<Map<String, dynamic>> _getFilteredEvents(String category) {
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(_events);

    // 1. Lọc theo Danh mục (TabBar)
    if (category != 'Tất cả') {
      list = list.where((e) => e['category'] == category).toList();
    }

    // 2. Lọc theo Từ khóa tìm kiếm (Tiêu đề và Mô tả)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((e) =>
          (e['title'] ?? '').toString().toLowerCase().contains(query) ||
          (e['description'] ?? '').toString().toLowerCase().contains(query)
      ).toList();
    }

    // 3. Lọc theo Khoảng giá vé
    if (_selectedPriceRange != 'Tất cả') {
      list = list.where((e) {
        final double price = (e['price'] as num).toDouble();
        if (_selectedPriceRange == 'Miễn phí') return price == 0;
        if (_selectedPriceRange == 'Dưới 200k') return price > 0 && price < 200000;
        if (_selectedPriceRange == '200k - 500k') return price >= 200000 && price <= 500000;
        if (_selectedPriceRange == 'Trên 500k') return price > 500000;
        return true;
      }).toList();
    }

    // 4. Lọc theo Địa điểm
    if (_selectedLocation != 'Tất cả') {
      list = list.where((e) {
        final String loc = (e['location'] ?? '').toString().toLowerCase();
        if (_selectedLocation == 'TP.HCM') {
          return loc.contains('hcm') || loc.contains('sala') || loc.contains('phú thọ') || loc.contains('quận') || loc.contains('đầm sen');
        }
        if (_selectedLocation == 'Hà Nội') {
          return loc.contains('hà nội') || loc.contains('hn') || loc.contains('phố cổ') || loc.contains('mỹ đình');
        }
        if (_selectedLocation == 'Đà Nẵng') {
          return loc.contains('đà nẵng') || loc.contains('đn') || loc.contains('sông hàn') || loc.contains('rồng');
        }
        return true;
      }).toList();
    }

    // 5. Sắp xếp dữ liệu
    if (_selectedSort == 'Gần nhất') {
      list.sort((a, b) => (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));
    } else if (_selectedSort == 'Giá tăng dần') {
      list.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (_selectedSort == 'Giá giảm dần') {
      list.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    }

    return list;
  }

  // =========================================================================
  // 4. HIỂN THỊ BỘ LỌC CHUYÊN SÂU (BOTTOM SHEET KÍNH MỜ)
  // =========================================================================
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChoiceChip(String label, String currentSelection, String value, VoidCallback onTap) {
              final bool isSelected = currentSelection == value;
              return GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber : const Color(0xFF0F0C20).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ] : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF0F0C20) : Colors.white.withOpacity(0.8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF15102A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh kéo báo hiệu BottomSheet
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Bộ Lọc Sự Kiện',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        child: const Text('Làm mới', style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setModalState(() {
                            _selectedPriceRange = 'Tất cả';
                            _selectedLocation = 'Tất cả';
                            _selectedSort = 'Gần nhất';
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16),

                  // 1. Khoảng giá vé
                  const Text(
                    'KHOẢNG GIÁ VÉ',
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      buildChoiceChip('Tất cả', _selectedPriceRange, 'Tất cả', () => setModalState(() => _selectedPriceRange = 'Tất cả')),
                      buildChoiceChip('Miễn phí', _selectedPriceRange, 'Miễn phí', () => setModalState(() => _selectedPriceRange = 'Miễn phí')),
                      buildChoiceChip('Dưới 200k', _selectedPriceRange, 'Dưới 200k', () => setModalState(() => _selectedPriceRange = 'Dưới 200k')),
                      buildChoiceChip('200k - 500k', _selectedPriceRange, '200k - 500k', () => setModalState(() => _selectedPriceRange = '200k - 500k')),
                      buildChoiceChip('Trên 500k', _selectedPriceRange, 'Trên 500k', () => setModalState(() => _selectedPriceRange = 'Trên 500k')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Địa điểm
                  const Text(
                    'ĐỊA ĐIỂM',
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      buildChoiceChip('Tất cả', _selectedLocation, 'Tất cả', () => setModalState(() => _selectedLocation = 'Tất cả')),
                      buildChoiceChip('TP.HCM', _selectedLocation, 'TP.HCM', () => setModalState(() => _selectedLocation = 'TP.HCM')),
                      buildChoiceChip('Hà Nội', _selectedLocation, 'Hà Nội', () => setModalState(() => _selectedLocation = 'Hà Nội')),
                      buildChoiceChip('Đà Nẵng', _selectedLocation, 'Đà Nẵng', () => setModalState(() => _selectedLocation = 'Đà Nẵng')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Sắp xếp
                  const Text(
                    'SẮP XẾP THEO',
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      buildChoiceChip('Ngày diễn ra gần nhất', _selectedSort, 'Gần nhất', () => setModalState(() => _selectedSort = 'Gần nhất')),
                      buildChoiceChip('Giá từ thấp đến cao', _selectedSort, 'Giá tăng dần', () => setModalState(() => _selectedSort = 'Giá tăng dần')),
                      buildChoiceChip('Giá từ cao đến thấp', _selectedSort, 'Giá giảm dần', () => setModalState(() => _selectedSort = 'Giá giảm dần')),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Nút hành động áp dụng bộ lọc
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xFF0F0C20),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        shadowColor: Colors.amber.withOpacity(0.2),
                      ),
                      child: const Text('ÁP DỤNG BỘ LỌC', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      onPressed: () {
                        setState(() {}); // Làm mới HomeScreen state với bộ lọc mới
                        Navigator.pop(context);
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

  // =========================================================================
  // 5. THIẾT KẾ THANH TÌM KIẾM & NÚT BỘ LỌC
  // =========================================================================
  Widget _buildSearchBarAndFilterButton() {
    final bool hasActiveFilters = _selectedPriceRange != 'Tất cả' || _selectedLocation != 'Tất cả' || _selectedSort != 'Gần nhất';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A3C).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sự kiện, liveshow...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasActiveFilters ? Colors.amber : const Color(0xFF1E1A3C).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: hasActiveFilters ? Colors.amber : Colors.white.withOpacity(0.08)),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: hasActiveFilters ? const Color(0xFF0F0C20) : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0F0C20), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (hasActiveFilters) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                if (_selectedPriceRange != 'Tất cả')
                  _buildFilterChip('Giá: $_selectedPriceRange', () {
                    setState(() {
                      _selectedPriceRange = 'Tất cả';
                    });
                  }),
                if (_selectedLocation != 'Tất cả')
                  _buildFilterChip('Khu vực: $_selectedLocation', () {
                    setState(() {
                      _selectedLocation = 'Tất cả';
                    });
                  }),
                if (_selectedSort != 'Gần nhất')
                  _buildFilterChip(
                    _selectedSort == 'Giá tăng dần' ? 'Giá thấp -> cao' : 'Giá cao -> thấp',
                    () {
                      setState(() {
                        _selectedSort = 'Gần nhất';
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded, color: Colors.amber, size: 12),
          ),
        ],
      ),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            ).then((updated) {
                              if (updated == true) {
                                // Làm mới trạng thái HomeScreen để cập nhật lời chào hiển thị tên mới
                                setState(() {});
                              }
                            });
                          } else if (value == 'password') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                    child: _buildSearchBarAndFilterButton(),
                  ),
                ),
              ];
            },
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventList(_getFilteredEvents('Tất cả')),
                      _buildEventList(_getFilteredEvents('Âm nhạc')),
                      _buildEventList(_getFilteredEvents('Thể thao')),
                      _buildEventList(_getFilteredEvents('Workshop')),
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
      final bool hasActiveFilters = _searchQuery.isNotEmpty || _selectedPriceRange != 'Tất cả' || _selectedLocation != 'Tất cả';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasActiveFilters ? Icons.search_off_rounded : Icons.event_busy_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                hasActiveFilters
                    ? 'Không tìm thấy sự kiện nào phù hợp với bộ lọc.'
                    : 'Chưa có sự kiện nào thuộc chủ đề này.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
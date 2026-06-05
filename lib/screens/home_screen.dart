import 'package:flutter/material.dart';
import 'event_detail_screen.dart';
import 'settings_screen.dart';
import 'ai_chat_screen.dart';
import '../data/mock_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/settings_service.dart';

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

    _uploadMockDataToFirebase();

    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      final List<Map<String, dynamic>> firestoreEvents = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'] ?? doc.id,
          'title': data['title'] ?? '',
          'category': data['category'] ?? '',
          'date': data['date'] ?? '',
          'time': data['time'] ?? '',
          'location': data['location'] ?? '',
          'price': data['price'] ?? 0,
          'imageUrl': data['imageUrl'] ?? '',
          'description': data['description'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _events = firestoreEvents.isNotEmpty ? firestoreEvents : MockData.initialEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading events from Firestore: $e');
      if (mounted) {
        setState(() {
          _events = MockData.initialEvents;
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================================
  // 3. CÁC HÀM XỬ LÝ LỌC & SẮP XẾP SỰ KIỆN THỜI GIAN THỰC
  // =========================================================================
  List<Map<String, dynamic>> _getFilteredEvents(String category) {
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(_events);

    if (category != 'Tất cả') {
      list = list.where((e) => e['category'] == category).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((e) =>
          (e['title'] ?? '').toString().toLowerCase().contains(query) ||
          (e['description'] ?? '').toString().toLowerCase().contains(query)
      ).toList();
    }

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
  // 4. HIỂN THỊ BỘ LỌC CHUYÊN SÂU (BOTTOM SHEET NỀN SÁNG/TỐI)
  // =========================================================================
  void _showFilterBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChoiceChip(String label, String currentSelection, String value, VoidCallback onTap) {
              final bool isSelected = currentSelection == value;
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.blue : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
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
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppSettings.translate('filter'),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        child: Text(AppSettings.translate('reset'), style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  Divider(color: isDark ? Colors.grey[800] : Colors.grey[200], height: 16),

                  // 1. Khoảng giá vé
                  Text(
                    AppSettings.translate('price_range'),
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
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
                  Text(
                    AppSettings.translate('location'),
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
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
                  Text(
                    AppSettings.translate('sort_by'),
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      buildChoiceChip(AppSettings.translate('sort_closest'), _selectedSort, 'Gần nhất', () => setModalState(() => _selectedSort = 'Gần nhất')),
                      buildChoiceChip(AppSettings.translate('sort_price_asc'), _selectedSort, 'Giá tăng dần', () => setModalState(() => _selectedSort = 'Giá tăng dần')),
                      buildChoiceChip(AppSettings.translate('sort_price_desc'), _selectedSort, 'Giá giảm dần', () => setModalState(() => _selectedSort = 'Giá giảm dần')),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Nút hành động áp dụng bộ lọc
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppSettings.translate('apply_filter'), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      onPressed: () {
                        setState(() {});
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
  Widget _buildSearchBarAndFilterButton(bool isDark) {
    final bool hasActiveFilters = _selectedPriceRange != 'Tất cả' || _selectedLocation != 'Tất cả' || _selectedSort != 'Gần nhất';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppSettings.translate('search_placeholder'),
                    hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.grey[500] : Colors.grey[400], size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: Icon(Icons.clear_rounded, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 18),
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
                  onTap: () => _showFilterBottomSheet(isDark),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasActiveFilters ? Colors.blue : (isDark ? Colors.grey[800] : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: hasActiveFilters ? Colors.blue : (isDark ? Colors.grey[700]! : Colors.grey[300]!)),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: hasActiveFilters ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
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
                        border: Border.all(color: isDark ? Colors.grey[900]! : Colors.white, width: 1.5),
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
        color: Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded, color: Colors.blue, size: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.languageNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettings.themeNotifier,
          builder: (context, themeMode, _) {
            final isDark = themeMode == ThemeMode.dark;

            return Scaffold(
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      snap: true,
                      elevation: innerBoxIsScrolled ? 2 : 0,
                      shadowColor: Colors.black26,
                      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppSettings.translate('event_pro'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppSettings.translate('welcome')}, ${FirebaseAuth.instance.currentUser?.displayName ?? 'Khách'} 👋',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              ).then((_) {
                                setState(() {});
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5),
                              ),
                              child: CircleAvatar(
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                radius: 16,
                                child: Icon(Icons.settings_outlined, color: Colors.blue, size: 18),
                              ),
                            ),
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
                              color: Colors.blue,
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
                            dividerColor: Colors.transparent,
                            indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            tabs: [
                              Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(AppSettings.translate('category_all')))),
                              Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(AppSettings.translate('category_music')))),
                              Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(AppSettings.translate('category_sports')))),
                              Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(AppSettings.translate('category_workshop')))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                        child: _buildSearchBarAndFilterButton(isDark),
                      ),
                    ),
                  ];
                },
                body: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEventList(_getFilteredEvents('Tất cả'), isDark),
                          _buildEventList(_getFilteredEvents('Âm nhạc'), isDark),
                          _buildEventList(_getFilteredEvents('Thể thao'), isDark),
                          _buildEventList(_getFilteredEvents('Workshop'), isDark),
                        ],
                      ),
              ),
              floatingActionButton: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.tealAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AIChatScreen()),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> list, bool isDark) {
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
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                hasActiveFilters
                    ? 'Không tìm thấy sự kiện nào phù hợp với bộ lọc.'
                    : 'Chưa có sự kiện nào thuộc chủ đề này.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
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
          color: isDark ? Colors.grey[850] : Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
                Stack(
                  children: [
                    Image.network(
                      item['imageUrl'],
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['price'] == 0 || item['price'] == 'Miễn phí' ? 'Miễn phí' : '${item['price']}đ',
                          style: const TextStyle(
                            color: Colors.white,
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '${item['date']} - ${item['time'] ?? ''}',
                            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['location'],
                              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13),
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
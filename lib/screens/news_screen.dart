import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _newsList = [
    {
      'id': 'n1',
      'title': 'Sơn Tùng M-TP hứa hẹn gây bùng nổ tại Liveshow "Thanh Âm Mùa Hè"',
      'category': 'Âm nhạc',
      'date': '23/05/2026',
      'readTime': '3 phút đọc',
      'imageUrl': 'https://thanhnien.mediacdn.vn/uploaded/caotung/2020_08_29/sontungm-tpskytour2-netflix_IKDM.jpg?width=500',
      'summary': 'Đêm nhạc Thanh Âm Mùa Hè tại Nhà thi đấu Phú Thọ ghi nhận số lượng vé đặt kỷ lục ngay trong ngày đầu mở cổng thanh toán trực tuyến.',
      'content': 'Sự kiện âm nhạc hot nhất mùa hè này đang nóng lên từng giờ. Theo ban tổ chức, Sơn Tùng M-TP sẽ mang đến một set diễn kéo dài 45 phút với hệ thống âm thanh ánh sáng chuẩn quốc tế được nhập khẩu trực tiếp từ Singapore. Đây hứa hẹn là đêm nhạc bùng nổ cảm xúc của hàng vạn khán giả trẻ Sài Thành.'
    },
    {
      'id': 'n2',
      'title': 'Giải Marathon Quốc Tế Sala 2026 đạt mốc 10.000 vận động viên đăng ký',
      'category': 'Thể thao',
      'date': '22/05/2026',
      'readTime': '5 phút đọc',
      'imageUrl': 'https://timve365.vn/uploads/f_65dbf8aac26f782ac4075d3b/giai-chay-120240303175559-2024251615.jfif',
      'summary': 'Ban tổ chức chính thức công bố bản đồ cung đường chạy xanh Sala, đi qua những địa danh sinh thái tuyệt đẹp tại Quận 2.',
      'content': 'Giải chạy Marathon Quốc Tế Sala 2026 không chỉ là cuộc đua thể chất mà còn là ngày hội phong cách sống lành mạnh của cộng đồng. Cung đường chạy năm nay được nâng cấp toàn diện, trạm y tế và tiếp nước bố trí dày đặc mỗi 2km, đảm bảo an toàn tuyệt đối cho các vận động viên thử sức ở mọi cự ly 5km, 10km và 21km.'
    },
    {
      'id': 'n3',
      'title': 'Xu hướng chuyển dịch số hóa ngành tổ chức sự kiện tại Việt Nam',
      'category': 'Workshop',
      'date': '20/05/2026',
      'readTime': '4 phút đọc',
      'imageUrl': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',
      'summary': 'Tích hợp thanh toán trực tuyến VietQR và vé điện tử E-ticket QR Code đang trở thành chuẩn mực bắt buộc cho các sự kiện lớn nhỏ.',
      'content': 'Công nghệ đang làm thay đổi hoàn toàn cách chúng ta tham gia sự kiện. Việc loại bỏ vé giấy vật lý sang vé điện tử E-ticket tích hợp QR Code không chỉ bảo vệ môi trường mà còn giảm thiểu 95% thời gian xếp hàng check-in soát vé tại cửa, nâng tầm chuyên nghiệp của ban tổ chức lên tiêu chuẩn quốc tế.'
    },
    {
      'id': 'n4',
      'title': 'Đen Vâu bắt tay nghệ sĩ Indie quốc tế trong dự án concert sắp tới',
      'category': 'Âm nhạc',
      'date': '18/05/2026',
      'readTime': '3 phút đọc',
      'imageUrl': 'https://afamilycdn.com/2018/7/21/1336393-1532190959423718062301.jpg',
      'summary': 'Sự kết hợp độc đáo hứa hẹn mang đến những bản phối đầy chất tự sự và mộc mạc làm nức lòng người hâm mộ nhạc Indie.',
      'content': 'Dự án concert âm nhạc tối giản mang đậm chất trữ tình của Đen Vâu vừa công bố dàn nghệ sĩ khách mời quốc tế đầy bí ẩn. Đêm nhạc sẽ sử dụng hoàn toàn nhạc cụ acoustic mộc mạc kết hợp dàn giao hưởng thính phòng mang đến không gian nghe nhạc đỉnh cao vô cùng ấm cúng.'
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredNews() {
    String selectedCategory = 'Tất cả';
    switch (_tabController.index) {
      case 1:
        selectedCategory = 'Âm nhạc';
        break;
      case 2:
        selectedCategory = 'Thể thao';
        break;
      case 3:
        selectedCategory = 'Workshop';
        break;
    }

    return _newsList.where((news) {
      final bool matchesCategory = selectedCategory == 'Tất cả' || news['category'] == selectedCategory;
      final bool matchesSearch = news['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          news['summary'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showNewsDetails(BuildContext context, Map<String, dynamic> news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Stack(
            children: [
              // Ảnh bìa tin tức có bóng mờ sáng
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.network(
                  news['imageUrl'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.white.withOpacity(0.7),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.4, 0.7],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              // Nội dung bài báo
              Padding(
                padding: const EdgeInsets.only(top: 220),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag danh mục
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          news['category'].toUpperCase(),
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        news['title'],
                        style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(news['date'], style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(news['readTime'], style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),
                      Text(
                        news['summary'],
                        style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        news['content'],
                        style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.7),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNews = _getFilteredNews();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header đơn giản
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.newspaper_rounded, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Tin Tức Sự Kiện',
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

            // Ô tìm kiếm tin tức
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm tin tức hot nhất...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                          child: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                        )
                      : null,
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.blue, width: 1),
                  ),
                ),
              ),
            ),

            // Thanh TabBar chọn thể loại tin tức
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TabBar(
                controller: _tabController,
                onTap: (idx) => setState(() {}),
                isScrollable: true,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey[700],
                indicatorColor: Colors.blue,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                physics: const BouncingScrollPhysics(),
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Âm nhạc'),
                  Tab(text: 'Thể thao'),
                  Tab(text: 'Workshop'),
                ],
              ),
            ),

            // Danh sách bài viết
            Expanded(
              child: filteredNews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy bài viết phù hợp.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
                      itemCount: filteredNews.length,
                      itemBuilder: (context, index) {
                        final news = filteredNews[index];
                        return GestureDetector(
                          onTap: () => _showNewsDetails(context, news),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ảnh đại diện tin tức
                                Image.network(
                                  news['imageUrl'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, err, stack) {
                                    return Container(height: 150, color: Colors.grey[200]);
                                  },
                                ),
                                // Chi tiết tóm tắt
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              news['category'],
                                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 9),
                                            ),
                                          ),
                                          Text(
                                            '${news['date']} • ${news['readTime']}',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        news['title'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        news['summary'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIChatService {
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;
  final List<ChatMessage> messages = [];

  /// Xóa phiên chat và tin nhắn cũ
  void clearSession() {
    _chatSession = null;
    messages.clear();
  }

  /// Khởi chạy một phiên hội thoại mới với trợ lý AI hoặc lấy phiên hiện tại
  Future<ChatSession> startNewChat() async {
    if (_chatSession != null) {
      return _chatSession!;
    }

    // 1. Lấy danh sách sự kiện hiện tại từ Firestore
    String eventsContext = await _getEventsContext();

    // 2. Lấy danh sách vé đã mua của người dùng hiện tại
    String ticketsContext = await _getTicketsContext();

    // 3. Xây dựng prompt chỉ dẫn hệ thống chặt chẽ
    final systemPrompt = '''
Bạn là "Trợ lý ảo Event Pro AI" - Trợ lý AI thông minh, nhiệt tình và chuyên nghiệp của ứng dụng Event Pro.

Nhiệm vụ chính của bạn: Hỗ trợ người dùng giải đáp các thắc mắc về chủ đề đặt vé, thời gian sự kiện, giá vé, địa điểm tổ chức của các sự kiện trên ứng dụng và các chức năng của ứng dụng Event Pro (như cách thanh toán, xem lịch sử giao dịch, cách đổi mật khẩu...).

Dưới đây là thông tin danh sách các sự kiện đang diễn ra trong hệ thống:
$eventsContext

Thông tin vé đã đặt mua của người dùng hiện tại (nếu có):
$ticketsContext

HƯỚNG DẪN CÁCH ĐẶT VÉ TRÊN APP:
- Để đặt vé cho một sự kiện, người dùng cần vào màn hình chính của app Event Pro, tìm sự kiện muốn đi và bấm vào sự kiện đó để xem chi tiết.
- Trên màn hình chi tiết, chọn các ghế còn trống trên sơ đồ 2D (ví dụ hàng A, B, C... cột 1, 2, 3...).
- Bấm nút "ĐẶT VÉ NGAY" ở dưới cùng để chuyển sang màn hình Thanh toán.
- Chọn phương thức thanh toán phù hợp (Thẻ Quốc tế, Ví MoMo, ZaloPay, VietQR) và bấm nút "Xác nhận thanh toán".
- Sau khi thanh toán thành công, vé điện tử có QR code sẽ xuất hiện trong mục "Vé của tôi" (My Tickets) hiển thị ở tab thứ 3 dưới thanh điều hướng của app.

QUY TẮC BẮT BUỘC (RÀNG BUỘC CÂU TRẢ LỜI):
1. Bạn CHỈ được phép trả lời những câu hỏi liên quan đến đặt vé, sự kiện, thời gian, giá tiền, địa điểm của các sự kiện hoặc tính năng hỗ trợ đặt vé, tài khoản trên app Event Pro.
2. Tuyệt đối KHÔNG trả lời các câu hỏi không liên quan đến ứng dụng (Ví dụ: lập trình, thời tiết, giải bài tập toán, công thức nấu ăn, viết email, dịch thuật văn bản không liên quan, chính trị...).
3. Nếu người dùng hỏi những câu hỏi ngoài phạm vi này, hãy từ chối một cách lịch sự bằng tiếng Việt.
   *Ví dụ từ chối*: "Rất tiếc, tôi là Trợ lý ảo AI của Event Pro và chỉ có thể hỗ trợ bạn các vấn đề liên quan đến đặt vé, thời gian, giá vé, và các sự kiện của ứng dụng. Tôi không thể hỗ trợ các chủ đề khác. Bạn có muốn hỏi về sự kiện nào của Event Pro không?"
4. Trả lời bằng tiếng Việt, ngắn gọn, thân thiện, dễ hiểu, sử dụng các emoji thích hợp (như 🎟️, 📅, 📍, 💳, 🤖...).
''';

    try {
      // 4. Khởi tạo GenerativeModel của Firebase AI bằng Google AI (Gemini Developer API) cho gói Spark miễn phí
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.1-flash-lite',
        systemInstruction: Content.system(systemPrompt),
      );

      // 5. Bắt đầu phiên chat mới
      _chatSession = _model!.startChat();

      // Thêm tin nhắn chào mừng mặc định nếu bộ nhớ tin nhắn đang trống
      if (messages.isEmpty) {
        messages.add(
          ChatMessage(
            text: 'Xin chào! Tôi là Trợ lý ảo AI của Event Pro. 🤖\n\nTên tôi là Event Pro Assistant. Tôi có thể giúp gì cho bạn về thông tin sự kiện, giá vé, lịch trình hoặc hướng dẫn mua vé hôm nay? 🎟️✨',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }

      return _chatSession!;
    } catch (e) {
      debugPrint('Error starting chat session: $e');
      rethrow;
    }
  }

  /// Lấy danh sách sự kiện từ Firestore và định dạng thành chuỗi văn bản
  Future<String> _getEventsContext() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      if (snapshot.docs.isEmpty) {
        return "Hiện tại hệ thống chưa có sự kiện nào.";
      }

      StringBuffer buffer = StringBuffer();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        buffer.writeln('- Tên sự kiện: ${data['title'] ?? 'Chưa rõ'}');
        buffer.writeln('  Mã sự kiện: ${data['id'] ?? doc.id}');
        buffer.writeln('  Thể loại: ${data['category'] ?? 'Chưa rõ'}');
        buffer.writeln('  Ngày diễn ra: ${data['date'] ?? 'Chưa rõ'}');
        buffer.writeln('  Thời gian: ${data['time'] ?? 'Chưa rõ'}');
        buffer.writeln('  Địa điểm: ${data['location'] ?? 'Chưa rõ'}');
        final price = data['price'];
        buffer.writeln('  Giá vé: ${price == null || price == 0 ? 'Miễn phí' : '$priceđ'}');
        buffer.writeln('  Mô tả: ${data['description'] ?? 'Không có mô tả'}');
        buffer.writeln('');
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('Error fetching events for AI context: $e');
      return "Không thể kết nối lấy danh sách sự kiện từ hệ thống.";
    }
  }

  /// Lấy danh sách vé đã mua của người dùng hiện tại từ Firestore
  Future<String> _getTicketsContext() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return "Người dùng chưa đăng nhập. Không thể xem thông tin vé cá nhân.";
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        return "Tài khoản hiện tại chưa đặt mua vé nào.";
      }

      StringBuffer buffer = StringBuffer();
      buffer.writeln("Người dùng ${currentUser.displayName ?? 'Khách'} đã mua các vé:");
      for (var doc in snapshot.docs) {
        final data = doc.data();
        buffer.writeln('- Tên sự kiện: ${data['eventTitle'] ?? 'Chưa rõ'}');
        buffer.writeln('  Mã vé: ${data['id'] ?? doc.id}');
        buffer.writeln('  Ngày diễn ra: ${data['eventDate'] ?? 'Chưa rõ'}');
        buffer.writeln('  Địa điểm: ${data['eventLocation'] ?? 'Chưa rõ'}');
        buffer.writeln('  Vị trí ghế: ${data['seatNumber'] ?? 'Chưa rõ'}');
        buffer.writeln('  Trạng thái vé: ${data['status'] ?? 'Chưa sử dụng'}');
        buffer.writeln('  Thời gian mua vé: ${data['bookingTime'] ?? 'Chưa rõ'}');
        buffer.writeln('');
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('Error fetching tickets for AI context: $e');
      return "Không thể kết nối lấy thông tin vé cá nhân của người dùng.";
    }
  }
}

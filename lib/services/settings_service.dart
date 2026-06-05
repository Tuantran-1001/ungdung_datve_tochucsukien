import 'package:flutter/material.dart';

class AppSettings {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<String> languageNotifier = ValueNotifier('vi'); // 'vi' hoặc 'en'

  static bool get isDark => themeNotifier.value == ThemeMode.dark;
  static bool get isEnglish => languageNotifier.value == 'en';

  static void toggleTheme(bool dark) {
    themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  static void toggleLanguage(bool english) {
    languageNotifier.value = english ? 'en' : 'vi';
  }

  // Hàm tiện ích hỗ trợ dịch ngôn ngữ nhanh chóng
  static String translate(String key) {
    final Map<String, Map<String, String>> translations = {
      'event_pro': {
        'vi': 'Event Pro',
        'en': 'Event Pro',
      },
      'welcome': {
        'vi': 'Xin chào',
        'en': 'Welcome',
      },
      'settings': {
        'vi': 'Cài Đặt Hệ Thống',
        'en': 'System Settings',
      },
      'profile': {
        'vi': 'Xem thông tin hồ sơ',
        'en': 'View profile information',
      },
      'profile_title': {
        'vi': 'Thông Tin Hồ Sơ',
        'en': 'Profile Details',
      },
      'change_password': {
        'vi': 'Đổi mật khẩu',
        'en': 'Change password',
      },
      'dark_theme': {
        'vi': 'Giao diện Tối',
        'en': 'Dark Theme',
      },
      'language': {
        'vi': 'Ngôn ngữ (Tiếng Anh)',
        'en': 'Language (English)',
      },
      'logout': {
        'vi': 'Đăng xuất',
        'en': 'Logout',
      },
      'ticket': {
        'vi': 'Vé của tôi',
        'en': 'My Tickets',
      },
      'news': {
        'vi': 'Tin tức',
        'en': 'News',
      },
      'search_placeholder': {
        'vi': 'Tìm kiếm sự kiện, liveshow...',
        'en': 'Search events, liveshows...',
      },
      'category_all': {
        'vi': 'Tất cả',
        'en': 'All',
      },
      'category_music': {
        'vi': 'Âm nhạc',
        'en': 'Music',
      },
      'category_sports': {
        'vi': 'Thể thao',
        'en': 'Sports',
      },
      'category_workshop': {
        'vi': 'Workshop',
        'en': 'Workshop',
      },
      'filter': {
        'vi': 'Bộ Lọc Sự Kiện',
        'en': 'Event Filter',
      },
      'apply_filter': {
        'vi': 'ÁP DỤNG BỘ LỌC',
        'en': 'APPLY FILTER',
      },
      'reset': {
        'vi': 'Làm mới',
        'en': 'Reset',
      },
      'price_range': {
        'vi': 'KHOẢNG GIÁ VÉ',
        'en': 'PRICE RANGE',
      },
      'location': {
        'vi': 'ĐỊA ĐIỂM',
        'en': 'LOCATION',
      },
      'sort_by': {
        'vi': 'SẮP XẾP THEO',
        'en': 'SORT BY',
      },
      'sort_closest': {
        'vi': 'Ngày diễn ra gần nhất',
        'en': 'Closest date first',
      },
      'sort_price_asc': {
        'vi': 'Giá từ thấp đến cao',
        'en': 'Price low to high',
      },
      'sort_price_desc': {
        'vi': 'Giá từ cao đến thấp',
        'en': 'Price high to low',
      },
      'transaction_history': {
        'vi': 'Lịch sử giao dịch',
        'en': 'Transaction History',
      },
      'no_transactions': {
        'vi': 'Chưa có giao dịch nào được thực hiện.',
        'en': 'No transactions have been made yet.',
      },
      'transaction_id': {
        'vi': 'Mã giao dịch',
        'en': 'Transaction ID',
      },
      'payment_time': {
        'vi': 'Thời gian thanh toán',
        'en': 'Payment Time',
      },
      'payment_method': {
        'vi': 'Phương thức',
        'en': 'Method',
      },
      'total_payment': {
        'vi': 'Tổng thanh toán',
        'en': 'Total Payment',
      },
      'seats_booked': {
        'vi': 'Số ghế',
        'en': 'Seats',
      },
      // === Admin translations ===
      'admin_dashboard': {
        'vi': 'Bảng Điều Khiển Admin',
        'en': 'Admin Dashboard',
      },
      'event_management': {
        'vi': 'Quản Lý Sự Kiện',
        'en': 'Event Management',
      },
      'qr_scanner': {
        'vi': 'Quét Mã QR Soát Vé',
        'en': 'QR Ticket Scanner',
      },
      'revenue_stats': {
        'vi': 'Thống Kê Doanh Thu',
        'en': 'Revenue Statistics',
      },
      'add_event': {
        'vi': 'Thêm Sự Kiện',
        'en': 'Add Event',
      },
      'edit_event': {
        'vi': 'Sửa Sự Kiện',
        'en': 'Edit Event',
      },
      'delete_event': {
        'vi': 'Xóa Sự Kiện',
        'en': 'Delete Event',
      },
      'confirm_delete': {
        'vi': 'Bạn có chắc chắn muốn xóa sự kiện này?',
        'en': 'Are you sure you want to delete this event?',
      },
      'event_name': {
        'vi': 'Tên sự kiện',
        'en': 'Event name',
      },
      'event_category': {
        'vi': 'Danh mục',
        'en': 'Category',
      },
      'event_date': {
        'vi': 'Ngày & Giờ',
        'en': 'Date & Time',
      },
      'event_location': {
        'vi': 'Địa điểm',
        'en': 'Location',
      },
      'event_price': {
        'vi': 'Giá vé (VND)',
        'en': 'Ticket price (VND)',
      },
      'event_image': {
        'vi': 'Link ảnh',
        'en': 'Image URL',
      },
      'event_description': {
        'vi': 'Mô tả chi tiết',
        'en': 'Description',
      },
      'save': {
        'vi': 'LƯU',
        'en': 'SAVE',
      },
      'cancel': {
        'vi': 'Hủy',
        'en': 'Cancel',
      },
      'confirm': {
        'vi': 'Xác nhận',
        'en': 'Confirm',
      },
      'scan_qr': {
        'vi': 'Hướng camera vào mã QR trên vé',
        'en': 'Point camera at QR code on ticket',
      },
      'checkin_success': {
        'vi': 'Check-in thành công!',
        'en': 'Check-in successful!',
      },
      'ticket_used': {
        'vi': 'Vé đã được sử dụng!',
        'en': 'Ticket already used!',
      },
      'invalid_qr': {
        'vi': 'Mã QR không hợp lệ!',
        'en': 'Invalid QR code!',
      },
      'manual_input': {
        'vi': 'Nhập mã vé thủ công',
        'en': 'Enter ticket code manually',
      },
      'total_revenue': {
        'vi': 'Tổng doanh thu',
        'en': 'Total Revenue',
      },
      'total_tickets_sold': {
        'vi': 'Tổng vé đã bán',
        'en': 'Total Tickets Sold',
      },
      'total_events': {
        'vi': 'Tổng sự kiện',
        'en': 'Total Events',
      },
      'revenue_by_event': {
        'vi': 'DOANH THU THEO SỰ KIỆN',
        'en': 'REVENUE BY EVENT',
      },
    };

    return translations[key]?[languageNotifier.value] ?? key;
  }
}

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
    };

    return translations[key]?[languageNotifier.value] ?? key;
  }
}

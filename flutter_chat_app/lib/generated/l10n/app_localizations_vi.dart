// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Ứng dụng Chat Flutter';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get loading => 'Đang tải...';

  @override
  String get errorOccurred => 'Đã xảy ra lỗi';

  @override
  String get retry => 'Thử lại';

  @override
  String get send => 'Gửi';

  @override
  String get close => 'Đóng';

  @override
  String get login => 'Đăng nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get register => 'Đăng ký';

  @override
  String get forgotPassword => 'Quên mật khẩu';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String get password => 'Mật khẩu';

  @override
  String get email => 'Email';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get newMessage => 'Tin nhắn mới';

  @override
  String get typeMessage => 'Nhập tin nhắn...';

  @override
  String get noMessages => 'Chưa có tin nhắn';

  @override
  String get loadMore => 'Tải thêm';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get today => 'Hôm nay';

  @override
  String get online => 'Trực tuyến';

  @override
  String get offline => 'Ngoại tuyến';

  @override
  String get connecting => 'Đang kết nối...';

  @override
  String get reconnecting => 'Đang kết nối lại...';

  @override
  String messageCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tin nhắn',
      one: '1 tin nhắn',
      zero: 'Không có tin nhắn',
    );
    return '$_temp0';
  }

  @override
  String lastSeen(String time) {
    return 'Hoạt động $time';
  }

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get profileSettings => 'Hồ sơ';

  @override
  String get chatSettings => 'Cài đặt trò chuyện';

  @override
  String get notificationSettings => 'Thông báo';

  @override
  String get languageSettings => 'Ngôn ngữ';

  @override
  String get aboutSettings => 'Giới thiệu';

  @override
  String get systemDefault => 'Theo hệ thống';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get languageChanged => 'Đổi ngôn ngữ thành công';

  @override
  String get poorConnection => 'Kết nối kém';

  @override
  String get goodConnection => 'Kết nối tốt';

  @override
  String get excellentConnection => 'Kết nối rất tốt';

  @override
  String get testData => 'Dữ liệu kiểm thử';

  @override
  String get createTestData => 'Tạo dữ liệu kiểm thử';

  @override
  String get clearData => 'Xóa dữ liệu';

  @override
  String get dataCleared => 'Đã xóa dữ liệu';

  @override
  String get users => 'Người dùng';

  @override
  String get chats => 'Cuộc trò chuyện';

  @override
  String get messages => 'Tin nhắn';

  @override
  String get noUsers => 'Chưa có người dùng';

  @override
  String get noChats => 'Chưa có cuộc trò chuyện';

  @override
  String get connectionError => 'Lỗi kết nối';

  @override
  String get databaseError => 'Lỗi cơ sở dữ liệu';

  @override
  String get syncError => 'Lỗi đồng bộ hóa';

  @override
  String get uploadError => 'Lỗi tải lên';

  @override
  String get downloadError => 'Lỗi tải xuống';

  @override
  String get themeSettings => 'Giao diện';

  @override
  String get lightTheme => 'Sáng';

  @override
  String get darkTheme => 'Tối';

  @override
  String get systemTheme => 'Theo hệ thống';

  @override
  String get themeChanged => 'Đã thay đổi giao diện';

  @override
  String get appearance => 'Giao diện';

  @override
  String get general => 'Chung';

  @override
  String get privacy => 'Riêng tư';

  @override
  String get security => 'Bảo mật';

  @override
  String get help => 'Trợ giúp';

  @override
  String get feedback => 'Phản hồi';

  @override
  String get version => 'Phiên bản';

  @override
  String get account => 'Tài khoản';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get avatar => 'Ảnh đại diện';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get bio => 'Tiểu sử';

  @override
  String get accessibility => 'Khả năng tiếp cận';

  @override
  String get fontSize => 'Cỡ chữ';

  @override
  String get animations => 'Hoạt ảnh';
}

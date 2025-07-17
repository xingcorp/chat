import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';

/// Extensions cho String
extension StringExtension on String {
  /// Chuyển chữ cái đầu tiên của chuỗi thành chữ hoa
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
  
  /// Chuyển đổi chuỗi thành bool
  bool toBool() {
    return toLowerCase() == 'true';
  }
  
  /// Kiểm tra chuỗi có phải là email hay không
  bool get isValidEmail {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegExp.hasMatch(this);
  }
  
  /// Kiểm tra chuỗi có phải là URL hay không
  bool get isValidUrl {
    final urlRegExp = RegExp(
      r'^(http|https)://'
      r'([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?'
      r'(/[a-zA-Z0-9_-]+)*/?'
      r'(\?[a-zA-Z0-9_-]+=[a-zA-Z0-9%+_.-]+(&[a-zA-Z0-9_-]+=[a-zA-Z0-9%+_.-]+)*)?',
    );
    return urlRegExp.hasMatch(this);
  }
  
  /// Kiểm tra chuỗi có phải là số điện thoại hay không
  bool get isValidPhone {
    final phoneRegExp = RegExp(r'^\+?[0-9]{10,14}$');
    return phoneRegExp.hasMatch(this);
  }
  
  /// Lấy tên miền từ URL
  String get domainFromUrl {
    if (!isValidUrl) return this;
    try {
      final uri = Uri.parse(this);
      return uri.host;
    } catch (e) {
      return this;
    }
  }
  
  /// Lấy tên file từ đường dẫn
  String get fileNameFromPath {
    try {
      return split('/').last;
    } catch (e) {
      return this;
    }
  }
  
  /// Lấy phần mở rộng của file từ đường dẫn
  String get fileExtension {
    try {
      return split('.').last.toLowerCase();
    } catch (e) {
      return '';
    }
  }
  
  /// Kiểm tra chuỗi có phải là file ảnh hay không dựa vào phần mở rộng
  bool get isImageFile {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
    return imageExtensions.contains(fileExtension);
  }
  
  /// Kiểm tra chuỗi có phải là file video hay không dựa vào phần mở rộng
  bool get isVideoFile {
    final videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'];
    return videoExtensions.contains(fileExtension);
  }
  
  /// Lấy avatar dựa vào tên (ví dụ: Nguyễn Văn A -> NA)
  String get initialsFromName {
    if (isEmpty) return '';
    
    final nameParts = trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '';
    }
    
    return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'.toUpperCase();
  }
  
  /// Rút gọn chuỗi nếu quá dài, thêm ... ở cuối
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

/// Extensions cho DateTime
extension DateTimeExtension on DateTime {
  /// Định dạng ngày theo chuẩn dd/MM/yyyy
  String get toFormattedDate {
    return DateFormat(AppConstants.kDefaultDateFormat).format(this);
  }
  
  /// Định dạng thời gian theo chuẩn HH:mm
  String get toFormattedTime {
    return DateFormat(AppConstants.kDefaultTimeFormat).format(this);
  }
  
  /// Định dạng ngày và thời gian theo chuẩn dd/MM/yyyy HH:mm
  String get toFormattedDateTime {
    return DateFormat(AppConstants.kDefaultDateTimeFormat).format(this);
  }
  
  /// Trả về thời gian theo định dạng thân thiện (vd: 5 phút trước, 2 giờ trước, ...)
  String get timeAgo {
    final difference = DateTime.now().difference(this);
    
    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tuần trước';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else {
      return '${(difference.inDays / 365).floor()} năm trước';
    }
  }
  
  /// Trả về thông tin ngày phù hợp với tin nhắn chat
  String get chatTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(year, month, day);
    
    if (dateToCheck == today) {
      return toFormattedTime;
    } else if (dateToCheck == yesterday) {
      return 'Hôm qua, $toFormattedTime';
    } else if (now.difference(this).inDays < 7) {
      // Trong vòng 1 tuần
      final weekday = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'];
      return '${weekday[weekday.length - 1]}, $toFormattedTime';
    } else {
      return toFormattedDateTime;
    }
  }
  
  /// Kiểm tra xem DateTime có phải là ngày hôm nay không
  bool get isToday {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }
  
  /// Kiểm tra xem DateTime có phải là ngày hôm qua không
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return yesterday.day == day && yesterday.month == month && yesterday.year == year;
  }
  
  /// Lấy DateTime chỉ có ngày (loại bỏ giờ, phút, giây)
  DateTime get dateOnly {
    return DateTime(year, month, day);
  }
}

/// Extensions cho int
extension IntExtension on int {
  /// Chuyển đổi kích thước file từ byte sang định dạng dễ đọc (KB, MB, GB)
  String get formatFileSize {
    if (this < 1024) {
      return '$this B';
    } else if (this < 1024 * 1024) {
      final kb = this / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else if (this < 1024 * 1024 * 1024) {
      final mb = this / (1024 * 1024);
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      final gb = this / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }
  
  /// Chuyển đổi thời gian từ giây sang định dạng mm:ss
  String get formatDuration {
    final minutes = (this ~/ 60).toString().padLeft(2, '0');
    final seconds = (this % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  /// Chuyển đổi thời gian từ giây sang định dạng hh:mm:ss nếu cần
  String get formatDurationExtended {
    if (this < 3600) {
      return formatDuration;
    } else {
      final hours = (this ~/ 3600).toString().padLeft(2, '0');
      final minutes = ((this % 3600) ~/ 60).toString().padLeft(2, '0');
      final seconds = (this % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
  }
  
  /// Chuyển đổi số lượng lớn thành định dạng dễ đọc (K, M, B)
  String get formatCount {
    if (this < 1000) {
      return toString();
    } else if (this < 1000000) {
      final k = this / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    } else if (this < 1000000000) {
      final m = this / 1000000;
      return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M';
    } else {
      final b = this / 1000000000;
      return '${b.toStringAsFixed(b.truncateToDouble() == b ? 0 : 1)}B';
    }
  }
}

/// Extensions cho Widget
extension WidgetExtension on Widget {
  /// Bọc widget trong Padding
  Widget withPadding(EdgeInsetsGeometry padding) {
    return Padding(
      padding: padding,
      child: this,
    );
  }
  
  /// Căn giữa widget
  Widget centered() {
    return Center(
      child: this,
    );
  }
  
  /// Bọc widget trong Card
  Widget inCard({
    Color? color,
    double? elevation,
    ShapeBorder? shape,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      color: color,
      elevation: elevation ?? AppConstants.kDefaultElevation,
      shape: shape,
      margin: margin,
      child: padding != null
          ? Padding(padding: padding, child: this)
          : this,
    );
  }
  
  /// Bọc widget trong Container với border radius
  Widget withBorderRadius(double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: this,
    );
  }
  
  /// Tạo vùng chạm lớn hơn cho widget
  Widget withTouchTarget({double size = AppConstants.kTouchTargetSize}) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: this,
      ),
    );
  }
  
  /// Bọc widget trong Expanded
  Widget expanded({int flex = 1}) {
    return Expanded(
      flex: flex,
      child: this,
    );
  }
  
  /// Bọc widget trong Flexible
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) {
    return Flexible(
      flex: flex,
      fit: fit,
      child: this,
    );
  }
}

/// Extensions cho List<T>
extension ListExtension<T> on List<T> {
  /// Lấy phần tử ngẫu nhiên từ danh sách
  T? get randomItem {
    if (isEmpty) return null;
    return this[Random().nextInt(length)];
  }
  
  /// Lấy phần tử đầu tiên thỏa mãn điều kiện, hoặc null nếu không tìm thấy
  T? firstWhereOrNull(bool Function(T) predicate) {
    for (final element in this) {
      if (predicate(element)) {
        return element;
      }
    }
    return null;
  }
  
  /// Chia danh sách thành các nhóm có kích thước chỉ định
  List<List<T>> chunked(int size) {
    if (isEmpty) return [];
    
    final result = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final endIndex = (i + size < length) ? i + size : length;
      result.add(sublist(i, endIndex));
    }
    
    return result;
  }
}

/// Extensions cho BuildContext
extension BuildContextExtension on BuildContext {
  /// Lấy theme hiện tại
  ThemeData get theme => Theme.of(this);
  
  /// Lấy kích thước màn hình
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Lấy chiều rộng màn hình
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Lấy chiều cao màn hình
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Kiểm tra xem thiết bị có phải là di động không (dựa vào chiều rộng)
  bool get isMobile => screenWidth < 650;
  
  /// Kiểm tra xem thiết bị có phải là tablet không (dựa vào chiều rộng)
  bool get isTablet => screenWidth >= 650 && screenWidth < 1024;
  
  /// Kiểm tra xem thiết bị có phải là desktop không (dựa vào chiều rộng)
  bool get isDesktop => screenWidth >= 1024;
  
  /// Kiểm tra xem thiết bị đang ở chế độ dark mode hay không
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Kiểm tra xem bàn phím có đang hiển thị hay không
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;
  
  /// Lấy padding của màn hình (notch, status bar, navigation bar)
  EdgeInsets get screenPadding => MediaQuery.of(this).padding;
  
  /// Ẩn bàn phím
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
  
  /// Hiển thị SnackBar
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }
  
  /// Điều hướng đến trang mới
  Future<T?> navigateTo<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  /// Thay thế trang hiện tại
  Future<T?> replaceTo<T>(Widget page) {
    return Navigator.of(this).pushReplacement<T, dynamic>(
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  /// Quay lại trang trước đó
  void goBack<T>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }
}

/// Extensions cho File
extension FileExtension on File {
  /// Kiểm tra file có phải là ảnh hay không
  bool get isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'];
    final extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }
  
  /// Kiểm tra file có phải là video hay không
  bool get isVideo {
    final videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'];
    final extension = path.split('.').last.toLowerCase();
    return videoExtensions.contains(extension);
  }
  
  /// Lấy kích thước file theo định dạng đọc được
  Future<String> get readableSize async {
    final bytes = await length();
    return bytes.formatFileSize;
  }
} 
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Lớp tiện ích giúp xử lý responsive design
class ScreenUtils {
  /// Trả về giá trị dựa trên kích thước màn hình
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    // Desktop layout
    if (width >= 1024) {
      return desktop ?? tablet ?? mobile;
    }
    
    // Tablet layout
    if (width >= 650) {
      return tablet ?? mobile;
    }
    
    // Mobile layout
    return mobile;
  }
  
  /// Trả về giá trị scale dựa trên kích thước màn hình
  static double get scaleFactor {
    final width = ScreenUtil().screenWidth;
    if (width >= 1024) return 1.25;
    if (width >= 650) return 1.125;
    return 1.0;
  }
  
  /// Tạo padding dựa vào kích thước màn hình
  static EdgeInsets responsivePadding({
    required BuildContext context,
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    return responsiveValue(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  /// Kiểm tra xem thiết bị có phải là Notch phone không
  static bool get isNotchPhone {
    if (!Platform.isIOS) return false;
    
    // Danh sách iPhone với notch
    const notchPhones = [
      'iPhone 10', 'iPhone 11', 'iPhone 12', 'iPhone 13', 'iPhone 14', 'iPhone 15',
    ];
    
    final device = Platform.localHostname.toLowerCase();
    return notchPhones.any((phone) => device.contains(phone.toLowerCase()));
  }
  
  /// Nhận bottom padding cho safe area
  static double safeBottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  /// Nhận top padding cho safe area
  static double safeTopPadding(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  /// Kiểm tra xem thiết bị có phải là điện thoại hay không
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 650;
  }
  
  /// Kiểm tra xem thiết bị có phải là tablet hay không
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 650 && width < 1024;
  }
  
  /// Kiểm tra xem thiết bị có phải là desktop hay không
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
  
  /// Trả về hướng màn hình (ngang/dọc)
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }
  
  /// Kiểm tra xem thiết bị có đang ở chế độ ngang hay không
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Kiểm tra xem thiết bị có đang ở chế độ dọc hay không
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// Tính toán số cột trong grid dựa trên kích thước màn hình
  static int calculateGridColumnCount(BuildContext context, {double idealItemWidth = 150}) {
    final width = MediaQuery.of(context).size.width;
    final count = max(1, (width / idealItemWidth).floor());
    return count;
  }
  
  /// Trả về kích thước box dựa vào kích thước màn hình và số cột
  static double calculateGridItemSize(BuildContext context, {int columnCount = 2, double spacing = 16}) {
    final width = MediaQuery.of(context).size.width;
    final totalSpacing = spacing * (columnCount - 1);
    final sidePadding = spacing * 2;
    return (width - totalSpacing - sidePadding) / columnCount;
  }
  
  /// Khởi tạo ScreenUtil với design size
  static void initScreenUtil(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(375, 812), // Kích thước thiết kế cho iPhone X
      minTextAdapt: true,
      splitScreenMode: true,
    );
  }
  
  /// Trả về kích thước cho GridView dựa vào số item trên hàng
  static double getGridCrossAxisExtent(BuildContext context, int itemPerRow) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / itemPerRow);
  }
  
  /// Trả về height ratio dựa vào kích thước thiết kế
  static double heightRatio(double height) {
    return height / 812; // Dựa trên chiều cao thiết kế (iPhone X)
  }
  
  /// Trả về width ratio dựa vào kích thước thiết kế
  static double widthRatio(double width) {
    return width / 375; // Dựa trên chiều rộng thiết kế (iPhone X)
  }
  
  /// Trả về kích thước văn bản scale dựa vào kích thước thiết kế
  static double fontSizeScale(double size) {
    final scaleFactor = size <= 14 ? 0.9 : (size <= 18 ? 0.95 : 1.0);
    return size * scaleFactor;
  }
} 
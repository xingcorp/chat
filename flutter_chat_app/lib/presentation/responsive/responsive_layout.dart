import 'package:flutter/material.dart';

/// Widget giúp tự động điều chỉnh giao diện dựa trên kích thước màn hình
class ResponsiveLayout extends StatelessWidget {
  /// Widget cho màn hình điện thoại
  final Widget mobileLayout;
  
  /// Widget cho màn hình tablet (tùy chọn)
  final Widget? tabletLayout;
  
  /// Widget cho màn hình desktop (tùy chọn)
  final Widget? desktopLayout;

  /// Ngưỡng kích thước để coi là điện thoại (pixel)
  static const double _mobileBreakpoint = 650;
  
  /// Ngưỡng kích thước để coi là tablet (pixel)
  static const double _tabletBreakpoint = 1100;

  const ResponsiveLayout({
    Key? key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  }) : super(key: key);

  /// Kiểm tra xem có phải là màn hình điện thoại
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  /// Kiểm tra xem có phải là màn hình tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _mobileBreakpoint &&
      MediaQuery.of(context).size.width < _tabletBreakpoint;

  /// Kiểm tra xem có phải là màn hình desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    // Sử dụng LayoutBuilder để phản ứng với thay đổi kích thước
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _tabletBreakpoint) {
          // Desktop layout
          return desktopLayout ?? tabletLayout ?? mobileLayout;
        } else if (constraints.maxWidth >= _mobileBreakpoint) {
          // Tablet layout
          return tabletLayout ?? mobileLayout;
        } else {
          // Mobile layout
          return mobileLayout;
        }
      },
    );
  }
}

/// Widget hiển thị nội dung dựa trên platform (mobile/web/desktop)
class PlatformLayout extends StatelessWidget {
  /// Widget cho nền tảng mobile (iOS/Android)
  final Widget mobileLayout;
  
  /// Widget cho nền tảng web
  final Widget webLayout;
  
  /// Widget cho nền tảng desktop (Windows/macOS/Linux)
  final Widget desktopLayout;

  const PlatformLayout({
    Key? key,
    required this.mobileLayout,
    required this.webLayout,
    required this.desktopLayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Đây là phần placeholder, logic thực tế sẽ được xử lý
    // bởi conditional imports ở main.dart
    return mobileLayout;
  }
} 
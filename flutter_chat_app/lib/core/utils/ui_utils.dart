import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';

/// Lớp tiện ích cho UI
class UIUtils {
  /// Wrap ứng dụng với ScreenUtilInit để hỗ trợ responsive
  static Widget wrapWithScreenUtil(Widget app) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppDimens.breakpointDesktop;

        return ScreenUtilInit(
          designSize: isDesktop
              ? Size(constraints.maxWidth, constraints.maxHeight)
              : const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => app,
        );
      },
    );
  }
  
  /// Làm tròn số double thành số nguyên dựa vào DPI
  static double dp(double val) {
    return val.r;
  }
  
  /// Font size responsive
  static double sp(double val) {
    return val.sp;
  }
  
  /// Chiều rộng responsive
  static double w(double val) {
    return val.w;
  }
  
  /// Chiều cao responsive
  static double h(double val) {
    return val.h;
  }
  
  /// Radius responsive
  static double r(double val) {
    return val.r;
  }
  
  /// Tạo shadow cho container
  static List<BoxShadow> getShadow({
    Color color = Colors.black12,
    double blurRadius = 5,
    Offset offset = const Offset(0, 2),
  }) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
  
  /// Tạo gradient (thường dùng cho nút)
  static LinearGradient getGradient({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
    );
  }
} 
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Tiện ích phát hiện nền tảng chạy (desktop/mobile/web)
///
/// Dùng để quyết định UX phù hợp theo nền tảng:
/// - Desktop/Web: text selectable, right-click context menu
/// - Mobile: long-press copy, no text selection (tránh conflict scroll)
///
/// Tham khảo pattern từ Stream Chat Flutter: `device_segmentation.dart`
class PlatformUtils {
  PlatformUtils._();

  /// `true` nếu đang chạy trên macOS, Windows, hoặc Linux (KHÔNG phải web)
  static bool get isDesktopDevice =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// `true` nếu đang chạy trên web HOẶC desktop native
  ///
  /// Dùng để bật text selection (SelectableText) — user desktop/web
  /// expect drag-to-select giống các app khác.
  static bool get isDesktopDeviceOrWeb => kIsWeb || isDesktopDevice;

  /// `true` nếu đang chạy trên iOS hoặc Android (KHÔNG phải web)
  static bool get isMobileDevice =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// `true` nếu đang chạy trên iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// `true` nếu đang chạy trên Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// `true` nếu đang chạy trên Web
  static bool get isWeb => kIsWeb;
}

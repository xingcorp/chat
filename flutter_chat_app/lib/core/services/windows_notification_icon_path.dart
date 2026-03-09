import 'package:flutter_chat_app/core/services/windows_notification_icon_path_stub.dart'
    if (dart.library.io)
        'package:flutter_chat_app/core/services/windows_notification_icon_path_io.dart'
    as impl;

String? resolveWindowsNotificationIconPath(String assetPath) {
  return impl.resolveWindowsNotificationIconPath(assetPath);
}

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service that updates the native app icon / taskbar badge with the total
/// unread message count across **all** platforms.
///
/// - **Windows**: Sets a red overlay icon on the taskbar button via
///   `ITaskbarList3::SetOverlayIcon` (custom C++ plugin).
/// - **macOS**: Sets `NSApp.dockTile.badgeLabel` (custom Swift plugin).
/// - **Android**: Updates the launcher badge via `ShortcutBadger`
///   (through [FlutterAppBadger]).
/// - **iOS**: Sets `UIApplication.applicationIconBadgeNumber`
///   (through [FlutterAppBadger]).
/// - **Web**: No-op.
///
/// Listens to [ChatModuleEventBus.totalUnreadCountStream] and automatically
/// forwards every update to the appropriate native layer.
@lazySingleton
class DesktopBadgeService {
  final ChatModuleEventBus _eventBus;
  final Logger _logger;

  static const MethodChannel _channel =
      MethodChannel('com.oxii.chat/desktop_badge');

  StreamSubscription<int>? _unreadSubscription;

  /// Whether the current platform supports desktop badges via MethodChannel.
  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS;
  }

  /// Whether the current platform supports mobile badges via FlutterAppBadger.
  bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Whether any badge mechanism is available on this platform.
  bool get _isSupported => _isDesktop || _isMobile;

  DesktopBadgeService(this._eventBus, this._logger);

  /// Start listening to unread count changes and forward to native.
  void initialize() {
    if (!_isSupported) return;

    _unreadSubscription = _eventBus.totalUnreadCountStream.listen(
      (count) => _updateBadge(count),
      onError: (Object error) {
        _logger.w('DesktopBadgeService: stream error: $error');
      },
    );

    _logger.i('DesktopBadgeService: initialized (desktop=$_isDesktop, mobile=$_isMobile)');
  }

  /// Manually update the badge count.
  Future<void> updateBadge(int count) async {
    if (!_isSupported) return;
    await _updateBadge(count);
  }

  /// Remove the badge overlay / clear dock/app badge.
  Future<void> clearBadge() async {
    if (!_isSupported) return;
    await _updateBadge(0);
  }

  /// Cancel the stream subscription and clear the badge.
  Future<void> dispose() async {
    await _unreadSubscription?.cancel();
    _unreadSubscription = null;

    if (_isDesktop) {
      try {
        await _channel.invokeMethod<void>('clearBadge');
      } catch (_) {
        // Native side may already be torn down.
      }
    }

    if (_isMobile) {
      try {
        FlutterAppBadger.removeBadge();
      } catch (_) {
        // Badger not available or already torn down.
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _updateBadge(int count) async {
    if (_isDesktop) {
      await _updateDesktopBadge(count);
    }
    if (_isMobile) {
      await _updateMobileBadge(count);
    }
  }

  /// Desktop: MethodChannel → Windows C++ / macOS Swift plugin.
  Future<void> _updateDesktopBadge(int count) async {
    try {
      if (count <= 0) {
        await _channel.invokeMethod<void>('clearBadge');
      } else {
        await _channel.invokeMethod<void>('updateBadge', {'count': count});
      }
    } on MissingPluginException {
      // Native handler not registered — expected on unsupported platforms
      // or during hot-restart.
    } catch (e) {
      _logger.w('DesktopBadgeService: desktop native call failed: $e');
    }
  }

  /// Mobile: FlutterAppBadger → ShortcutBadger (Android) / UIApplication (iOS).
  Future<void> _updateMobileBadge(int count) async {
    try {
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();
      if (!isSupported) return;

      if (count <= 0) {
        FlutterAppBadger.removeBadge();
      } else {
        FlutterAppBadger.updateBadgeCount(count);
      }
    } catch (e) {
      _logger.w('DesktopBadgeService: mobile badge update failed: $e');
    }
  }
}

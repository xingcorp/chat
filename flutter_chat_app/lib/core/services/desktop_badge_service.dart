import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service that updates the native desktop taskbar/dock badge
/// with the total unread message count.
///
/// - **Windows**: Sets a red overlay icon with the count on the taskbar button
///   via `ITaskbarList3::SetOverlayIcon`.
/// - **macOS**: Sets `NSApp.dockTile.badgeLabel` to the count string.
/// - **Other platforms**: No-op.
///
/// Listens to [ChatModuleEventBus.totalUnreadCountStream] and automatically
/// forwards every update to the native layer through a [MethodChannel].
@lazySingleton
class DesktopBadgeService {
  final ChatModuleEventBus _eventBus;
  final Logger _logger;

  static const MethodChannel _channel =
      MethodChannel('com.oxii.chat/desktop_badge');

  StreamSubscription<int>? _unreadSubscription;

  /// Whether the current platform supports desktop badges.
  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS;
  }

  DesktopBadgeService(this._eventBus, this._logger);

  /// Start listening to unread count changes and forward to native.
  void initialize() {
    if (!_isDesktop) return;

    _unreadSubscription = _eventBus.totalUnreadCountStream.listen(
      (count) => _updateNativeBadge(count),
      onError: (Object error) {
        _logger.w('DesktopBadgeService: stream error: $error');
      },
    );

    _logger.i('DesktopBadgeService: initialized');
  }

  /// Manually update the badge count.
  Future<void> updateBadge(int count) async {
    if (!_isDesktop) return;
    await _updateNativeBadge(count);
  }

  /// Remove the badge overlay / clear dock badge.
  Future<void> clearBadge() async {
    if (!_isDesktop) return;
    await _updateNativeBadge(0);
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
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _updateNativeBadge(int count) async {
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
      _logger.w('DesktopBadgeService: native call failed: $e');
    }
  }
}

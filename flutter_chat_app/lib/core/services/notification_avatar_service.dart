import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Downloads and caches user/group avatars as local files for use in
/// OS-native notifications (Windows appLogoOverride, macOS attachment).
///
/// Also generates initials-based avatar images as fallback when the user
/// has no profile picture — matching the style shown in the conversation list.
///
/// Cache strategy:
/// - Files stored in `<tempDir>/chat_notification_avatars/<hash>.png`
/// - Each file reused across notifications until [clearCache] is called
/// - Download timeout: 3 seconds — if exceeded, returns `null` (notification
///   shows app icon instead)
class NotificationAvatarService {
  NotificationAvatarService({
    required AppLogger logger,
  }) : _logger = logger;

  static const Duration _downloadTimeout = Duration(seconds: 3);
  static const String _cacheSubDir = 'chat_notification_avatars';

  /// Size of generated initials avatar in pixels.
  ///
  /// 128×128 is sufficient for notification icons on all platforms:
  /// - Windows: app logo override (typically 48–64dp, circle-cropped)
  /// - macOS/iOS: attachment thumbnail
  static const int _initialsAvatarSize = 128;

  /// Deterministic color palette for initials avatars.
  ///
  /// Color is selected based on `name.hashCode % length`, so the same
  /// user always gets the same background color.
  static const List<ui.Color> _avatarColors = <ui.Color>[
    ui.Color(0xFF1ABC9C), // Turquoise
    ui.Color(0xFF2ECC71), // Emerald
    ui.Color(0xFF3498DB), // Peter River
    ui.Color(0xFF9B59B6), // Amethyst
    ui.Color(0xFFE67E22), // Carrot
    ui.Color(0xFFE74C3C), // Alizarin
    ui.Color(0xFF16A085), // Green Sea
    ui.Color(0xFF27AE60), // Nephritis
    ui.Color(0xFF2980B9), // Belize Hole
    ui.Color(0xFF8E44AD), // Wisteria
    ui.Color(0xFFD35400), // Pumpkin
    ui.Color(0xFFC0392B), // Pomegranate
    ui.Color(0xFFF39C12), // Sunflower
    ui.Color(0xFF00BCD4), // Cyan
    ui.Color(0xFF607D8B), // Blue Grey
    ui.Color(0xFF795548), // Brown
  ];

  final AppLogger _logger;

  /// In-memory map of avatar URL → local file path.
  ///
  /// If the file still exists on disk, we skip re-downloading.
  final Map<String, String> _urlToPathCache = <String, String>{};

  /// In-memory map of name → generated initials avatar file path.
  final Map<String, String> _initialsPathCache = <String, String>{};

  /// Returns a local [File] path for the given avatar [url].
  ///
  /// - Returns cached path immediately if the file still exists.
  /// - Downloads and saves to temp directory if not cached.
  /// - Returns `null` on any failure (timeout, network error, invalid image).
  Future<String?> getAvatarFilePath(String? url) async {
    if (kIsWeb || url == null || url.trim().isEmpty) {
      return null;
    }

    // Check in-memory cache first.
    final String? cached = _urlToPathCache[url];
    if (cached != null && File(cached).existsSync()) {
      return cached;
    }

    try {
      final Directory cacheDir = await _ensureCacheDir();
      final String fileName = _urlToFileName(url);
      final String filePath = path.join(cacheDir.path, fileName);
      final File file = File(filePath);

      // Check disk cache (might have been downloaded in a previous session).
      if (file.existsSync() && file.lengthSync() > 0) {
        _urlToPathCache[url] = filePath;
        return filePath;
      }

      // Download with timeout.
      final http.Response response = await http
          .get(Uri.parse(url))
          .timeout(_downloadTimeout);

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        _logger.d(
          'Avatar download failed',
          <String, dynamic>{
            'url': url,
            'status': response.statusCode,
          },
        );
        return null;
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);
      _urlToPathCache[url] = filePath;

      return filePath;
    } catch (error) {
      // Timeout, network error, file system error — all non-fatal.
      _logger.d(
        'Avatar download skipped',
        <String, dynamic>{
          'url': url,
          'error': error.toString(),
        },
      );
      return null;
    }
  }

  /// Generates an initials-based avatar PNG for [name] and returns the
  /// local file path.
  ///
  /// Renders a colored circle with 1-2 white initials centered inside,
  /// matching the visual style of [AppAvatar.initials] in the chat list.
  ///
  /// Results are cached by name — same name always produces same file.
  /// Returns `null` on web or if rendering fails.
  Future<String?> generateInitialsAvatar(String name) async {
    if (kIsWeb || name.trim().isEmpty) {
      return null;
    }

    final String trimmedName = name.trim();

    // Check in-memory cache.
    final String? cached = _initialsPathCache[trimmedName];
    if (cached != null && File(cached).existsSync()) {
      return cached;
    }

    try {
      final Directory cacheDir = await _ensureCacheDir();
      final String fileName = _initialsFileName(trimmedName);
      final String filePath = path.join(cacheDir.path, fileName);
      final File file = File(filePath);

      // Check disk cache.
      if (file.existsSync() && file.lengthSync() > 0) {
        _initialsPathCache[trimmedName] = filePath;
        return filePath;
      }

      // Render initials avatar using dart:ui Canvas.
      final Uint8List? pngBytes = await _renderInitialsPng(trimmedName);
      if (pngBytes == null || pngBytes.isEmpty) {
        return null;
      }

      await file.writeAsBytes(pngBytes, flush: true);
      _initialsPathCache[trimmedName] = filePath;

      return filePath;
    } catch (error, stackTrace) {
      _logger.d(
        'Initials avatar generation failed',
        <String, dynamic>{
          'name': trimmedName,
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      return null;
    }
  }

  /// Clears all cached avatar files from disk and memory.
  Future<void> clearCache() async {
    _urlToPathCache.clear();
    _initialsPathCache.clear();
    try {
      final Directory cacheDir = await _ensureCacheDir();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (error) {
      _logger.d(
        'Failed to clear avatar cache',
        <String, dynamic>{'error': error.toString()},
      );
    }
  }

  // ===========================================================
  // Private helpers
  // ===========================================================

  /// Renders a [_initialsAvatarSize]×[_initialsAvatarSize] PNG with a colored
  /// circle background and white initials text centered inside.
  Future<Uint8List?> _renderInitialsPng(String name) async {
    final double size = _initialsAvatarSize.toDouble();
    final String initials = _getInitials(name);
    final ui.Color bgColor = _colorForName(name);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, size, size),
    );

    // Draw colored circle background.
    final ui.Paint bgPaint = ui.Paint()..color = bgColor;
    canvas.drawCircle(
      ui.Offset(size / 2, size / 2),
      size / 2,
      bgPaint,
    );

    // Draw initials text centered.
    final double fontSize = size * 0.4;
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: const ui.Color(0xFFFFFFFF),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      ui.Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      _initialsAvatarSize,
      _initialsAvatarSize,
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();

    return byteData?.buffer.asUint8List();
  }

  /// Extracts 1-2 uppercase initials from a name.
  ///
  /// - `"John Doe"` → `"JD"`
  /// - `"Alice"` → `"A"`
  /// - `"Nguyễn Văn A"` → `"NA"`
  static String _getInitials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Returns a deterministic color for the given [name].
  static ui.Color _colorForName(String name) {
    final int hash = name.hashCode & 0x7fffffff;
    return _avatarColors[hash % _avatarColors.length];
  }

  Future<Directory> _ensureCacheDir() async {
    final Directory tempDir = await getTemporaryDirectory();
    final Directory cacheDir = Directory(
      path.join(tempDir.path, _cacheSubDir),
    );
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Converts a URL to a safe file name using its hashCode.
  String _urlToFileName(String url) {
    final int hash = url.hashCode & 0x7fffffff;
    return 'avatar_$hash.png';
  }

  /// Converts a name to a safe file name for initials avatar.
  String _initialsFileName(String name) {
    final int hash = name.hashCode & 0x7fffffff;
    return 'initials_$hash.png';
  }
}

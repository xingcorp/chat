import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/data/datasources/clipboard/clipboard_datasource.dart';
import 'package:flutter_chat_app/presentation/blocs/file_attachment/file_attachment_bloc.dart';

/// Mixin that adds clipboard image paste handling (Ctrl+V / Cmd+V)
/// to a [BaseState] widget.
///
/// Only active on web and desktop platforms.
/// Checks the clipboard for image data before allowing normal text paste.
///
/// Usage in a widget state:
/// ```dart
/// class _MyPageState extends BaseState<MyPage>
///     with ClipboardPasteHandler<MyPage> {
///
///   @override
///   FileAttachmentBloc get clipboardFileAttachmentBloc => _fileAttachmentBloc;
///
///   @override
///   ClipboardDataSource get clipboardDataSource => _clipboardDataSource;
/// }
/// ```
mixin ClipboardPasteHandler<T extends BaseStatefulWidget> on BaseState<T> {
  /// The file attachment BLoC to send pasted images to
  FileAttachmentBloc get clipboardFileAttachmentBloc;

  /// The clipboard data source to read images from
  ClipboardDataSource get clipboardDataSource;

  /// Whether clipboard paste is supported on this platform
  bool get isClipboardPasteSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  /// Handle a paste action. Returns true if an image was pasted,
  /// false if the paste should be handled normally (e.g., text paste).
  ///
  /// Call this from a keyboard shortcut handler for Ctrl+V / Cmd+V.
  Future<bool> handleClipboardPaste() async {
    if (!isClipboardPasteSupported) return false;

    try {
      final imageData = await clipboardDataSource.getImageFromClipboard();
      if (imageData != null) {
        clipboardFileAttachmentBloc.add(
          ImagePasted(
            bytes: imageData.bytes,
            fileName: imageData.fileName,
          ),
        );
        return true;
      }
    } catch (_) {
      // Fall through to normal paste
    }

    return false;
  }

  /// Creates a keyboard shortcut intent for image paste.
  ///
  /// Use this in a [Shortcuts] widget to intercept Ctrl+V / Cmd+V
  /// before the default text paste handler.
  Map<ShortcutActivator, Intent> get clipboardPasteShortcuts {
    if (!isClipboardPasteSupported) return {};

    return {
      const SingleActivator(LogicalKeyboardKey.keyV, control: true):
          const _PasteImageIntent(),
      const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
          const _PasteImageIntent(),
    };
  }
}

/// Intent for pasting images from clipboard
class PasteImageIntent extends Intent {
  const PasteImageIntent();
}

// Private alias for internal use
class _PasteImageIntent extends PasteImageIntent {
  const _PasteImageIntent();
}

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/datasources/clipboard/clipboard_datasource.dart';
import 'package:flutter_chat_app/presentation/blocs/file_attachment/file_attachment_bloc.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Mixin that adds clipboard paste handling (Ctrl+V / Cmd+V) to a
/// [BaseState] widget.
///
/// Supports:
/// - **Image data paste** — screenshots, copied image content
/// - **File path paste** — files copied via Ctrl+C from OS file explorer
///
/// Only active on web and desktop platforms.
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
  /// The file attachment BLoC to send pasted images/files to
  FileAttachmentBloc get clipboardFileAttachmentBloc;

  /// The clipboard data source to read images/files from
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

  /// Handle a paste action.
  ///
  /// Tries in order:
  /// 1. Read file paths from clipboard (Ctrl+C'd files from file explorer)
  /// 2. Read image bytes from clipboard (screenshot capture, image content)
  /// 3. Fall through to normal text paste
  ///
  /// Returns true if files/images were pasted, false otherwise.
  ///
  /// Call this from a keyboard shortcut handler for Ctrl+V / Cmd+V.
  Future<bool> handleClipboardPaste() async {
    LogUtils.d('PASTE_DEBUG', '>>> handleClipboardPaste() called');
    LogUtils.d('PASTE_DEBUG', '>>> isClipboardPasteSupported=$isClipboardPasteSupported, kIsWeb=$kIsWeb');

    if (!isClipboardPasteSupported) {
      LogUtils.d('PASTE_DEBUG', '>>> NOT SUPPORTED — returning false');
      return false;
    }

    try {
      // 1. Try reading file paths first (Ctrl+C from file explorer)
      if (!kIsWeb) {
        LogUtils.d('PASTE_DEBUG', '>>> Step 1: Trying getFilePathsFromClipboard()...');
        final filePaths =
            await clipboardDataSource.getFilePathsFromClipboard();
        LogUtils.d('PASTE_DEBUG', '>>> getFilePathsFromClipboard() returned ${filePaths.length} paths: $filePaths');

        if (filePaths.isNotEmpty) {
          final pickedFiles = <PickedFileInfo>[];
          for (final filePath in filePaths) {
            final file = File(filePath);
            final fileName = p.basename(filePath);
            final fileSize = await file.length();
            final mimeType =
                lookupMimeType(fileName) ?? 'application/octet-stream';

            LogUtils.d('PASTE_DEBUG', '>>> File: $fileName, size=$fileSize, mime=$mimeType');

            pickedFiles.add(PickedFileInfo(
              path: filePath,
              name: fileName,
              size: fileSize,
              mimeType: mimeType,
            ));
          }

          if (pickedFiles.isNotEmpty) {
            LogUtils.d('PASTE_DEBUG', '>>> Dispatching FilesPicked with ${pickedFiles.length} files');
            clipboardFileAttachmentBloc.add(
              FilesPicked(files: pickedFiles),
            );
            return true;
          }
        }
      }

      // 2. Try reading image bytes (screenshot, image content)
      LogUtils.d('PASTE_DEBUG', '>>> Step 2: Trying getImageFromClipboard()...');
      final imageData = await clipboardDataSource.getImageFromClipboard();
      LogUtils.d('PASTE_DEBUG', '>>> getImageFromClipboard() returned: ${imageData != null ? "image(${imageData.bytes.length} bytes)" : "null"}');

      if (imageData != null) {
        LogUtils.d('PASTE_DEBUG', '>>> Dispatching ImagePasted');
        clipboardFileAttachmentBloc.add(
          ImagePasted(
            bytes: imageData.bytes,
            fileName: imageData.fileName,
          ),
        );
        return true;
      }
    } catch (e, stack) {
      LogUtils.e('PASTE_DEBUG', '>>> EXCEPTION in handleClipboardPaste: $e\n$stack');
    }

    LogUtils.d('PASTE_DEBUG', '>>> No file/image found — returning false');
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

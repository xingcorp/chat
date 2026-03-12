import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Wraps [QuillController] and provides a simplified API for the
/// composer UI layer.
///
/// Responsibilities:
/// - Lifecycle management (`dispose`)
/// - Conversion helpers: `plainText`, `deltaJson`, `isEmpty`
/// - Loading / clearing the document
/// - Exposing a change stream for debounced draft saves
///
/// This class lives in the Presentation layer and is allowed to
/// import `flutter_quill`.
class QuillComposerController {
  QuillComposerController() {
    _quillController = QuillController.basic();
    _quillController.document.changes.listen((_) {
      _changeController.add(null);
    });
  }

  late final QuillController _quillController;

  final StreamController<void> _changeController =
      StreamController<void>.broadcast();

  /// The underlying [QuillController] for use by [QuillEditor] and
  /// toolbar widgets. Treat as read-only outside this class.
  QuillController get quillController => _quillController;

  // ─────────────────── Getters ───────────────────

  /// Extract plain text from the current document.
  ///
  /// Trims the trailing newline that Quill always appends.
  String get plainText {
    final raw = _quillController.document.toPlainText();
    // Quill documents always end with '\n'; strip for chat.
    return raw.endsWith('\n') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Serialise the current document to a JSON-encoded Delta ops array.
  ///
  /// Example output: `[{"insert":"Hello "},{"insert":"world","attributes":{"bold":true}},{"insert":"\n"}]`
  String get deltaJson {
    return jsonEncode(_quillController.document.toDelta().toJson());
  }

  /// Whether the document is empty (only the mandatory trailing
  /// newline, no real content).
  bool get isEmpty {
    final text = _quillController.document.toPlainText();
    return text == '\n' || text.isEmpty;
  }

  /// Whether the document contains any rich-text attributes.
  bool get hasFormatting {
    final ops = _quillController.document.toDelta().toJson();
    for (final op in ops) {
      final attrs = op['attributes'];
      if (attrs is Map && attrs.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  // ─────────────────── Streams ───────────────────

  /// Fires whenever the document content changes.
  Stream<void> get onDocumentChanged => _changeController.stream;

  // ─────────────────── Mutations ───────────────────

  /// Replace the editor content with a Delta JSON string.
  ///
  /// Used when restoring a draft.
  void loadDeltaJson(String json) {
    try {
      final decoded = jsonDecode(json);
      final List<dynamic> ops;
      if (decoded is List) {
        ops = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
        ops = decoded['ops'] as List<dynamic>;
      } else {
        return;
      }
      final delta = Delta.fromJson(ops);
      _quillController.document = Document.fromDelta(delta);
      _quillController.moveCursorToEnd();
    } catch (_) {
      // Silently ignore corrupt delta — editor keeps current state.
    }
  }

  /// Replace the editor content with plain text.
  ///
  /// Used when restoring a draft that was saved as plain text only.
  void loadPlainText(String text) {
    if (text.isEmpty) {
      clear();
      return;
    }
    final delta = Delta()..insert('$text\n');
    _quillController.document = Document.fromDelta(delta);
    _quillController.moveCursorToEnd();
  }

  /// Clear the editor content (reset to empty document).
  void clear() {
    _quillController.document = Document()..insert(0, '');
    _quillController.moveCursorToStart();
  }

  /// Insert plain text at the current cursor position.
  ///
  /// Used for inserting emoji or other text fragments from external pickers.
  void insertText(String text) {
    if (text.isEmpty) return;
    final index = _quillController.selection.baseOffset;
    final insertAt = index < 0 ? _quillController.document.length - 1 : index;
    _quillController.document.insert(insertAt, text);
    _quillController.updateSelection(
      TextSelection.collapsed(offset: insertAt + text.length),
      ChangeSource.local,
    );
  }

  /// Release all resources.
  void dispose() {
    _changeController.close();
    _quillController.dispose();
  }
}

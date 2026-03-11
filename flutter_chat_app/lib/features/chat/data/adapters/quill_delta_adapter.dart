import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:injectable/injectable.dart';

/// Adapter interface for Quill Delta JSON operations.
///
/// Located in the Data layer because it imports [flutter_quill]
/// (infrastructure dependency). The Domain layer uses [String?]
/// for `contentDelta` and never touches this adapter directly.
abstract class IQuillDeltaAdapter {
  /// Convert a Delta JSON string to plain text.
  ///
  /// Returns an empty string if [deltaJson] is null, empty, or invalid.
  String deltaJsonToPlainText(String deltaJson);

  /// Check whether [json] is a valid Quill Delta JSON string.
  ///
  /// A valid Delta JSON is a JSON object with an `ops` array where each
  /// operation has at least an `insert` key.
  bool isValidDeltaJson(String json);

  /// Check whether [deltaJson] contains any rich formatting attributes.
  ///
  /// Returns `false` for plain text–only documents or invalid JSON.
  bool hasRichFormatting(String deltaJson);

  /// Create an empty Quill Delta JSON string.
  ///
  /// Equivalent to a document with a single newline insert:
  /// `{"ops":[{"insert":"\n"}]}`
  String createEmptyDeltaJson();

  /// Create a Delta JSON string from plain text.
  ///
  /// Inserts the text followed by a trailing newline (Quill convention).
  String plainTextToDeltaJson(String text);
}

/// Concrete adapter backed by [flutter_quill].
@LazySingleton(as: IQuillDeltaAdapter)
class QuillDeltaAdapter implements IQuillDeltaAdapter {
  @override
  String deltaJsonToPlainText(String deltaJson) {
    try {
      final delta = Delta.fromJson(jsonDecode(deltaJson) as List<dynamic>);
      final document = Document.fromDelta(delta);
      return document.toPlainText().trimRight();
    } catch (_) {
      return '';
    }
  }

  @override
  bool isValidDeltaJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        // Raw ops array: [{"insert": "hello\n"}]
        Delta.fromJson(decoded);
        return true;
      }
      if (decoded is Map<String, dynamic>) {
        final ops = decoded['ops'];
        if (ops is List) {
          Delta.fromJson(ops);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  bool hasRichFormatting(String deltaJson) {
    try {
      final decoded = jsonDecode(deltaJson);
      final List<dynamic> ops;
      if (decoded is List) {
        ops = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
        ops = decoded['ops'] as List<dynamic>;
      } else {
        return false;
      }

      for (final op in ops) {
        if (op is Map<String, dynamic>) {
          final attributes = op['attributes'];
          if (attributes is Map && attributes.isNotEmpty) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  String createEmptyDeltaJson() {
    return jsonEncode([
      {'insert': '\n'},
    ]);
  }

  @override
  String plainTextToDeltaJson(String text) {
    final content = text.isEmpty ? '' : text;
    return jsonEncode([
      {'insert': '$content\n'},
    ]);
  }
}

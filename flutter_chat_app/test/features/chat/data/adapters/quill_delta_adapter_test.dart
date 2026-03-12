import 'dart:convert';

import 'package:flutter_chat_app/features/chat/data/adapters/quill_delta_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late QuillDeltaAdapter adapter;

  setUp(() {
    adapter = QuillDeltaAdapter();
  });

  group('deltaJsonToPlainText', () {
    test('extracts plain text from simple Delta', () {
      final delta = jsonEncode([
        {'insert': 'Hello world\n'},
      ]);
      expect(adapter.deltaJsonToPlainText(delta), 'Hello world');
    });

    test('extracts plain text from formatted Delta', () {
      final delta = jsonEncode([
        {'insert': 'Hello '},
        {
          'insert': 'bold',
          'attributes': {'bold': true},
        },
        {'insert': ' world\n'},
      ]);
      expect(adapter.deltaJsonToPlainText(delta), 'Hello bold world');
    });

    test('returns empty string for invalid JSON', () {
      expect(adapter.deltaJsonToPlainText('not json'), '');
    });

    test('returns empty string for empty Delta', () {
      final delta = jsonEncode([
        {'insert': '\n'},
      ]);
      expect(adapter.deltaJsonToPlainText(delta), '');
    });
  });

  group('isValidDeltaJson', () {
    test('returns true for valid ops array', () {
      final delta = jsonEncode([
        {'insert': 'Hello\n'},
      ]);
      expect(adapter.isValidDeltaJson(delta), true);
    });

    test('returns true for valid ops object', () {
      final delta = jsonEncode({
        'ops': [
          {'insert': 'Hello\n'},
        ],
      });
      expect(adapter.isValidDeltaJson(delta), true);
    });

    test('returns false for invalid JSON', () {
      expect(adapter.isValidDeltaJson('not json'), false);
    });

    test('returns false for non-Delta JSON', () {
      expect(adapter.isValidDeltaJson('{"key": "value"}'), false);
    });
  });

  group('hasRichFormatting', () {
    test('returns false for plain text Delta', () {
      final delta = jsonEncode([
        {'insert': 'Hello world\n'},
      ]);
      expect(adapter.hasRichFormatting(delta), false);
    });

    test('returns true for bold text Delta', () {
      final delta = jsonEncode([
        {
          'insert': 'bold',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
      expect(adapter.hasRichFormatting(delta), true);
    });

    test('returns true for link Delta', () {
      final delta = jsonEncode([
        {
          'insert': 'click here',
          'attributes': {'link': 'https://example.com'},
        },
        {'insert': '\n'},
      ]);
      expect(adapter.hasRichFormatting(delta), true);
    });

    test('returns false for invalid JSON', () {
      expect(adapter.hasRichFormatting('not json'), false);
    });
  });

  group('createEmptyDeltaJson', () {
    test('creates valid empty Delta', () {
      final empty = adapter.createEmptyDeltaJson();
      expect(adapter.isValidDeltaJson(empty), true);
      expect(adapter.deltaJsonToPlainText(empty), '');
    });
  });

  group('plainTextToDeltaJson', () {
    test('creates valid Delta from text', () {
      final delta = adapter.plainTextToDeltaJson('Hello world');
      expect(adapter.isValidDeltaJson(delta), true);
      expect(adapter.deltaJsonToPlainText(delta), 'Hello world');
    });

    test('creates empty Delta from empty text', () {
      final delta = adapter.plainTextToDeltaJson('');
      expect(adapter.isValidDeltaJson(delta), true);
    });
  });
}

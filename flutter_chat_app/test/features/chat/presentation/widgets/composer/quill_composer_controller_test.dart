import 'dart:convert';

import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/quill_composer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late QuillComposerController controller;

  setUp(() {
    controller = QuillComposerController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('isEmpty', () {
    test('returns true for new controller', () {
      expect(controller.isEmpty, true);
    });
  });

  group('plainText', () {
    test('returns empty string for new controller', () {
      expect(controller.plainText, '');
    });
  });

  group('deltaJson', () {
    test('returns valid JSON for new controller', () {
      final json = controller.deltaJson;
      expect(() => jsonDecode(json), returnsNormally);
    });
  });

  group('hasFormatting', () {
    test('returns false for new controller', () {
      expect(controller.hasFormatting, false);
    });
  });

  group('loadDeltaJson', () {
    test('loads valid Delta JSON ops array', () {
      final delta = jsonEncode([
        {'insert': 'Hello world\n'},
      ]);
      controller.loadDeltaJson(delta);
      expect(controller.plainText, 'Hello world');
      expect(controller.isEmpty, false);
    });

    test('loads valid Delta JSON with ops wrapper', () {
      final delta = jsonEncode({
        'ops': [
          {'insert': 'Test\n'},
        ],
      });
      controller.loadDeltaJson(delta);
      expect(controller.plainText, 'Test');
    });

    test('ignores invalid Delta JSON', () {
      controller.loadDeltaJson('not json');
      expect(controller.isEmpty, true);
    });
  });

  group('loadPlainText', () {
    test('loads plain text', () {
      controller.loadPlainText('Hello');
      expect(controller.plainText, 'Hello');
      expect(controller.isEmpty, false);
    });

    test('clears on empty text', () {
      controller.loadPlainText('Hello');
      controller.loadPlainText('');
      expect(controller.isEmpty, true);
    });
  });

  group('clear', () {
    test('clears content', () {
      controller.loadPlainText('Hello');
      controller.clear();
      expect(controller.isEmpty, true);
      expect(controller.plainText, '');
    });
  });

  group('onDocumentChanged', () {
    test('emits when document changes', () async {
      var changeCount = 0;
      final sub = controller.onDocumentChanged.listen((_) {
        changeCount++;
      });

      controller.loadPlainText('Hello');
      await Future<void>.delayed(Duration.zero);

      expect(changeCount, greaterThan(0));
      await sub.cancel();
    });
  });
}

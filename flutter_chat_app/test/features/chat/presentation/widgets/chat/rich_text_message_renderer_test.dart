import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/rich_text_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({
    required String plainText,
    String? deltaJson,
    bool isSender = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RichTextBubble(
          plainText: plainText,
          deltaJson: deltaJson,
          isSender: isSender,
        ),
      ),
    );
  }

  group('RichTextBubble', () {
    testWidgets('renders plain text when deltaJson is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        plainText: 'Hello world',
        deltaJson: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders plain text when deltaJson is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        plainText: 'Fallback text',
        deltaJson: '',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fallback text'), findsOneWidget);
    });

    testWidgets('renders plain text when deltaJson is invalid',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        plainText: 'Fallback text',
        deltaJson: 'not valid json',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fallback text'), findsOneWidget);
    });

    testWidgets('renders QuillEditor when deltaJson is valid', (tester) async {
      final delta = jsonEncode([
        {'insert': 'Rich text content\n'},
      ]);

      await tester.pumpWidget(buildTestWidget(
        plainText: 'Fallback',
        deltaJson: delta,
      ));
      await tester.pumpAndSettle();

      // When valid delta is provided, QuillEditor is rendered
      // (plain text fallback should NOT be found)
      expect(find.text('Fallback'), findsNothing);
    });

    testWidgets('renders formatted Delta with bold text', (tester) async {
      final delta = jsonEncode([
        {
          'insert': 'Bold text',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);

      await tester.pumpWidget(buildTestWidget(
        plainText: 'Fallback',
        deltaJson: delta,
        isSender: true,
      ));
      await tester.pumpAndSettle();

      // QuillEditor should render (not the plain text fallback)
      expect(find.text('Fallback'), findsNothing);
    });

    testWidgets('handles ops wrapper format', (tester) async {
      final delta = jsonEncode({
        'ops': [
          {'insert': 'Wrapped format\n'},
        ],
      });

      await tester.pumpWidget(buildTestWidget(
        plainText: 'Fallback',
        deltaJson: delta,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fallback'), findsNothing);
    });

    testWidgets('updates when deltaJson changes', (tester) async {
      final delta1 = jsonEncode([
        {'insert': 'First\n'},
      ]);
      final delta2 = jsonEncode([
        {'insert': 'Second\n'},
      ]);

      await tester.pumpWidget(buildTestWidget(
        plainText: 'Fallback',
        deltaJson: delta1,
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildTestWidget(
        plainText: 'Fallback',
        deltaJson: delta2,
      ));
      await tester.pumpAndSettle();

      // Widget should update without errors
      expect(find.byType(RichTextBubble), findsOneWidget);
    });
  });
}

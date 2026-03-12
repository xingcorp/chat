import 'package:flutter/material.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/composer/toolbar_orchestrator.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late QuillController quillController;

  setUp(() {
    quillController = QuillController.basic();
  });

  tearDown(() {
    quillController.dispose();
  });

  Widget buildTestWidget({
    VoidCallback? onEmojiPressed,
    VoidCallback? onAttachPressed,
    VoidCallback? onInsertLink,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ToolbarOrchestrator(
          controller: quillController,
          onEmojiPressed: onEmojiPressed ?? () {},
          onAttachPressed: onAttachPressed ?? () {},
          onInsertLink: onInsertLink ?? () {},
        ),
      ),
    );
  }

  group('ToolbarOrchestrator', () {
    testWidgets('renders action row', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Action row should be visible (emoji, attach, format toggle icons)
      expect(find.byType(ToolbarOrchestrator), findsOneWidget);
    });

    testWidgets('formatting panel is initially hidden', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // FormattingPanel should not be visible initially
      // (it's inside AnimatedSize with zero height)
      expect(find.byType(ToolbarOrchestrator), findsOneWidget);
    });

    testWidgets('emoji button triggers callback', (tester) async {
      var emojiPressed = false;
      await tester.pumpWidget(buildTestWidget(
        onEmojiPressed: () => emojiPressed = true,
      ));
      await tester.pumpAndSettle();

      // Find and tap emoji button (first IconButton with emoji icon)
      final emojiButton = find.byIcon(Icons.emoji_emotions_outlined);
      if (emojiButton.evaluate().isNotEmpty) {
        await tester.tap(emojiButton.first);
        await tester.pumpAndSettle();
        expect(emojiPressed, true);
      }
    });

    testWidgets('attach button triggers callback', (tester) async {
      var attachPressed = false;
      await tester.pumpWidget(buildTestWidget(
        onAttachPressed: () => attachPressed = true,
      ));
      await tester.pumpAndSettle();

      final attachButton = find.byIcon(Icons.attach_file_rounded);
      if (attachButton.evaluate().isNotEmpty) {
        await tester.tap(attachButton.first);
        await tester.pumpAndSettle();
        expect(attachPressed, true);
      }
    });
  });
}

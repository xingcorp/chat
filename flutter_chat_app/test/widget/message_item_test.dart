import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/presentation/widgets/message_item.dart';

import '../test_config.dart';

/// **ENTERPRISE MESSAGE ITEM WIDGET TESTS**
///
/// Comprehensive widget tests for MessageItem component with full UI validation,
/// interaction testing, and performance verification.
///
/// **Test Coverage:**
/// - Widget rendering for all message types
/// - User interactions (tap, long press)
/// - Visual appearance validation
/// - Performance and accessibility
///
/// **Architecture**: Widget testing with enterprise standards

void main() {
  group('MessageItem Widget', () {
    late ChatMessage testMessage;
    late MessageSender testSender;

    setUp(() async {
      await TestConfig.initializeTestEnvironment();
      
      testSender = MessageSender(
        id: 'test_user_1',
        name: 'Test User',
        avatar: null,
      );
      
      testMessage = TestDataFactory.createTestMessage(
        content: 'Test message content',
        sender: testSender,
      );
    });

    tearDown(() async {
      await TestConfig.cleanup();
    });

    group('Rendering', () {
      testWidgets('should render text message correctly', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.text('Test message content'), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        
        // Verify message bubble is displayed
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should render current user message with different styling', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: true,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.text('Test message content'), findsOneWidget);
        
        // Verify current user styling
        final container = tester.widget<Container>(find.byType(Container).first);
        expect(container.alignment, equals(Alignment.centerRight));
      });

      testWidgets('should render message timestamp', (WidgetTester tester) async {
        // Arrange
        final messageWithTime = TestDataFactory.createTestMessage(
          content: 'Test message',
          createdAt: DateTime(2024, 1, 1, 12, 0),
        );
        
        final widget = MessageItem(
          message: messageWithTime,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.text('Test message'), findsOneWidget);
        // Timestamp should be displayed (format may vary)
        expect(find.byType(Text), findsAtLeastNWidgets(2));
      });

      testWidgets('should render image message correctly', (WidgetTester tester) async {
        // Arrange
        final imageMessage = TestDataFactory.createTestMessage(
          content: 'https://example.com/image.jpg',
          contentType: ContentType.image,
        );
        
        final widget = MessageItem(
          message: imageMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('https://example.com/image.jpg'), findsOneWidget);
      });

      testWidgets('should render file message correctly', (WidgetTester tester) async {
        // Arrange
        final fileMessage = TestDataFactory.createTestMessage(
          content: 'document.pdf',
          contentType: ContentType.file,
        );
        
        final widget = MessageItem(
          message: fileMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.text('document.pdf'), findsOneWidget);
        expect(find.byIcon(Icons.attach_file), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('should handle tap gesture', (WidgetTester tester) async {
        // Arrange
        bool tapped = false;
        final widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
          onTap: () {
            tapped = true;
          },
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));
        await tester.tap(find.byType(MessageItem));
        await tester.pump();

        // Assert
        expect(tapped, isTrue);
      });

      testWidgets('should handle long press gesture', (WidgetTester tester) async {
        // Arrange
        bool longPressed = false;
        final widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
          onLongPress: () {
            longPressed = true;
          },
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));
        await tester.longPress(find.byType(MessageItem));
        await tester.pump();

        // Assert
        expect(longPressed, isTrue);
      });

      testWidgets('should not handle gestures when callbacks are null', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act & Assert
        await tester.pumpWidget(TestConfig.createTestWidget(widget));
        
        // Should not throw when tapping without callbacks
        await tester.tap(find.byType(MessageItem));
        await tester.pump();
        
        await tester.longPress(find.byType(MessageItem));
        await tester.pump();
        
        // Test passes if no exceptions are thrown
      });
    });

    group('Visual Appearance', () {
      testWidgets('should have correct colors for current user', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: true,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration?;
        
        // Verify current user message has appropriate styling
        expect(decoration?.color, isNotNull);
      });

      testWidgets('should have correct colors for other user', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration?;
        
        // Verify other user message has appropriate styling
        expect(decoration?.color, isNotNull);
      });

      testWidgets('should have rounded corners', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration?;
        
        expect(decoration?.borderRadius, isNotNull);
      });
    });

    group('Performance', () {
      testWidgets('should render within performance target', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act & Assert
        final duration = await TestConfig.measurePerformance(() async {
          await tester.pumpWidget(TestConfig.createTestWidget(widget));
          await TestUtils.pumpAndSettleWithTimeout(tester);
        });

        expect(duration, TestMatchers.takesLessThan(const Duration(milliseconds: 100)));
      });

      testWidgets('should handle multiple messages efficiently', (WidgetTester tester) async {
        // Arrange
        final messages = List.generate(10, (index) => 
          TestDataFactory.createTestMessage(
            id: 'msg_$index',
            content: 'Message $index',
          )
        );

        final widgets = messages.map((msg) => MessageItem(
          message: msg,
          sender: testSender,
          isCurrentUser: index % 2 == 0,
        )).toList();

        // Act & Assert
        final duration = await TestConfig.measurePerformance(() async {
          await tester.pumpWidget(TestConfig.createTestWidget(
            Column(children: widgets),
          ));
          await TestUtils.pumpAndSettleWithTimeout(tester);
        });

        expect(duration, TestMatchers.takesLessThan(const Duration(milliseconds: 500)));
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.bySemanticsLabel('Message from Test User'), findsOneWidget);
        expect(find.bySemanticsLabel('Test message content'), findsOneWidget);
      });

      testWidgets('should support screen readers', (WidgetTester tester) async {
        // Arrange
        const widget = MessageItem(
          message: testMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        final semantics = tester.getSemantics(find.byType(MessageItem));
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty message content', (WidgetTester tester) async {
        // Arrange
        final emptyMessage = TestDataFactory.createTestMessage(content: '');
        const widget = MessageItem(
          message: emptyMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.text(''), findsOneWidget);
        expect(find.byType(MessageItem), findsOneWidget);
      });

      testWidgets('should handle very long message content', (WidgetTester tester) async {
        // Arrange
        final longContent = 'A' * 1000;
        final longMessage = TestDataFactory.createTestMessage(content: longContent);
        const widget = MessageItem(
          message: longMessage,
          sender: testSender,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.text(longContent), findsOneWidget);
        expect(find.byType(MessageItem), findsOneWidget);
      });

      testWidgets('should handle null sender avatar', (WidgetTester tester) async {
        // Arrange
        final senderWithoutAvatar = MessageSender(
          id: 'test_user_1',
          name: 'Test User',
          avatar: null,
        );
        
        const widget = MessageItem(
          message: testMessage,
          sender: senderWithoutAvatar,
          isCurrentUser: false,
        );

        // Act
        await tester.pumpWidget(TestConfig.createTestWidget(widget));

        // Assert
        expect(find.byType(MessageItem), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
      });
    });
  });
}

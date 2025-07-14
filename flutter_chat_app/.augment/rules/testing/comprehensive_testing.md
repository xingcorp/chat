# Comprehensive Testing Rules - Enterprise Messaging App

**Type**: Always  
**Description**: Complete testing strategy with 90%+ coverage, automated testing pipelines, and enterprise-quality assurance standards

## Testing Architecture Overview

### Testing Pyramid Implementation
```dart
class TestingStrategy {
  static const Map<TestType, TestingRequirements> requirements = {
    TestType.unit: TestingRequirements(
      coverage: 0.95, // 95% for business logic
      executionTime: Duration(seconds: 30),
      parallelization: true,
      mockingStrategy: MockingStrategy.comprehensive,
    ),
    TestType.widget: TestingRequirements(
      coverage: 0.85, // 85% for UI components
      executionTime: Duration(minutes: 2),
      parallelization: true,
      mockingStrategy: MockingStrategy.selective,
    ),
    TestType.integration: TestingRequirements(
      coverage: 0.80, // 80% for critical user flows
      executionTime: Duration(minutes: 10),
      parallelization: false,
      mockingStrategy: MockingStrategy.minimal,
    ),
    TestType.e2e: TestingRequirements(
      coverage: 0.70, // 70% for end-to-end scenarios
      executionTime: Duration(minutes: 30),
      parallelization: false,
      mockingStrategy: MockingStrategy.none,
    ),
  };
  
  static Future<TestResults> runComprehensiveTests() async {
    final results = <TestType, TestResult>{};
    
    // Run tests in order of speed
    for (final testType in [TestType.unit, TestType.widget, TestType.integration, TestType.e2e]) {
      final requirement = requirements[testType]!;
      
      print('🧪 Running ${testType.name} tests...');
      final startTime = DateTime.now();
      
      final result = await _runTestType(testType, requirement);
      results[testType] = result;
      
      final duration = DateTime.now().difference(startTime);
      print('✅ ${testType.name} tests completed in ${duration.inSeconds}s');
      
      // Fail fast if critical tests fail
      if (!result.passed && testType == TestType.unit) {
        throw TestFailureException('Unit tests failed, stopping test execution');
      }
    }
    
    return TestResults(results);
  }
}
```

### Unit Testing Standards
```dart
// Example: Message BLoC comprehensive unit testing
class MessageBlocTest {
  late MessageBloc messageBloc;
  late MockGetMessagesUseCase mockGetMessages;
  late MockSendMessageUseCase mockSendMessage;
  late MockWebSocketService mockWebSocketService;
  
  setUp(() {
    mockGetMessages = MockGetMessagesUseCase();
    mockSendMessage = MockSendMessageUseCase();
    mockWebSocketService = MockWebSocketService();
    
    messageBloc = MessageBloc(
      getMessages: mockGetMessages,
      sendMessage: mockSendMessage,
      webSocketService: mockWebSocketService,
    );
  });
  
  group('MessageBloc Unit Tests', () {
    // Test all possible states
    blocTest<MessageBloc, MessageState>(
      'emits [loading, loaded] when messages loaded successfully',
      build: () {
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Right([testMessage]));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageEvent.loadMessages(chatId: 'chat-123')),
      expect: () => [
        MessageState.loading(),
        MessageState.loaded(messages: [testMessage], chatId: 'chat-123'),
      ],
      verify: (_) {
        verify(() => mockGetMessages(any())).called(1);
      },
    );
    
    // Test error scenarios
    blocTest<MessageBloc, MessageState>(
      'emits [loading, error] when loading messages fails',
      build: () {
        when(() => mockGetMessages(any()))
            .thenAnswer((_) async => Left(NetworkFailure('Connection failed')));
        return messageBloc;
      },
      act: (bloc) => bloc.add(MessageEvent.loadMessages(chatId: 'chat-123')),
      expect: () => [
        MessageState.loading(),
        MessageState.error(
          message: 'Connection failed',
          failure: isA<NetworkFailure>(),
        ),
      ],
    );
    
    // Test optimistic updates
    blocTest<MessageBloc, MessageState>(
      'handles optimistic updates correctly',
      build: () => messageBloc,
      seed: () => MessageState.loaded(messages: [], chatId: 'chat-123'),
      act: (bloc) {
        when(() => mockSendMessage(any()))
            .thenAnswer((_) async => Right(testMessage));
        bloc.add(MessageEvent.sendMessage(
          chatId: 'chat-123',
          content: 'Hello',
          type: MessageType.text,
        ));
      },
      expect: () => [
        // Optimistic update
        MessageState.loaded(
          messages: [isA<ChatMessage>()],
          chatId: 'chat-123',
        ),
        // Real message update
        MessageState.loaded(
          messages: [testMessage],
          chatId: 'chat-123',
        ),
      ],
    );
    
    // Test real-time message handling
    blocTest<MessageBloc, MessageState>(
      'handles real-time messages correctly',
      build: () => messageBloc,
      seed: () => MessageState.loaded(
        messages: [existingMessage],
        chatId: 'chat-123',
      ),
      act: (bloc) => bloc.add(MessageEvent.receiveMessage(message: newMessage)),
      expect: () => [
        MessageState.loaded(
          messages: [newMessage, existingMessage],
          chatId: 'chat-123',
        ),
      ],
    );
    
    // Test edge cases
    test('handles empty message content validation', () async {
      when(() => mockSendMessage(any()))
          .thenAnswer((_) async => Left(ValidationFailure('Message cannot be empty')));
      
      messageBloc.add(MessageEvent.sendMessage(
        chatId: 'chat-123',
        content: '',
        type: MessageType.text,
      ));
      
      await expectLater(
        messageBloc.stream,
        emitsInOrder([
          isA<MessageError>().having(
            (state) => state.message,
            'message',
            'Message cannot be empty',
          ),
        ]),
      );
    });
  });
}
```

### Widget Testing Standards
```dart
class MessageWidgetTest {
  testWidgets('MessageTile displays message content correctly', (tester) async {
    // Arrange
    const testMessage = ChatMessage(
      id: 'msg-123',
      chatId: 'chat-456',
      content: 'Hello, World!',
      type: MessageType.text,
      sender: testUser,
      createdAt: testDateTime,
    );
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageTile(message: testMessage),
        ),
      ),
    );
    
    // Assert
    expect(find.text('Hello, World!'), findsOneWidget);
    expect(find.text(testUser.displayName), findsOneWidget);
    expect(find.byType(MessageStatusIndicator), findsOneWidget);
  });
  
  testWidgets('MessageTile handles long messages with overflow', (tester) async {
    const longMessage = ChatMessage(
      id: 'msg-123',
      chatId: 'chat-456',
      content: 'This is a very long message that should wrap properly and not cause overflow issues in the UI. ' * 10,
      type: MessageType.text,
      sender: testUser,
      createdAt: testDateTime,
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: MessageTile(message: longMessage),
          ),
        ),
      ),
    );
    
    // Verify no overflow
    expect(tester.takeException(), isNull);
    
    // Verify text wrapping
    final textWidget = tester.widget<Text>(find.byType(Text).first);
    expect(textWidget.overflow, TextOverflow.visible);
  });
  
  testWidgets('MessageList scrolls to bottom on new message', (tester) async {
    final messages = List.generate(50, (i) => ChatMessage(
      id: 'msg-$i',
      chatId: 'chat-123',
      content: 'Message $i',
      type: MessageType.text,
      sender: testUser,
      createdAt: DateTime.now().subtract(Duration(minutes: i)),
    ));
    
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => MockMessageBloc(),
          child: MessageListWidget(),
        ),
      ),
    );
    
    // Simulate new message
    final bloc = BlocProvider.of<MessageBloc>(tester.element(find.byType(MessageListWidget)));
    bloc.add(MessageEvent.receiveMessage(message: messages.first));
    
    await tester.pumpAndSettle();
    
    // Verify scroll position
    final scrollController = tester.widget<ListView>(find.byType(ListView)).controller;
    expect(scrollController?.position.pixels, 0); // At bottom
  });
}
```

### Integration Testing Standards
```dart
class MessageFlowIntegrationTest {
  testWidgets('Complete message sending flow', (tester) async {
    // Setup
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // Navigate to chat screen
    await tester.tap(find.byKey(Key('chat-item-123')));
    await tester.pumpAndSettle();
    
    // Type message
    await tester.enterText(find.byKey(Key('message-input')), 'Hello, integration test!');
    
    // Send message
    await tester.tap(find.byKey(Key('send-button')));
    await tester.pumpAndSettle();
    
    // Verify optimistic update
    expect(find.text('Hello, integration test!'), findsOneWidget);
    expect(find.byKey(Key('message-sending-indicator')), findsOneWidget);
    
    // Wait for server response
    await tester.pumpAndSettle(Duration(seconds: 2));
    
    // Verify message sent successfully
    expect(find.byKey(Key('message-sent-indicator')), findsOneWidget);
    expect(find.byKey(Key('message-sending-indicator')), findsNothing);
  });
  
  testWidgets('Offline message queueing and sync', (tester) async {
    // Setup offline mode
    await NetworkSimulator.setOffline();
    
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // Send message while offline
    await tester.tap(find.byKey(Key('chat-item-123')));
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byKey(Key('message-input')), 'Offline message');
    await tester.tap(find.byKey(Key('send-button')));
    await tester.pumpAndSettle();
    
    // Verify message queued
    expect(find.text('Offline message'), findsOneWidget);
    expect(find.byKey(Key('message-queued-indicator')), findsOneWidget);
    
    // Go back online
    await NetworkSimulator.setOnline();
    await tester.pumpAndSettle(Duration(seconds: 3));
    
    // Verify message synced
    expect(find.byKey(Key('message-sent-indicator')), findsOneWidget);
    expect(find.byKey(Key('message-queued-indicator')), findsNothing);
  });
}
```

### End-to-End Testing Standards
```dart
class E2ETestSuite {
  static Future<void> runCriticalUserJourneys() async {
    await _testUserRegistrationAndLogin();
    await _testMessageSendingAndReceiving();
    await _testGroupChatCreation();
    await _testFileSharing();
    await _testOfflineSync();
    await _testNotifications();
  }
  
  static Future<void> _testMessageSendingAndReceiving() async {
    final driver = FlutterDriver.connect();
    
    try {
      // User A sends message
      await driver.tap(find.byValueKey('chat-user-b'));
      await driver.enterText('Hello from User A!');
      await driver.tap(find.byValueKey('send-button'));
      
      // Verify message appears
      await driver.waitFor(find.text('Hello from User A!'));
      
      // Switch to User B's device (simulated)
      await _switchToUserB();
      
      // Verify message received
      await driver.waitFor(find.text('Hello from User A!'));
      
      // User B replies
      await driver.enterText('Hello back from User B!');
      await driver.tap(find.byValueKey('send-button'));
      
      // Switch back to User A
      await _switchToUserA();
      
      // Verify reply received
      await driver.waitFor(find.text('Hello back from User B!'));
      
    } finally {
      await driver.close();
    }
  }
}
```

## Performance Testing Standards

### Load Testing
```dart
class LoadTestSuite {
  static Future<void> runPerformanceTests() async {
    await _testMessageListPerformance();
    await _testMemoryUsageUnderLoad();
    await _testNetworkLatency();
    await _testConcurrentUsers();
  }
  
  static Future<void> _testMessageListPerformance() async {
    final stopwatch = Stopwatch()..start();
    
    // Generate large message list
    final messages = List.generate(10000, (i) => ChatMessage(
      id: 'msg-$i',
      chatId: 'chat-123',
      content: 'Performance test message $i',
      type: MessageType.text,
      sender: testUser,
      createdAt: DateTime.now().subtract(Duration(seconds: i)),
    ));
    
    // Measure rendering time
    await tester.pumpWidget(
      MaterialApp(
        home: MessageListWidget(messages: messages),
      ),
    );
    
    stopwatch.stop();
    
    // Assert performance requirements
    expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // < 2 seconds
    
    // Measure memory usage
    final memoryUsage = await _measureMemoryUsage();
    expect(memoryUsage, lessThan(150 * 1024 * 1024)); // < 150MB
    
    // Measure scroll performance
    final scrollStopwatch = Stopwatch()..start();
    await tester.fling(find.byType(ListView), Offset(0, -1000), 10000);
    await tester.pumpAndSettle();
    scrollStopwatch.stop();
    
    expect(scrollStopwatch.elapsedMilliseconds, lessThan(100)); // < 100ms
  }
}
```

## Automated Testing Pipeline

### CI/CD Integration
```yaml
# .augment/ci/testing-pipeline.yml
name: Comprehensive Testing Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Run unit tests
        run: |
          flutter test --coverage test/unit/
          
      - name: Check coverage threshold
        run: |
          dart run coverage_checker --threshold 95 --path coverage/lcov.info
          
  widget-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Run widget tests
        run: |
          flutter test --coverage test/widget/
          
      - name: Check coverage threshold
        run: |
          dart run coverage_checker --threshold 85 --path coverage/lcov.info
          
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Start test backend
        run: |
          docker-compose -f docker-compose.test.yml up -d
          
      - name: Run integration tests
        run: |
          flutter test integration_test/
          
      - name: Stop test backend
        run: |
          docker-compose -f docker-compose.test.yml down
          
  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Setup test environment
        run: |
          docker-compose -f docker-compose.e2e.yml up -d
          
      - name: Run E2E tests
        run: |
          flutter drive --target=test_driver/app.dart
          
  performance-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Run performance benchmarks
        run: |
          flutter test integration_test/performance_test.dart
          
      - name: Validate performance metrics
        run: |
          dart run performance_validator \
            --startup-time-limit 2000 \
            --memory-limit 157286400 \
            --message-delivery-limit 100
```

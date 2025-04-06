# Chiến lược Kiểm thử

Tài liệu này mô tả chiến lược kiểm thử toàn diện cho ứng dụng chat, bao gồm quy trình, công cụ, và cách tiếp cận để đảm bảo chất lượng sản phẩm.

## Tổng quan

Chúng ta áp dụng chiến lược kiểm thử kim tự tháp để cân bằng chi phí, tốc độ, và độ tin cậy:

```
        ╱╲
       /  \
      /    \
     / E2E  \
    /--------\
   /          \
  / Integration \
 /--------------\
/      Unit       \
------------------
```

- **Unit Testing**: Kiểm thử đơn vị nhỏ nhất của code (classes, functions)
- **Integration Testing**: Kiểm thử tương tác giữa các thành phần
- **E2E Testing**: Kiểm thử luồng đầy đủ của người dùng trong môi trường thực tế

## Unit Testing

### Thành phần cần test

1. **Domain Layer**:
   - Entities và các phương thức liên quan
   - Use cases và business logic
   - Repository interfaces

2. **Data Layer**:
   - Repository implementations
   - Data sources
   - Mappers từ DTO sang Entities

3. **Presentation Layer**:
   - BLoC/Cubit states và events
   - Reducers và selectors

4. **Core**:
   - Utils và helpers
   - Services

### Guidelines và Best Practices

```dart
// GOOD: Đặt tên test rõ ràng và mô tả hành vi
test('should return cached messages when network fails and cache exists', () {
  // Arrange
  when(mockNetworkSource.getMessages(any)).thenThrow(NetworkException());
  when(mockLocalSource.getMessages(any)).thenReturn([mockMessage]);
  
  // Act
  final result = messageRepository.getMessages('chat123');
  
  // Assert
  expect(result, [mockMessage]);
  verify(mockLocalSource.getMessages('chat123')).called(1);
});

// BAD: Tên test không mô tả đúng mục đích
test('test get messages', () {
  when(mockNetworkSource.getMessages(any)).thenReturn([mockMessage]);
  final result = messageRepository.getMessages('chat123');
  expect(result, [mockMessage]);
});
```

### Mocking và Test Doubles

Sử dụng các package như `mockito` hoặc `mocktail` để tạo mock objects:

```dart
@GenerateMocks([MessageRepository, NetworkInfo])
void main() {
  late MessageUseCase messageUseCase;
  late MockMessageRepository mockMessageRepository;
  late MockNetworkInfo mockNetworkInfo;
  
  setUp(() {
    mockMessageRepository = MockMessageRepository();
    mockNetworkInfo = MockNetworkInfo();
    messageUseCase = MessageUseCase(
      repository: mockMessageRepository,
      networkInfo: mockNetworkInfo,
    );
  });
  
  group('getMessages', () {
    final tChatId = 'chat_123';
    final tMessage = Message(id: '1', text: 'Test message');
    final tMessages = [tMessage];
    
    test('should check if device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockMessageRepository.getMessages(any))
          .thenAnswer((_) async => tMessages);
      
      // act
      await messageUseCase.execute(tChatId);
      
      // assert
      verify(mockNetworkInfo.isConnected);
    });
    
    group('device is online', () {
      setUp(() {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });
      
      test('should return messages from repository when call is successful',
          () async {
        // arrange
        when(mockMessageRepository.getMessages(any))
            .thenAnswer((_) async => tMessages);
        
        // act
        final result = await messageUseCase.execute(tChatId);
        
        // assert
        expect(result, equals(Right(tMessages)));
        verify(mockMessageRepository.getMessages(tChatId));
      });
    });
  });
}
```

### Testing Asynchronous Code

```dart
test('should properly handle async operations and complete futures', () async {
  // Arrange
  final completer = Completer<List<Message>>();
  when(mockRepository.getMessages(any)).thenAnswer((_) => completer.future);
  
  // Start the async operation, but don't await it yet
  final future = messageBloc.loadMessages('chat123');
  
  // Verify the loading state
  expect(messageBloc.state, isA<MessageLoadingState>());
  
  // Complete the future
  completer.complete([mockMessage]);
  
  // Now await the original operation and verify the final state
  await future;
  expect(messageBloc.state, isA<MessageLoadedState>());
  expect((messageBloc.state as MessageLoadedState).messages, [mockMessage]);
});
```

### Testing BLoC Pattern

```dart
group('ChatBloc', () {
  late ChatBloc chatBloc;
  late MockChatRepository mockChatRepository;
  
  setUp(() {
    mockChatRepository = MockChatRepository();
    chatBloc = ChatBloc(repository: mockChatRepository);
  });
  
  tearDown(() {
    chatBloc.close();
  });
  
  test('initial state should be ChatInitial', () {
    expect(chatBloc.state, equals(ChatInitial()));
  });
  
  blocTest<ChatBloc, ChatState>(
    'emits [ChatLoading, ChatLoaded] when LoadChats is added and loading succeeds',
    build: () {
      when(mockChatRepository.getChats())
          .thenAnswer((_) async => [mockChat]);
      return chatBloc;
    },
    act: (bloc) => bloc.add(LoadChats()),
    expect: () => [
      ChatLoading(),
      ChatLoaded(chats: [mockChat]),
    ],
    verify: (_) {
      verify(mockChatRepository.getChats()).called(1);
    },
  );
  
  blocTest<ChatBloc, ChatState>(
    'emits [ChatLoading, ChatError] when LoadChats is added and loading fails',
    build: () {
      when(mockChatRepository.getChats())
          .thenThrow(Exception('Network error'));
      return chatBloc;
    },
    act: (bloc) => bloc.add(LoadChats()),
    expect: () => [
      ChatLoading(),
      ChatError(message: 'Failed to load chats: Exception: Network error'),
    ],
  );
});
```

### Testing Network Requests

```dart
group('MessageApiService tests', () {
  late MessageApiService service;
  late MockHttpClient mockClient;
  
  setUp(() {
    mockClient = MockHttpClient();
    service = MessageApiService(client: mockClient);
  });
  
  test('getSingleMessage returns a Message if the http call completes successfully', () async {
    // Arrange
    final messageId = '123';
    final jsonResponse = {
      'id': messageId,
      'text': 'Hello',
      'senderId': 'user1',
      'timestamp': '2023-01-01T12:00:00Z'
    };
    
    when(mockClient.get(Uri.parse('${service.baseUrl}/messages/$messageId')))
        .thenAnswer((_) async => http.Response(json.encode(jsonResponse), 200));
    
    // Act
    final message = await service.getMessage(messageId);
    
    // Assert
    expect(message, isA<Message>());
    expect(message.id, equals(messageId));
    expect(message.text, equals('Hello'));
    expect(message.senderId, equals('user1'));
  });
  
  test('getSingleMessage throws an exception if the http call fails', () {
    // Arrange
    final messageId = '123';
    
    when(mockClient.get(Uri.parse('${service.baseUrl}/messages/$messageId')))
        .thenAnswer((_) async => http.Response('Not found', 404));
    
    // Act & Assert
    expect(() => service.getMessage(messageId), throwsA(isA<MessageNotFoundException>()));
  });
});
```

## Integration Testing

Integration tests kiểm tra sự tương tác giữa các component khác nhau trong ứng dụng.

### Các loại Integration tests

1. **Repository Integration Tests**: Kiểm tra tương tác giữa repository và các data sources
2. **Service Integration Tests**: Kiểm tra tương tác giữa các services khác nhau
3. **Screen Integration Tests**: Kiểm tra tương tác giữa UI và business logic

### Cách tiếp cận

```dart
group('MessageRepository Integration Tests', () {
  late MessageRepository repository;
  late MessageLocalDataSource localDataSource;
  late MessageRemoteDataSource remoteDataSource;
  late NetworkInfo networkInfo;
  
  setUp(() async {
    // Sử dụng Test Sqflite Provider cho local data source
    final database = await openDatabaseForTesting();
    localDataSource = MessageLocalDataSourceImpl(database: database);
    
    // Sử dụng Test Server cho remote data source
    final httpClient = http.Client();
    remoteDataSource = MessageRemoteDataSourceImpl(client: httpClient);
    
    // Sử dụng Mock NetworkInfo
    networkInfo = MockNetworkInfo();
    
    repository = MessageRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      networkInfo: networkInfo,
    );
  });
  
  group('getMessages', () {
    final chatId = 'chat_123';
    
    test('should return remote data when device is online', () async {
      // arrange
      when(networkInfo.isConnected).thenAnswer((_) async => true);
      
      // act
      final result = await repository.getMessages(chatId);
      
      // assert
      verify(networkInfo.isConnected);
      expect(result, isA<List<Message>>());
      
      // Verify data was cached
      final cachedMessages = await localDataSource.getMessages(chatId);
      expect(cachedMessages.length, equals(result.length));
    });
    
    test('should return cached data when device is offline', () async {
      // arrange
      when(networkInfo.isConnected).thenAnswer((_) async => false);
      
      // Add some test data to local cache
      await localDataSource.cacheMessages(chatId, [
        MessageModel(id: '1', text: 'Test message', senderId: 'sender1'),
      ]);
      
      // act
      final result = await repository.getMessages(chatId);
      
      // assert
      verify(networkInfo.isConnected);
      expect(result.length, 1);
      expect(result[0].text, 'Test message');
    });
  });
});
```

### Widget Testing

Widget tests là một phần quan trọng của integration testing trong Flutter.

```dart
group('ChatScreen widget tests', () {
  late MockChatBloc mockChatBloc;
  
  setUp(() {
    mockChatBloc = MockChatBloc();
  });
  
  testWidgets('displays loading indicator when state is ChatLoading',
      (WidgetTester tester) async {
    // Arrange
    when(mockChatBloc.state).thenReturn(ChatLoading());
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ChatBloc>.value(
          value: mockChatBloc,
          child: ChatScreen(),
        ),
      ),
    );
    
    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });
  
  testWidgets('displays chat list when state is ChatLoaded',
      (WidgetTester tester) async {
    // Arrange
    final chats = [
      Chat(id: '1', name: 'Test Chat 1'),
      Chat(id: '2', name: 'Test Chat 2'),
    ];
    
    when(mockChatBloc.state).thenReturn(ChatLoaded(chats: chats));
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ChatBloc>.value(
          value: mockChatBloc,
          child: ChatScreen(),
        ),
      ),
    );
    
    // Assert
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Test Chat 1'), findsOneWidget);
    expect(find.text('Test Chat 2'), findsOneWidget);
  });
  
  testWidgets('displays error message when state is ChatError',
      (WidgetTester tester) async {
    // Arrange
    when(mockChatBloc.state).thenReturn(ChatError(message: 'Error loading chats'));
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ChatBloc>.value(
          value: mockChatBloc,
          child: ChatScreen(),
        ),
      ),
    );
    
    // Assert
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Error loading chats'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
  
  testWidgets('tapping on refresh button triggers LoadChats event',
      (WidgetTester tester) async {
    // Arrange
    when(mockChatBloc.state).thenReturn(ChatError(message: 'Error loading chats'));
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ChatBloc>.value(
          value: mockChatBloc,
          child: ChatScreen(),
        ),
      ),
    );
    
    await tester.tap(find.byIcon(Icons.refresh));
    
    // Assert
    verify(mockChatBloc.add(LoadChats())).called(1);
  });
});
```

## E2E Testing

End-to-end tests kiểm tra toàn bộ luồng ứng dụng từ perspective của người dùng. Chúng ta sử dụng Flutter integration_test package.

### Cấu trúc thư mục

```
my_app/
├── integration_test/
│   ├── app_test.dart
│   ├── chat_flow_test.dart
│   └── helper/
│       ├── test_data.dart
│       └── test_helpers.dart
└── test_driver/
    └── integration_test.dart
```

### Viết E2E Tests

```dart
// integration_test/chat_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('End-to-end tests', () {
    testWidgets('Full chat flow test - create, send, and delete a message',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();
      
      // Log in (assumes login screen is the first screen)
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password123');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();
      
      // Verify we're on the chat list screen
      expect(find.byType(ChatListScreen), findsOneWidget);
      
      // Start a new chat
      await tester.tap(find.byKey(Key('new_chat_button')));
      await tester.pumpAndSettle();
      
      // Select a user to chat with
      await tester.tap(find.text('Test User'));
      await tester.pumpAndSettle();
      
      // Verify we're on the chat detail screen
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      
      // Type and send a message
      await tester.enterText(find.byKey(Key('message_input')), 'Hello, this is a test message');
      await tester.tap(find.byKey(Key('send_button')));
      await tester.pumpAndSettle();
      
      // Verify the message was sent and displayed
      expect(find.text('Hello, this is a test message'), findsOneWidget);
      
      // Test message actions (long press to get menu)
      await tester.longPress(find.text('Hello, this is a test message'));
      await tester.pumpAndSettle();
      
      // Delete the message
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      
      // Confirm delete
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      
      // Verify message is deleted
      expect(find.text('Hello, this is a test message'), findsNothing);
      
      // Navigate back to chat list
      await tester.tap(find.byKey(Key('back_button')));
      await tester.pumpAndSettle();
      
      // Verify we're back on the chat list screen
      expect(find.byType(ChatListScreen), findsOneWidget);
    });
  });
}
```

### Testing Offline Mode

```dart
testWidgets('Should handle offline mode gracefully', (WidgetTester tester) async {
  // Start the app
  app.main();
  await tester.pumpAndSettle();
  
  // Log in
  await _login(tester);
  
  // Enable network condition mocking
  await ConnectivityService.setNetworkCondition(NetworkCondition.offline);
  
  // Try to send a message
  await tester.enterText(find.byKey(Key('message_input')), 'Offline message');
  await tester.tap(find.byKey(Key('send_button')));
  await tester.pumpAndSettle();
  
  // Verify message shows as "Pending"
  expect(find.byKey(Key('pending_icon')), findsOneWidget);
  
  // Go back online
  await ConnectivityService.setNetworkCondition(NetworkCondition.online);
  
  // Wait for sync to complete
  await tester.pumpAndSettle(Duration(seconds: 3));
  
  // Verify message now shows as "Sent"
  expect(find.byKey(Key('sent_icon')), findsOneWidget);
  expect(find.byKey(Key('pending_icon')), findsNothing);
});
```

## Specialized Testing

### Performance Testing

```dart
testWidgets('Message list scrolls smoothly with 100 messages',
    (WidgetTester tester) async {
  // Setup test data
  final messages = List.generate(
    100,
    (i) => Message(
      id: 'msg_$i',
      text: 'Test message $i',
      senderId: 'sender1',
    ),
  );
  
  // Inject test data
  await tester.pumpWidget(
    MaterialApp(
      home: MessageListScreen(messages: messages),
    ),
  );
  
  // Record performance metrics
  await Performance.startPerformanceTracking();
  
  // Perform the scroll action
  final listFinder = find.byType(ListView);
  await tester.fling(listFinder, Offset(0, -500), 10000);
  
  // Wait for scrolling to settle
  await tester.pumpAndSettle();
  
  // Retrieve and verify performance results
  final metrics = await Performance.stopPerformanceTracking();
  
  expect(metrics.averageFrameRasterTime, lessThan(Duration(milliseconds: 16)));
  expect(metrics.missedFrameCount, equals(0));
});
```

### Memory Testing

```dart
// Test for memory leaks when navigating between screens
testWidgets('No memory leaks when navigating between chat list and chat detail',
    (WidgetTester tester) async {
  // Start memory tracking
  final memoryInfo = await DeviceInfo.startMemoryTracking();
  
  // Navigate to a chat detail screen and back 10 times
  for (int i = 0; i < 10; i++) {
    // Navigate to chat detail
    await tester.tap(find.byKey(Key('chat_item_0')));
    await tester.pumpAndSettle();
    
    // Verify we're on chat detail
    expect(find.byType(ChatDetailScreen), findsOneWidget);
    
    // Navigate back to chat list
    await tester.tap(find.byKey(Key('back_button')));
    await tester.pumpAndSettle();
    
    // Verify we're back on chat list
    expect(find.byType(ChatListScreen), findsOneWidget);
  }
  
  // Stop memory tracking and get final memory usage
  final memoryUsage = await DeviceInfo.stopMemoryTracking(memoryInfo);
  
  // Verify memory usage is within acceptable limits
  expect(memoryUsage.increase, lessThan(5.0)); // Less than 5MB increase
});
```

### Accessibility Testing

```dart
testWidgets('Chat screen is accessible', (WidgetTester tester) async {
  // Build our app
  await tester.pumpWidget(MyApp());
  
  // Navigate to chat screen
  await navigateToChatScreen(tester);
  
  // Get the semantics from the widget
  final SemanticsHandle handle = tester.ensureSemantics();
  
  // Check for large text support
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaleFactor: 2.0),
        child: ChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  
  // Verify that the UI adapts properly
  expect(find.byType(OverflowBox), findsNothing); // No overflow
  
  // Verify content descriptions are present for important actions
  expect(
    tester.getSemantics(find.byKey(Key('send_button'))),
    matchesSemantics(label: 'Send message', isButton: true),
  );
  
  expect(
    tester.getSemantics(find.byKey(Key('attachment_button'))),
    matchesSemantics(label: 'Add attachment', isButton: true),
  );
  
  // Clean up
  handle.dispose();
});
```

## Automated Testing

### Continuous Integration

Sử dụng GitHub Actions để tự động hóa quá trình kiểm thử:

```yaml
# .github/workflows/test.yml
name: Test
on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Verify formatting
        run: flutter format --set-exit-if-changed lib test
      
      - name: Analyze project source
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v1
        with:
          file: coverage/lcov.info
```

### Test Report Dashboard

Tạo dashboard để theo dõi kết quả test:

```dart
// lib/test_coverage_dashboard.dart
import 'dart:convert';
import 'dart:io';

void main() async {
  final coverageReport = await generateCoverageReport();
  final testResults = await runTestsAndGetResults();
  
  await generateDashboard(coverageReport, testResults);
}

Future<Map<String, dynamic>> generateCoverageReport() async {
  // Run tests with coverage
  final result = await Process.run('flutter', ['test', '--coverage']);
  if (result.exitCode != 0) {
    print('Tests failed: ${result.stderr}');
    exit(1);
  }
  
  // Parse LCOV info
  final lcovFile = File('coverage/lcov.info');
  final lcovInfo = await lcovFile.readAsString();
  
  // Generate report
  return parseLcovInfo(lcovInfo);
}

Future<Map<String, dynamic>> runTestsAndGetResults() async {
  final result = await Process.run(
    'flutter',
    ['test', '--machine'],
    stdoutEncoding: utf8,
  );
  
  // Parse the JSON output
  final lines = result.stdout.toString().split('\n');
  final testEvents = lines
      .where((line) => line.isNotEmpty)
      .map((line) => json.decode(line))
      .toList();
  
  // Extract test results
  return processTestEvents(testEvents);
}

Future<void> generateDashboard(
    Map<String, dynamic> coverageReport,
    Map<String, dynamic> testResults) async {
  // Create HTML dashboard
  final html = '''
    <!DOCTYPE html>
    <html>
    <head>
      <title>Test Coverage Dashboard</title>
      <style>
        body { font-family: Arial, sans-serif; }
        .summary { display: flex; gap: 20px; }
        .card { background: #f5f5f5; padding: 16px; border-radius: 8px; }
        .good { color: green; }
        .warning { color: orange; }
        .bad { color: red; }
      </style>
    </head>
    <body>
      <h1>Test Coverage Dashboard</h1>
      
      <div class="summary">
        <div class="card">
          <h2>Line Coverage</h2>
          <p class="${getCoverageClass(coverageReport['lineCoverage'])}">
            ${(coverageReport['lineCoverage'] * 100).toStringAsFixed(2)}%
          </p>
        </div>
        
        <div class="card">
          <h2>Branch Coverage</h2>
          <p class="${getCoverageClass(coverageReport['branchCoverage'])}">
            ${(coverageReport['branchCoverage'] * 100).toStringAsFixed(2)}%
          </p>
        </div>
        
        <div class="card">
          <h2>Test Results</h2>
          <p>Total: ${testResults['total']}</p>
          <p>Passed: <span class="good">${testResults['passed']}</span></p>
          <p>Failed: <span class="bad">${testResults['failed']}</span></p>
          <p>Skipped: <span class="warning">${testResults['skipped']}</span></p>
        </div>
      </div>
      
      <h2>Coverage by Directory</h2>
      <table border="1" cellspacing="0" cellpadding="8">
        <tr>
          <th>Directory</th>
          <th>Line Coverage</th>
          <th>Files</th>
        </tr>
        ${coverageReport['directories'].map((dir) => '''
          <tr>
            <td>${dir['name']}</td>
            <td class="${getCoverageClass(dir['coverage'])}">
              ${(dir['coverage'] * 100).toStringAsFixed(2)}%
            </td>
            <td>${dir['files']}</td>
          </tr>
        ''').join('')}
      </table>
      
      <h2>Recent Test Results</h2>
      <table border="1" cellspacing="0" cellpadding="8">
        <tr>
          <th>Test</th>
          <th>Result</th>
          <th>Duration</th>
        </tr>
        ${testResults['tests'].map((test) => '''
          <tr>
            <td>${test['name']}</td>
            <td class="${test['result'] == 'success' ? 'good' : 'bad'}">
              ${test['result']}
            </td>
            <td>${test['duration']}ms</td>
          </tr>
        ''').join('')}
      </table>
    </body>
    </html>
  ''';
  
  // Write HTML to file
  final file = File('test_coverage_dashboard.html');
  await file.writeAsString(html);
  
  print('Dashboard generated at: ${file.absolute.path}');
}

String getCoverageClass(double coverage) {
  if (coverage >= 0.8) return 'good';
  if (coverage >= 0.6) return 'warning';
  return 'bad';
}
```

## Best Practices và Testing Standards

### Code Coverage Goals

Thiết lập mục tiêu code coverage cho dự án:

| Layer | Coverage Target |
|-------|----------------|
| Domain | 95% |
| Data | 90% |
| Presentation | 85% |
| Core | 90% |
| Overall | 90% |

### Testing Standards

1. **Mỗi Pull Request phải bao gồm tests** phù hợp cho những thay đổi
2. **Không giảm code coverage**
3. **Đặt tên test files** theo cấu trúc: `{file_name}_test.dart`
4. **Sử dụng cấu trúc AAA** (Arrange-Act-Assert) trong mỗi test
5. **Tránh phụ thuộc giữa các tests** - mỗi test phải độc lập

### Quy trình kiểm tra

1. **Đảm bảo unit tests chạy trước mỗi commit** (sử dụng pre-commit hooks)
2. **Integration tests chạy trước mỗi push** lên server
3. **E2E tests chạy mỗi đêm** hoặc khi merge vào các nhánh chính

## Testing Mobile-specific Features

### Platform Channel Testing

```dart
// Testing Platform Channels
group('NotificationService Platform Channel Tests', () {
  const MethodChannel channel = MethodChannel('com.example.app/notifications');
  
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'requestPermission') {
          return true;
        } else if (methodCall.method == 'getPendingNotifications') {
          return [
            {
              'id': '1',
              'title': 'Test Notification',
              'body': 'This is a test',
              'data': {'chatId': '123'}
            }
          ];
        }
        return null;
      },
    );
  });
  
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  
  test('requestNotificationPermission returns true when permission granted', () async {
    final notificationService = NotificationService();
    final result = await notificationService.requestPermission();
    expect(result, true);
  });
  
  test('getPendingNotifications returns list of notifications', () async {
    final notificationService = NotificationService();
    final notifications = await notificationService.getPendingNotifications();
    expect(notifications, hasLength(1));
    expect(notifications[0].title, 'Test Notification');
    expect(notifications[0].data['chatId'], '123');
  });
});
```

### Device-specific Testing

```dart
// Testing different screen sizes
testWidgets('ChatUI adapts to different screen sizes',
    (WidgetTester tester) async {
  // Test on phone-sized screen
  await _pumpChatUIWithSize(tester, Size(375, 667)); // iPhone 8
  expect(find.byKey(Key('message_input')), findsOneWidget);
  expect(find.byKey(Key('sidebar')), findsNothing);
  
  // Test on tablet-sized screen
  await _pumpChatUIWithSize(tester, Size(1024, 768)); // iPad
  expect(find.byKey(Key('message_input')), findsOneWidget);
  expect(find.byKey(Key('sidebar')), findsOneWidget);
});

Future<void> _pumpChatUIWithSize(WidgetTester tester, Size size) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: ChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

## Tổng kết

Chiến lược kiểm thử toàn diện nhằm đảm bảo:

- **Reliable Code**: Đảm bảo mọi thành phần hoạt động như mong đợi
- **Regression Prevention**: Ngăn chặn bug do những thay đổi mới
- **Documentation**: Tests cung cấp tài liệu về cách mỗi thành phần hoạt động
- **Confidence**: Tự tin khi triển khai các thay đổi mới

## Các công cụ sử dụng

- **Test Runner**: `flutter test`
- **Mocking**: `mockito` hoặc `mocktail`
- **BLoC Testing**: `bloc_test`
- **Integration Test**: `integration_test`
- **Code Coverage**: `lcov`
- **CI/CD**: GitHub Actions hoặc Codemagic

## Tham khảo

- [Testing Flutter Apps](https://flutter.dev/docs/testing)
- [Flutter Testing Cookbook](https://flutter.dev/docs/cookbook/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/usage#testing)
- [Integration Testing in Flutter](https://flutter.dev/docs/testing/integration-tests)
- [Flutter BLoC Testing](https://bloclibrary.dev/#/testing)
</rewritten_file> 
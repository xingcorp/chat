import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';
import 'package:flutter_chat_app/presentation/pages/chat/chat_page.dart';
import 'package:flutter_chat_app/presentation/pages/chat/conversation_page.dart';
import 'package:flutter_chat_app/presentation/pages/home/home_page.dart';
import 'package:flutter_chat_app/presentation/pages/login/login_page.dart';
import 'package:flutter_chat_app/di/service_locator.dart';
import 'package:flutter_chat_app/core/blocs/auth/auth_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_chat_app/core/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/core/blocs/message/message_bloc.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([SocketManager, AuthBloc, ChatBloc, MessageBloc])
import 'chat_flow_automation_test.mocks.dart';

void main() {
  late MockSocketManager mockSocketManager;
  late MockAuthBloc mockAuthBloc;
  late MockChatBloc mockChatBloc;
  late MockMessageBloc mockMessageBloc;
  
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset service locator
    GetIt.instance.reset();
    
    // Initialize mocks
    mockSocketManager = MockSocketManager();
    mockAuthBloc = MockAuthBloc();
    mockChatBloc = MockChatBloc();
    mockMessageBloc = MockMessageBloc();
    
    // Configure service locator
    GetIt.instance.registerSingleton<SocketManager>(mockSocketManager);
    GetIt.instance.registerSingleton<AuthBloc>(mockAuthBloc);
    GetIt.instance.registerSingleton<ChatBloc>(mockChatBloc);
    GetIt.instance.registerSingleton<MessageBloc>(mockMessageBloc);
    
    // Setup default mocked behaviors
    when(mockSocketManager.connectionState).thenReturn(SocketConnectionState.connected);
    when(mockSocketManager.on(any)).thenAnswer((_) => Stream.empty());
    when(mockSocketManager.emit(any, any)).thenReturn(null);
  });

  testWidgets('Complete Chat Flow Test', (WidgetTester tester) async {
    // Step 1: Setup app with necessary mocks
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(),
        routes: {
          '/home': (context) => HomePage(),
          '/chat': (context) => ChatPage(),
          '/conversation': (context) => ConversationPage(),
        },
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Step 2: Login flow
    print('Testing login flow...');
    
    // Find username and password fields
    final usernameField = find.byKey(Key('usernameField'));
    final passwordField = find.byKey(Key('passwordField'));
    final loginButton = find.byKey(Key('loginButton'));
    
    // Enter credentials
    await tester.enterText(usernameField, 'testuser');
    await tester.enterText(passwordField, 'password123');
    
    // Simulate successful login response
    when(mockAuthBloc.login('testuser', 'password123')).thenAnswer((_) async => true);
    
    // Tap login button
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    
    // Verify we navigated to home page
    expect(find.byType(HomePage), findsOneWidget);
    
    // Step 3: Navigate to Chat Screen
    print('Navigating to chat screen...');
    
    // Find and tap the chat navigation button
    final chatNavButton = find.byKey(Key('chatNavButton'));
    await tester.tap(chatNavButton);
    await tester.pumpAndSettle();
    
    // Verify we navigated to chat page
    expect(find.byType(ChatPage), findsOneWidget);
    
    // Step 4: Verify Chat List is displayed
    print('Verifying chat list is loaded...');
    
    // Mock chat list data
    final chatListData = [
      {
        'id': '1',
        'name': 'Jane Doe',
        'lastMessage': 'Hello there!',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'unreadCount': 2,
      },
      {
        'id': '2',
        'name': 'John Smith',
        'lastMessage': 'How are you?',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 60000,
        'unreadCount': 0,
      }
    ];
    
    // Simulate chat list loading complete
    when(mockChatBloc.chats).thenReturn(Stream.value(chatListData));
    when(mockChatBloc.isLoading).thenReturn(false);
    
    // Refresh the UI
    await tester.pump();
    
    // Verify chat list items are displayed
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('John Smith'), findsOneWidget);
    
    // Step 5: Open a specific conversation
    print('Opening a conversation...');
    
    // Find and tap on the first chat
    final firstChatItem = find.text('Jane Doe');
    await tester.tap(firstChatItem);
    await tester.pumpAndSettle();
    
    // Verify we navigated to conversation page
    expect(find.byType(ConversationPage), findsOneWidget);
    
    // Step 6: Verify messages are loaded
    print('Verifying messages are loaded...');
    
    // Mock message list data
    final messagesData = [
      {
        'id': 'm1',
        'senderId': 'other-user',
        'text': 'Hello there!',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 120000,
      },
      {
        'id': 'm2',
        'senderId': 'current-user',
        'text': 'Hi! How are you?',
        'timestamp': DateTime.now().millisecondsSinceEpoch - 60000,
      }
    ];
    
    // Simulate messages loading complete
    when(mockMessageBloc.messages).thenReturn(Stream.value(messagesData));
    when(mockMessageBloc.isLoading).thenReturn(false);
    
    // Refresh the UI
    await tester.pump();
    
    // Verify messages are displayed
    expect(find.text('Hello there!'), findsOneWidget);
    expect(find.text('Hi! How are you?'), findsOneWidget);
    
    // Step 7: Send a new message
    print('Sending a new message...');
    
    // Find message input field and send button
    final messageField = find.byKey(Key('messageInputField'));
    final sendButton = find.byKey(Key('sendButton'));
    
    // Enter a message
    await tester.enterText(messageField, 'This is a test message!');
    
    // Setup socket emit verification
    when(mockSocketManager.connected).thenReturn(true);
    
    // Tap send button
    await tester.tap(sendButton);
    await tester.pump();
    
    // Verify the message was sent via socket
    verify(mockSocketManager.emit('message', {
      'text': 'This is a test message!',
      'chatId': '1', // The ID of the opened chat
      'timestamp': any,
    })).called(1);
    
    // Step 8: Verify the new message appears in the chat
    print('Verifying new message appears...');
    
    // Add the sent message to the mock data
    messagesData.add({
      'id': 'm3',
      'senderId': 'current-user',
      'text': 'This is a test message!',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Update the stream
    when(mockMessageBloc.messages).thenReturn(Stream.value(messagesData));
    
    // Refresh the UI
    await tester.pump();
    
    // Verify new message is displayed
    expect(find.text('This is a test message!'), findsOneWidget);
    
    // Step 9: Test receiving a new message
    print('Testing receiving a new message...');
    
    // Setup stream for incoming messages
    final messageStreamController = StreamController<Map<String, dynamic>>.broadcast();
    when(mockSocketManager.on('new_message')).thenAnswer((_) => messageStreamController.stream);
    
    // Simulate incoming message
    messageStreamController.add({
      'id': 'm4',
      'senderId': 'other-user',
      'text': 'I got your message!',
      'chatId': '1',
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
    
    // Add the received message to the mock data
    messagesData.add({
      'id': 'm4',
      'senderId': 'other-user',
      'text': 'I got your message!',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Update the stream
    when(mockMessageBloc.messages).thenReturn(Stream.value(messagesData));
    
    // Refresh the UI
    await tester.pump();
    
    // Verify received message is displayed
    expect(find.text('I got your message!'), findsOneWidget);
    
    // Step 10: Test disconnection handling
    print('Testing disconnection handling...');
    
    // Simulate disconnection
    when(mockSocketManager.connectionState).thenReturn(SocketConnectionState.disconnected);
    
    // Create a stream for connection state
    final connectionStateController = StreamController<SocketConnectionState>.broadcast();
    when(mockSocketManager.connectionStateStream).thenAnswer((_) => connectionStateController.stream);
    
    // Emit disconnected state
    connectionStateController.add(SocketConnectionState.disconnected);
    
    // Refresh the UI
    await tester.pump();
    
    // Verify disconnection indicator is shown (assuming there's a widget that shows this)
    expect(find.byKey(Key('disconnectionIndicator')), findsOneWidget);
    
    // Step 11: Test message queuing when offline
    print('Testing offline message queuing...');
    
    // Try to send a message while offline
    await tester.enterText(messageField, 'Offline message test');
    await tester.tap(sendButton);
    await tester.pump();
    
    // Verify the message was queued rather than sent immediately
    verify(mockMessageBloc.queueOfflineMessage(any)).called(1);
    verifyNever(mockSocketManager.emit('message', any)); // Should not emit when offline
    
    // Step 12: Test reconnection and message sync
    print('Testing reconnection and message sync...');
    
    // Simulate reconnection
    when(mockSocketManager.connectionState).thenReturn(SocketConnectionState.connected);
    connectionStateController.add(SocketConnectionState.connected);
    
    // Refresh the UI
    await tester.pump();
    
    // Verify connection indicator shows connected state
    expect(find.byKey(Key('connectionIndicator')), findsOneWidget);
    
    // Verify offline messages are synced
    verify(mockMessageBloc.syncOfflineMessages()).called(1);
    
    // Cleanup
    await messageStreamController.close();
    await connectionStateController.close();
  });
} 
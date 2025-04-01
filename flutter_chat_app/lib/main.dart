import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/config/route/app_router.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/services/chat_message_service.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:uuid/uuid.dart';

// Import home screens from respective platform files
import 'main_mobile.dart' show MobileHomeScreen;
import 'main_web.dart' show WebHomeScreen;
import 'main_desktop.dart' show DesktopHomeScreen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Configure dependencies
  await configureInjection();
  
  // Tùy thuộc vào nền tảng, chúng ta sẽ khởi động các dịch vụ phù hợp
  if (kIsWeb) {
    await _initializeWebServices();
  } else if (Platform.isAndroid || Platform.isIOS) {
    await _initializeMobileServices();
  } else {
    await _initializeDesktopServices();
  }
  
  // Khởi tạo SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(MyApp(sharedPreferences: sharedPreferences));
}

Future<void> _initializeWebServices() async {
  // Initialize web-specific services
  final databaseService = GetIt.I<DatabaseService>();
  await databaseService.initialize();
  
  // Khởi tạo dịch vụ kết nối thời gian thực
  final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
  await realtimeConnectionService.initialize();
  
  // Khởi tạo dịch vụ tin nhắn chat
  final chatMessageService = GetIt.I<ChatMessageService>();
  await chatMessageService.initialize();
}

Future<void> _initializeMobileServices() async {
  // Initialize mobile-specific services
  final databaseService = GetIt.I<DatabaseService>();
  await databaseService.initialize();
  
  // Khởi tạo dịch vụ kết nối thời gian thực
  final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
  await realtimeConnectionService.initialize();
  
  // Khởi tạo dịch vụ hàng đợi tin nhắn
  final messageQueueService = GetIt.I<MessageQueueService>();
  await messageQueueService.initialize();
  
  // Khởi tạo dịch vụ tin nhắn chat
  final chatMessageService = GetIt.I<ChatMessageService>();
  await chatMessageService.initialize();
}

Future<void> _initializeDesktopServices() async {
  // Initialize desktop-specific services
  final databaseService = GetIt.I<DatabaseService>();
  await databaseService.initialize();
  
  // Khởi tạo dịch vụ kết nối thời gian thực
  final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
  await realtimeConnectionService.initialize();
  
  // Khởi tạo dịch vụ hàng đợi tin nhắn
  final messageQueueService = GetIt.I<MessageQueueService>();
  await messageQueueService.initialize();
  
  // Khởi tạo dịch vụ tin nhắn chat
  final chatMessageService = GetIt.I<ChatMessageService>();
  await chatMessageService.initialize();
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  
  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authBloc = AuthBloc(sharedPreferences);
        // Trigger an auth check on app startup
        authBloc.add(const AuthCheckRequested());
        return authBloc;
      },
      child: Builder(
        builder: (context) {
          final router = AppRouter.router(context);
          
          return MaterialApp.router(
            title: 'Flutter Chat App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

// This widget will determine which platform-specific implementation to use
class PlatformEntryPoint extends StatelessWidget {
  const PlatformEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    // Return the appropriate screen based on platform
    if (kIsWeb) {
      return const WebHomeScreen();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return const MobileHomeScreen();
    } else {
      return const DesktopHomeScreen();
    }
  }
}

class IsarTestScreen extends StatefulWidget {
  const IsarTestScreen({super.key});

  @override
  State<IsarTestScreen> createState() => _IsarTestScreenState();
}

class _IsarTestScreenState extends State<IsarTestScreen> {
  final _repository = GetIt.I<OfflineFirstRepository>();
  final _uuid = Uuid();
  bool _isLoading = false;
  String _statusMessage = 'Ready';
  List<UserModel> _users = [];
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _repository.getUserStream().listen((users) {
      setState(() {
        _users = users;
      });
    });
    
    _repository.getChatStream().listen((chats) {
      setState(() {
        _chats = chats;
      });
    });
  }

  Future<void> _createTestData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating test data...';
    });

    try {
      // Create test user
      final user = UserModel(
        serverId: 'srv_${_uuid.v4()}',
        username: 'testuser',
        displayName: 'Test User',
        lastSeen: DateTime.now(),
      );
      await _repository.saveUser(user);

      // Create test chat
      final chat = ChatModel(
        serverId: 'srv_${_uuid.v4()}',
        type: ChatType.direct,
        participantIds: [user.serverId],
        createdAt: DateTime.now(),
      );
      await _repository.saveChat(chat);

      // Create test message
      final message = MessageModel(
        localId: _uuid.v4(),
        chatId: chat.serverId,
        senderId: user.serverId,
        content: 'Hello, this is a test message',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );
      await _repository.saveMessage(message);

      // Load messages for the chat
      _repository.getMessagesForChat(chat.serverId).listen((messages) {
        setState(() {
          _messages = messages;
        });
      });

      setState(() {
        _statusMessage = 'Test data created successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating test data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing data...';
    });

    try {
      final databaseService = GetIt.I<DatabaseService>();
      await databaseService.clearAllData();
      
      setState(() {
        _messages = [];
        _statusMessage = 'Data cleared successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isar Offline-First Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: $_statusMessage', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  const Text('Users:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _users.isEmpty
                      ? const Text('No users yet')
                      : Column(
                          children: _users
                              .map((user) => ListTile(
                                    title: Text(user.displayName),
                                    subtitle: Text(user.username),
                                  ))
                              .toList(),
                        ),
                  const SizedBox(height: 20),
                  
                  const Text('Chats:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _chats.isEmpty
                      ? const Text('No chats yet')
                      : Column(
                          children: _chats
                              .map((chat) => ListTile(
                                    title: Text('Chat ${chat.id}'),
                                    subtitle: Text('Type: ${chat.type.name}'),
                                  ))
                              .toList(),
                        ),
                  const SizedBox(height: 20),
                  
                  const Text('Messages:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _messages.isEmpty
                      ? const Text('No messages yet')
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return ListTile(
                                title: Text(message.content),
                                subtitle: Text('Status: ${message.status.name}'),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _createTestData,
            tooltip: 'Create Test Data',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _clearData,
            tooltip: 'Clear Data',
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
} 
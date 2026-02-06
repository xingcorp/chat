import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_chat_app/main.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initializeFromEnvironment();
  }
  final envFileName =
      FlavorConfig.instance.isProduction ? '.env.production' : '.env.staging';
  await dotenv.load(fileName: envFileName);
  debugPrint('Loaded env file: $envFileName');
  debugPrint("GRAPHQL_API_URL: ${dotenv.env['GRAPHQL_API_URL']}");
  
  // Configure Enterprise dependencies
  await configureDependencies();
  
  // Initialize services for web
  await _initializeWebServices();
  
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const MyApp(),
    ),
  );
}

Future<void> _initializeWebServices() async {
  // Initialize database service
  final databaseService = getIt<DatabaseService>();
  await databaseService.initialize();

  // Initialize any web-specific services here
  // Examples:
  // - IndexedDB wrappers
  // - PWA functionality
  // - Browser APIs
}

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final _repository = getIt<OfflineFirstRepository>();
  final _uuid = const Uuid();
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
        content: 'Hello, this is a test message from web',
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
    // Web UI with a slightly different layout
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Chat Application'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show web-specific help
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Web App Help'),
                  content: const Text('This is the web version of the chat application.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Side navigation (web-specific)
                Container(
                  width: 250,
                  color: Colors.grey[200],
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Navigation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('Home'),
                        selected: true,
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.chat),
                        title: const Text('Chats'),
                        onTap: () {},
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () {},
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Status: $_statusMessage'),
                      ),
                    ],
                  ),
                ),
                
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Web Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Test Data'),
                                  onPressed: _createTestData,
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Clear Data'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _clearData,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Two column grid for web layout
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First column - Users and Chats
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Users:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    _users.isEmpty
                                        ? const Text('No users yet')
                                        : Expanded(
                                            child: ListView.builder(
                                              itemCount: _users.length,
                                              itemBuilder: (context, index) {
                                                final user = _users[index];
                                                return ListTile(
                                                  title: Text(user.displayName),
                                                  subtitle: Text(user.username),
                                                  leading: CircleAvatar(
                                                    child: Text(user.displayName.substring(0, 1)),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                    const SizedBox(height: 20),
                                    const Text('Chats:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    _chats.isEmpty
                                        ? const Text('No chats yet')
                                        : Expanded(
                                            child: ListView.builder(
                                              itemCount: _chats.length,
                                              itemBuilder: (context, index) {
                                                final chat = _chats[index];
                                                return ListTile(
                                                  title: Text('Chat ${chat.id}'),
                                                  subtitle: Text('Type: ${chat.type.name}'),
                                                  leading: const Icon(Icons.chat),
                                                );
                                              },
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                              
                              // Separator
                              const VerticalDivider(),
                              
                              // Second column - Messages
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Messages:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    _messages.isEmpty
                                        ? const Text('No messages yet')
                                        : Expanded(
                                            child: ListView.builder(
                                              itemCount: _messages.length,
                                              itemBuilder: (context, index) {
                                                final message = _messages[index];
                                                return Card(
                                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                                  child: ListTile(
                                                    title: Text(message.content),
                                                    subtitle: Text('Status: ${message.status.name}'),
                                                    trailing: Text(
                                                      message.createdAt.toString().substring(0, 16),
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 
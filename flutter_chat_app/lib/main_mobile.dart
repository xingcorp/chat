import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_chat_app/main.dart' show MyApp;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Configure Enterprise dependencies
  await EnterpriseDI.initialize();
  
  // Initialize services for mobile
  await _initializeMobileServices();
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(MyApp(sharedPreferences: sharedPreferences));
}

Future<void> _initializeMobileServices() async {
  // Initialize database service
  final databaseService = EnterpriseDI.get<DatabaseService>();
  await databaseService.initialize();

  // Initialize any mobile-specific services here
  // Examples:
  // - Local notifications
  // - Deep linking
  // - Platform channels
}

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  final _repository = EnterpriseDI.get<OfflineFirstRepository>();
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
        title: const Text('Mobile Chat App'),
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
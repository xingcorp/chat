// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';

// Third-party package imports
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

// App imports - initialization
import 'package:flutter_chat_app/core/initialization/env_validator.dart';

// App imports
import 'package:flutter_chat_app/core/constants/app_dimensions.dart';
import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/localization/app_strings.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/data/models/message_model.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/data/repositories/offline_first_repository.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/main.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initializeFromEnvironment();
  }
  await EnvValidator.loadDotenvForFlavor();
  
  // Configure Enterprise dependencies
  await configureDependencies();
  
  // Initialize services for desktop
  await _initializeDesktopServices();
  
  runApp(const MyApp());
}

Future<void> _initializeDesktopServices() async {
  // Initialize database service
  final databaseService = getIt<DatabaseService>();
  await databaseService.initialize();

  // Initialize any desktop-specific services here
  // Examples:
  // - File system access
  // - System tray integration
  // - Native desktop APIs
}

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  final _repository = getIt<OfflineFirstRepository>();
  final _uuid = const Uuid();
  bool _isLoading = false;
  String _statusMessage = 'Ready';
  List<UserModel> _users = [];
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  int _selectedIndex = 0;
  ChatModel? _selectedChat;

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
        // Select the first chat if available and none is selected
        if (_selectedChat == null && chats.isNotEmpty) {
          _selectChat(chats.first);
        }
      });
    });
  }

  void _selectChat(ChatModel chat) {
    setState(() {
      _selectedChat = chat;
    });
    
    // Load messages for the selected chat
    _repository.getMessagesForChat(chat.serverId).listen((messages) {
      setState(() {
        _messages = messages;
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
        content: 'Hello, this is a test message from desktop',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );
      await _repository.saveMessage(message);

      setState(() {
        _statusMessage = 'Test data created successfully';
        _selectChat(chat);
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
        _selectedChat = null;
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
    // Desktop UI with a multi-pane layout
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Navigation sidebar
                NavigationRail(
                  extended: true,
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'), // Keep as is - not user-facing
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.chat),
                      label: Text(AppStrings.chats),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.people),
                      label: Text('Users'), // Keep as is - not user-facing
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings),
                      label: Text(AppStrings.settings),
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
                
                // Vertical divider
                const VerticalDivider(thickness: 1, width: 1),
                
                // Chat list panel
                SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingDefault),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chats',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _createTestData,
                              tooltip: 'Create Test Data',
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: _chats.isEmpty
                            ? const Center(child: Text('Chưa có cuộc trò chuyện nào'))
                            : ListView.builder(
                                itemCount: _chats.length,
                                itemBuilder: (context, index) {
                                  final chat = _chats[index];
                                  final isSelected = _selectedChat?.serverId == chat.serverId;
                                  
                                  return ListTile(
                                    title: Text('Chat ${chat.id}'),
                                    subtitle: Text('Type: ${chat.type.name}'),
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                      child: const Icon(Icons.chat, color: Colors.white),
                                    ),
                                    selected: isSelected,
                                    onTap: () => _selectChat(chat),
                                  );
                                },
                              ),
                      ),
                      
                      // Status bar
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _statusMessage,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              tooltip: 'Clear Data',
                              onPressed: _clearData,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vertical divider
                const VerticalDivider(thickness: 1, width: 1),
                
                // Main content area with messages
                Expanded(
                  child: _selectedChat == null
                      ? const Center(child: Text('Chọn cuộc trò chuyện để xem tin nhắn'))
                      : Column(
                          children: [
                            // Chat header
                            AppBar(
                              title: Text('Chat ${_selectedChat!.id}'),
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.info),
                                  onPressed: () {
                                    // Show chat details
                                  },
                                ),
                              ],
                            ),
                            
                            // Message list
                            Expanded(
                              child: _messages.isEmpty
                                  ? const Center(child: Text('Chưa có tin nhắn nào'))
                                  : ListView.builder(
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        final isSentByMe = message.senderId == 'current_user_id'; // Replace with actual current user ID
                                        
                                        return Align(
                                          alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: AppDimensions.marginDefault,
                                              vertical: AppDimensions.marginTiny,
                                            ),
                                            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                                            decoration: BoxDecoration(
                                              color: isSentByMe
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.grey[300],
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  message.content,
                                                  style: TextStyle(
                                                    color: isSentByMe ? Colors.white : Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  message.createdAt.toString().substring(0, 16),
                                                  style: TextStyle(
                                                    color: isSentByMe
                                                        ? Colors.white.withValues(alpha: 0.7)
                                                        : Colors.black54,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            
                            // Message input
                            Padding(
                              padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.attach_file),
                                    onPressed: () {
                                      // Attach file
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: AppStrings.typeMessage,
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(24.0)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: AppDimensions.paddingDefault,
                                          vertical: AppDimensions.paddingSmall,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    color: Theme.of(context).colorScheme.primary,
                                    onPressed: () {
                                      // Send message
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                
                // User panel (optional, can be hidden based on screen size)
                if (MediaQuery.of(context).size.width > 1200)
                  Container(
                    width: 250,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingDefault),
                          child: const Text(
                            'Users',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        Expanded(
                          child: _users.isEmpty
                              ? const Center(child: Text('Chưa có người dùng nào'))
                              : ListView.builder(
                                  itemCount: _users.length,
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    return ListTile(
                                      title: Text(user.displayName),
                                      subtitle: Text(user.username),
                                      leading: CircleAvatar(
                                        child: Text(user.displayName.substring(0, 1)),
                                      ),
                                      trailing: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: user.isOnline ? Colors.green : Colors.grey,
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
    );
  }
} 
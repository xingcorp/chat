import 'package:flutter/widgets.dart';
import 'package:flutter_chat_app/chat_config.dart';
import 'package:flutter_chat_app/core/di/chat_module_injection.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_list_page.dart';

/// Entry point for the chat module when used as a package.
///
/// Host apps call [initialize] with a [ChatConfig] to set up internal
/// dependencies, then use [chatListPage] / [chatDetailPage] to get
/// ready-to-use widgets.
///
/// ```dart
/// await ChatModule.initialize(ChatConfig(
///   baseUrl: 'https://api.example.com',
///   graphqlUrl: 'https://api.example.com/graphql',
///   graphqlWsUrl: 'wss://api.example.com/graphql',
///   socketUrl: 'wss://api.example.com/socket',
///   accessToken: userToken,
///   currentUserId: userId,
///   onTokenRefresh: () => authService.refreshToken(),
///   onAuthExpired: () => navigator.pushLogin(),
/// ));
///
/// // Navigate to chat
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ChatModule.chatListPage(),
/// ));
/// ```
class ChatModule {
  ChatModule._();

  static bool _initialized = false;
  static ChatConfig? _config;

  /// Whether the module has been initialized.
  static bool get isInitialized => _initialized;

  /// The current configuration, or null if not initialized.
  static ChatConfig? get config => _config;

  /// Initialize the chat module with the given configuration.
  ///
  /// Must be called before using [chatListPage] or [chatDetailPage].
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> initialize(ChatConfig config) async {
    if (_initialized) return;
    _config = config;
    await ChatModuleInjection.initialize(config);
    _initialized = true;
  }

  /// Returns the chat list page widget.
  ///
  /// The widget pulls its dependencies from the internal DI container.
  /// Host app is responsible for wrapping with navigation (e.g., MaterialPageRoute).
  static Widget chatListPage() {
    _ensureInitialized();
    return const ChatListPage();
  }

  /// Returns the chat detail page widget for a specific conversation.
  ///
  /// [chatId] is the conversation ID to display.
  static Widget chatDetailPage({required String chatId}) {
    _ensureInitialized();
    return ChatDetailsPage(chatId: chatId);
  }

  /// Dispose all resources and reset the module.
  ///
  /// After calling this, [initialize] must be called again before using
  /// any other methods.
  static Future<void> dispose() async {
    if (!_initialized) return;
    await ChatModuleInjection.dispose();
    _config = null;
    _initialized = false;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ChatModule has not been initialized. '
        'Call ChatModule.initialize(ChatConfig(...)) first.',
      );
    }
  }
}

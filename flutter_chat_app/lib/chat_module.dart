import 'package:flutter/material.dart';
import 'package:flutter_chat_app/chat_config.dart';
import 'package:flutter_chat_app/core/di/chat_module_injection.dart';
import 'package:flutter_chat_app/core/network/auth/token_repository.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_list_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/create_group_page.dart';
import 'package:get_it/get_it.dart';

/// Entry point for the chat module when used as a package.
///
/// Host apps call [initialize] with a [ChatConfig] to set up internal
/// dependencies, then use the page widgets or route helpers to navigate.
///
/// ## Lifecycle
///
/// ```dart
/// // 1. Initialize (once after login)
/// await ChatModule.initialize(ChatConfig(
///   baseUrl: 'https://api.example.com',
///   graphqlUrl: 'https://api.example.com/graphql',
///   graphqlWsUrl: 'wss://api.example.com/graphql',
///   socketUrl: 'wss://api.example.com/socket',
///   accessToken: userToken,
///   currentUserId: userId,
///   onTokenRefresh: () => authService.refreshToken(),
///   onAuthExpired: () => navigator.pushReplacementNamed('/login'),
/// ));
///
/// // 2. Navigate to chat
/// Navigator.push(context, ChatModule.chatListRoute());
/// Navigator.push(context, ChatModule.chatDetailRoute(chatId: 'abc'));
///
/// // 3. Update token when host app refreshes it independently
/// await ChatModule.updateToken('new_access_token');
///
/// // 4. Cleanup on logout
/// await ChatModule.dispose();
/// ```
class ChatModule {
  ChatModule._();

  static bool _initialized = false;
  static ChatConfig? _config;

  /// Whether the module has been initialized.
  static bool get isInitialized => _initialized;

  /// The current configuration, or null if not initialized.
  static ChatConfig? get config => _config;

  // ===========================================================
  // Lifecycle
  // ===========================================================

  /// Initialize the chat module with the given configuration.
  ///
  /// Must be called before using any page or route methods.
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> initialize(ChatConfig config) async {
    if (_initialized) return;
    _config = config;
    await ChatModuleInjection.initialize(config);
    _initialized = true;
  }

  /// Dispose all resources and reset the module.
  ///
  /// After calling this, [initialize] must be called again before using
  /// any other methods. Typically called on user logout.
  static Future<void> dispose() async {
    if (!_initialized) return;
    await ChatModuleInjection.dispose();
    _config = null;
    _initialized = false;
  }

  /// Update the access token at runtime.
  ///
  /// Call this when the host app refreshes its token independently
  /// (e.g., via its own interceptor) so the chat module uses the new token
  /// for subsequent API calls and socket connections.
  static Future<void> updateToken(String newAccessToken) async {
    _ensureInitialized();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<TokenRepository>()) {
      await getIt<TokenRepository>().saveAccessToken(newAccessToken);
    }
  }

  // ===========================================================
  // Page Widgets — use these when you manage navigation yourself
  // ===========================================================

  /// Returns the chat list page widget.
  ///
  /// Shows all conversations for the current user.
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

  /// Returns the create group page widget.
  static Widget createGroupPage() {
    _ensureInitialized();
    return const CreateGroupPage();
  }

  // ===========================================================
  // Route Helpers — convenience methods that return MaterialPageRoute
  // ===========================================================

  /// Returns a [MaterialPageRoute] to the chat list page.
  ///
  /// ```dart
  /// Navigator.push(context, ChatModule.chatListRoute());
  /// ```
  static Route<dynamic> chatListRoute() {
    _ensureInitialized();
    return MaterialPageRoute<void>(
      builder: (_) => const ChatListPage(),
      settings: const RouteSettings(name: '/chat'),
    );
  }

  /// Returns a [MaterialPageRoute] to the chat detail page.
  ///
  /// ```dart
  /// Navigator.push(context, ChatModule.chatDetailRoute(chatId: 'abc123'));
  /// ```
  static Route<dynamic> chatDetailRoute({required String chatId}) {
    _ensureInitialized();
    return MaterialPageRoute<void>(
      builder: (_) => ChatDetailsPage(chatId: chatId),
      settings: RouteSettings(name: '/chat/$chatId'),
    );
  }

  /// Returns a [MaterialPageRoute] to the create group page.
  ///
  /// ```dart
  /// Navigator.push(context, ChatModule.createGroupRoute());
  /// ```
  static Route<dynamic> createGroupRoute() {
    _ensureInitialized();
    return MaterialPageRoute<void>(
      builder: (_) => const CreateGroupPage(),
      settings: const RouteSettings(name: '/chat/create-group'),
    );
  }

  // ===========================================================
  // Internal
  // ===========================================================

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ChatModule has not been initialized. '
        'Call ChatModule.initialize(ChatConfig(...)) first.',
      );
    }
  }
}

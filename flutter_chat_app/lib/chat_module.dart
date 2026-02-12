import 'package:flutter/material.dart';
import 'package:flutter_chat_app/chat_config.dart';
import 'package:flutter_chat_app/core/app/chat_app_shell.dart';
import 'package:flutter_chat_app/core/di/chat_module_injection.dart';
import 'package:flutter_chat_app/core/network/auth/token_repository.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_list_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/create_group_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
/// // 4. Cleanup on logout (clears user data but keeps module ready)
/// await ChatModule.logout();
///
/// // 5. Full cleanup (unregisters dependencies, call on app termination)
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

  /// Logout the current user and clear all user-specific data.
  ///
  /// This clears the local database, cache, and resets the module state
  /// so that a new user can login without seeing old data.
  /// The module remains initialized and ready for re-initialization with
  /// a new user's config.
  ///
  /// Typically called when user logs out. After this, call [initialize]
  /// again with the new user's config before using any other methods.
  static Future<void> logout() async {
    if (!_initialized) return;
    await ChatModuleInjection.logout();
    _config = null;
    _initialized = false;
  }

  /// Dispose all resources and reset the module.
  ///
  /// After calling this, [initialize] must be called again before using
  /// any other methods. Typically called on app termination or after logout
  /// when you want to fully cleanup dependencies.
  ///
  /// Note: For user logout, prefer [logout] which clears user data.
  /// Use [dispose] only when you need to fully unregister dependencies.
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
  /// Wrapped with [ChatAppShell.package] for providers and localization.
  static Widget chatListPage() {
    _ensureInitialized();
    return const _ChatPackageWrapper(child: ChatListPage());
  }

  /// Returns the chat detail page widget for a specific conversation.
  ///
  /// [chatId] is the conversation ID to display.
  static Widget chatDetailPage({required String chatId}) {
    _ensureInitialized();
    return _ChatPackageWrapper(child: ChatDetailsPage(chatId: chatId));
  }

  /// Returns the create group page widget.
  static Widget createGroupPage() {
    _ensureInitialized();
    return const _ChatPackageWrapper(child: CreateGroupPage());
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
      builder: (_) => const _ChatPackageWrapper(child: ChatListPage()),
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
      builder: (_) =>
          _ChatPackageWrapper(child: ChatDetailsPage(chatId: chatId)),
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
      builder: (_) => const _ChatPackageWrapper(child: CreateGroupPage()),
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

/// Wrapper widget that provides all required dependencies for package mode.
///
/// Uses [ChatAppShell.package] to provide:
/// - AuthBloc (with pre-authenticated state from ChatConfig)
/// - ChatBloc (from GetIt)
/// - Localization delegates
/// - ScreenUtil initialization
class _ChatPackageWrapper extends StatelessWidget {
  const _ChatPackageWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => ChatAppShell.package(
        child: child,
      ),
    );
  }
}

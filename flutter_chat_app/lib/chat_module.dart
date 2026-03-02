import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/chat_config.dart';
import 'package:flutter_chat_app/core/app/chat_app_shell.dart';
import 'package:flutter_chat_app/core/cache/background_sync_helper.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_theme.dart';
import 'package:flutter_chat_app/core/theme/app_theme_extensions.dart';
import 'package:flutter_chat_app/core/di/chat_module_injection.dart';
import 'package:flutter_chat_app/core/network/auth/token_repository.dart';
import 'package:flutter_chat_app/core/services/chat_fcm_handler.dart';
import 'package:flutter_chat_app/core/services/chat_module_event_bus.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_home_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/create_group_page.dart';
import 'package:flutter_chat_app/features/contacts/presentation/pages/contacts_page.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat_message.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Also persist to SharedPreferences for background isolate access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BackgroundSyncHelper.keyAccessToken, newAccessToken);
  }

  // ===========================================================
  // Host App API — Events, Unread Count, Sync, FCM
  // ===========================================================

  /// Stream of total unread message count across all conversations.
  ///
  /// Host app can listen to this to update a badge on the chat tab.
  /// ```dart
  /// ChatModule.unreadCountStream.listen((count) {
  ///   setState(() => _chatBadge = count);
  /// });
  /// ```
  static Stream<int> get unreadCountStream {
    _ensureInitialized();
    return GetIt.instance<ChatModuleEventBus>().totalUnreadCountStream;
  }

  /// Current total unread count (synchronous).
  static int get currentUnreadCount {
    _ensureInitialized();
    return GetIt.instance<ChatModuleEventBus>().currentTotalUnreadCount;
  }

  /// Stream of new messages from any conversation.
  static Stream<ChatMessage> get newMessageStream {
    _ensureInitialized();
    return GetIt.instance<ChatModuleEventBus>().newMessageStream;
  }

  /// Convenience method to listen for new messages.
  ///
  /// Returns a [StreamSubscription] that the caller should cancel
  /// when no longer needed.
  static StreamSubscription<ChatMessage> onNewMessage(
      void Function(ChatMessage message) callback,
      ) {
    _ensureInitialized();
    return GetIt.instance<ChatModuleEventBus>().newMessageStream.listen(callback);
  }

  /// Forward an FCM data payload into the chat module for processing.
  ///
  /// Call this from the host app's FCM foreground message handler
  /// so the chat module can update its cache and UI.
  static void onFCMMessageReceived(Map<String, dynamic> data) {
    _ensureInitialized();
    GetIt.instance<ChatModuleEventBus>().emitFCMData(data);
  }

  /// Request a foreground sync of chat data from the server.
  ///
  /// Useful after receiving a silent push notification or when
  /// the host app detects connectivity restored.
  static void triggerSync() {
    _ensureInitialized();
    GetIt.instance<ChatModuleEventBus>().triggerSync();
  }

  /// Check if an FCM data payload is chat-related.
  ///
  /// ```dart
  /// FirebaseMessaging.onMessage.listen((message) {
  ///   if (ChatModule.isChatFCMMessage(message.data)) {
  ///     ChatModule.onFCMMessageReceived(message.data);
  ///   }
  /// });
  /// ```
  static bool isChatFCMMessage(Map<String, dynamic> data) {
    return ChatFCMHandler.isChatMessage(data);
  }

  /// Handle a background FCM data payload (no GetIt, no DI).
  ///
  /// Call from a top-level `@pragma('vm:entry-point')` function:
  /// ```dart
  /// @pragma('vm:entry-point')
  /// Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  ///   if (ChatModule.isChatFCMMessage(message.data)) {
  ///     await ChatModule.handleBackgroundFCM(message.data);
  ///   }
  /// }
  /// ```
  static Future<void> handleBackgroundFCM(Map<String, dynamic> data) async {
    await ChatFCMHandler.onBackgroundMessage(data);
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
    return const _ChatPackageWrapper(child: ChatHomePage());
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

  /// Returns the contacts page widget.
  static Widget contactsPage() {
    _ensureInitialized();
    return const _ChatPackageWrapper(child: ContactsPage());
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
      builder: (_) => const _ChatPackageWrapper(child: ChatHomePage()),
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

  /// Returns a [MaterialPageRoute] to the contacts page.
  ///
  /// ```dart
  /// Navigator.push(context, ChatModule.contactsRoute());
  /// ```
  static Route<dynamic> contactsRoute() {
    _ensureInitialized();
    return MaterialPageRoute<void>(
      builder: (_) => const _ChatPackageWrapper(child: ContactsPage()),
      settings: const RouteSettings(name: '/chat/contacts'),
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
/// - Theme override (from [ChatConfig.theme], host app context, or chat default)
class _ChatPackageWrapper extends StatelessWidget {
  const _ChatPackageWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppDimens.breakpointDesktop;

        return ScreenUtilInit(
          designSize: isDesktop
              ? Size(constraints.maxWidth, constraints.maxHeight)
              : const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) {
            // Resolve theme INSIDE ScreenUtilInit builder so .sp is available
            // when AppTheme.lightTheme builds its text styles.
            final configTheme = ChatModule.config?.theme;
            final themeData = configTheme ?? AppTheme.lightTheme;
            // Ensure AppThemeExtensions is always available
            final effectiveTheme =
            themeData.extension<AppThemeExtensions>() != null
                ? themeData
                : themeData.copyWith(
              extensions: [
                ...themeData.extensions.values,
                AppThemeExtensions.light,
              ],
            );

            return Theme(
              data: effectiveTheme,
              child: Portal(
                child: ChatAppShell.package(
                  child: child,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

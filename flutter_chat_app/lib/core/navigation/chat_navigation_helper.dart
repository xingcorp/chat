import 'package:flutter/material.dart';

import 'package:flutter_chat_app/chat_module.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_list_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/create_group_page.dart';

/// Helper for internal navigation within the chat module.
///
/// This helper automatically detects the current mode (standalone vs package)
/// and uses the appropriate navigation method:
///
/// - **Package mode**: Uses [ChatModule] routes which wrap pages with [ChatAppShell]
/// - **Standalone mode**: Navigates directly since pages inherit providers from app.dart
///
/// ## Usage
/// ```dart
/// // Instead of:
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ChatDetailsPage(chatId: id),
/// ));
///
/// // Use:
/// ChatNavigationHelper.navigateToChatDetail(context, chatId: id);
/// ```
///
/// ## Why This is Needed
/// In package mode, each new route needs to be wrapped with [ChatAppShell] to
/// get the required providers (AuthBloc, Localizations, etc.).
/// In standalone mode, the entire app is wrapped, so direct navigation works.
class ChatNavigationHelper {
  ChatNavigationHelper._();

  /// Whether the chat module is running in package mode.
  static bool get isPackageMode => ChatModule.isInitialized;

  // ===========================================================
  // Navigation Methods
  // ===========================================================

  /// Navigate to chat list page.
  ///
  /// Pushes the chat list page onto the navigator stack.
  static Future<void> navigateToChatList(BuildContext context) {
    if (isPackageMode) {
      return Navigator.push(context, ChatModule.chatListRoute());
    } else {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatListPage(),
          settings: const RouteSettings(name: '/chat'),
        ),
      );
    }
  }

  /// Navigate to chat detail page.
  ///
  /// [chatId] is the conversation ID to display.
  static Future<void> navigateToChatDetail(
    BuildContext context, {
    required String chatId,
  }) {
    if (isPackageMode) {
      return Navigator.push(context, ChatModule.chatDetailRoute(chatId: chatId));
    } else {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailsPage(chatId: chatId),
          settings: RouteSettings(name: '/chat/$chatId'),
        ),
      );
    }
  }

  /// Navigate to create group page.
  static Future<void> navigateToCreateGroup(BuildContext context) {
    if (isPackageMode) {
      return Navigator.push(context, ChatModule.createGroupRoute());
    } else {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CreateGroupPage(),
          settings: const RouteSettings(name: '/chat/create-group'),
        ),
      );
    }
  }

  // ===========================================================
  // Route Builders (for advanced use cases)
  // ===========================================================

  /// Returns a route to chat list page.
  ///
  /// Use this when you need a Route object instead of navigating directly.
  static Route<dynamic> chatListRoute() {
    if (isPackageMode) {
      return ChatModule.chatListRoute();
    } else {
      return MaterialPageRoute(
        builder: (_) => const ChatListPage(),
        settings: const RouteSettings(name: '/chat'),
      );
    }
  }

  /// Returns a route to chat detail page.
  static Route<dynamic> chatDetailRoute({required String chatId}) {
    if (isPackageMode) {
      return ChatModule.chatDetailRoute(chatId: chatId);
    } else {
      return MaterialPageRoute(
        builder: (_) => ChatDetailsPage(chatId: chatId),
        settings: RouteSettings(name: '/chat/$chatId'),
      );
    }
  }

  /// Returns a route to create group page.
  static Route<dynamic> createGroupRoute() {
    if (isPackageMode) {
      return ChatModule.createGroupRoute();
    } else {
      return MaterialPageRoute(
        builder: (_) => const CreateGroupPage(),
        settings: const RouteSettings(name: '/chat/create-group'),
      );
    }
  }

  // ===========================================================
  // Replacement Navigation (replaces current route)
  // ===========================================================

  /// Replace current route with chat list page.
  static Future<void> replaceToChatList(BuildContext context) {
    if (isPackageMode) {
      return Navigator.pushReplacement(context, ChatModule.chatListRoute());
    } else {
      return Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatListPage(),
          settings: const RouteSettings(name: '/chat'),
        ),
      );
    }
  }

  /// Replace current route with chat detail page.
  static Future<void> replaceToChatDetail(
    BuildContext context, {
    required String chatId,
  }) {
    if (isPackageMode) {
      return Navigator.pushReplacement(
        context,
        ChatModule.chatDetailRoute(chatId: chatId),
      );
    } else {
      return Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailsPage(chatId: chatId),
          settings: RouteSettings(name: '/chat/$chatId'),
        ),
      );
    }
  }
}

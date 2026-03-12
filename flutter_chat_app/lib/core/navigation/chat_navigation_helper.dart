import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_chat_app/chat_module.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/services/chat_conversation_selection_service.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_home_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/create_group_page.dart';
import 'package:flutter_chat_app/features/contacts/presentation/pages/contacts_page.dart';
import 'package:flutter_chat_app/presentation/pages/users/user_details_page.dart';

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

  static bool _isStandaloneDesktop(BuildContext context) {
    return !isPackageMode &&
        MediaQuery.sizeOf(context).width >= AppDimens.breakpointDesktop;
  }

  static void _selectDesktopConversation(
    String chatId, {
    String? receiverId,
  }) {
    if (!GetIt.I.isRegistered<ChatConversationSelectionService>()) {
      return;
    }

    GetIt.I<ChatConversationSelectionService>()
        .selectConversation(chatId, receiverId: receiverId);
  }

  static Widget _buildStandaloneChatDetailPage(
    BuildContext context, {
    required String chatId,
    String? receiverId,
  }) {
    if (_isStandaloneDesktop(context)) {
      _selectDesktopConversation(chatId, receiverId: receiverId);
      return const ChatHomePage();
    }

    return ChatDetailsPage(chatId: chatId, receiverId: receiverId);
  }

  // ===========================================================
  // Navigation Methods
  // ===========================================================

  /// Navigate to chat list page.
  ///
  /// Pushes the chat list page onto the navigator stack.
  static Future<void> navigateToChatList(BuildContext context) {
    if (_isStandaloneDesktop(context)) {
      final goRouter = GoRouter.maybeOf(context);
      if (goRouter != null) {
        goRouter.go('/chats');
        return Future<void>.value();
      }
    }

    if (isPackageMode) {
      return Navigator.push(context, ChatModule.chatListRoute());
    } else {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatHomePage(),
          settings: const RouteSettings(name: '/chat'),
        ),
      );
    }
  }

  /// Navigate to chat detail page.
  ///
  /// [chatId] is the conversation ID to display.
  /// [receiverId] is for pending direct chats (no server conversation yet).
  static Future<void> navigateToChatDetail(
    BuildContext context, {
    required String chatId,
    String? receiverId,
  }) {
    if (_isStandaloneDesktop(context)) {
      _selectDesktopConversation(chatId, receiverId: receiverId);
      final goRouter = GoRouter.maybeOf(context);
      if (goRouter != null) {
        goRouter.go('/chats');
        return Future<void>.value();
      }
    }

    if (isPackageMode) {
      return Navigator.push(context,
          ChatModule.chatDetailRoute(chatId: chatId, receiverId: receiverId));
    } else {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _buildStandaloneChatDetailPage(
            context,
            chatId: chatId,
            receiverId: receiverId,
          ),
          settings: RouteSettings(name: '/chat/$chatId'),
        ),
      );
    }
  }

  /// Navigate to create group page.
  static Future<dynamic> navigateToCreateGroup(BuildContext context) {
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

  /// Navigate to contacts page.
  static Future<dynamic> navigateToContacts(
    BuildContext context, {
    bool selectionMode = false,
  }) {
    if (isPackageMode) {
      return Navigator.push(
        context,
        ChatModule.contactsRoute(selectionMode: selectionMode),
      );
    } else {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactsPage(selectionMode: selectionMode),
          settings: const RouteSettings(name: '/chat/contacts'),
        ),
      );
    }
  }

  /// Navigate to user profile page.
  ///
  /// [userId] is the user ID to display.
  /// [displayName] and [avatarUrl] are optional hints for immediate display.
  static Future<dynamic> navigateToUserProfile(
    BuildContext context, {
    required String userId,
    String? displayName,
    String? avatarUrl,
  }) {
    if (isPackageMode) {
      return Navigator.push(
        context,
        ChatModule.userProfileRoute(
          userId: userId,
          displayName: displayName,
          avatarUrl: avatarUrl,
        ),
      );
    } else {
      final goRouter = GoRouter.maybeOf(context);
      if (goRouter != null) {
        goRouter.push(
          '/users/$userId',
          extra: {
            'displayName': displayName,
            'avatarUrl': avatarUrl,
          },
        );
        return Future<void>.value();
      }
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserDetailsPage(
            userId: userId,
            displayName: displayName,
            avatarUrl: avatarUrl,
          ),
          settings: RouteSettings(name: '/users/$userId'),
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
        builder: (_) => const ChatHomePage(),
        settings: const RouteSettings(name: '/chat'),
      );
    }
  }

  /// Returns a route to chat detail page.
  static Route<dynamic> chatDetailRoute({
    required String chatId,
    String? receiverId,
  }) {
    if (isPackageMode) {
      return ChatModule.chatDetailRoute(chatId: chatId, receiverId: receiverId);
    } else {
      return MaterialPageRoute(
        builder: (context) => _buildStandaloneChatDetailPage(
          context,
          chatId: chatId,
          receiverId: receiverId,
        ),
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

  /// Returns a route to contacts page.
  static Route<dynamic> contactsRoute({bool selectionMode = false}) {
    if (isPackageMode) {
      return ChatModule.contactsRoute(selectionMode: selectionMode);
    } else {
      return MaterialPageRoute(
        builder: (_) => ContactsPage(selectionMode: selectionMode),
        settings: const RouteSettings(name: '/chat/contacts'),
      );
    }
  }

  // ===========================================================
  // Replacement Navigation (replaces current route)
  // ===========================================================

  /// Replace current route with chat list page.
  static Future<void> replaceToChatList(BuildContext context) {
    if (_isStandaloneDesktop(context)) {
      final goRouter = GoRouter.maybeOf(context);
      if (goRouter != null) {
        goRouter.go('/chats');
        return Future<void>.value();
      }
    }

    if (isPackageMode) {
      return Navigator.pushReplacement(context, ChatModule.chatListRoute());
    } else {
      return Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatHomePage(),
          settings: const RouteSettings(name: '/chat'),
        ),
      );
    }
  }

  /// Replace current route with chat detail page.
  static Future<void> replaceToChatDetail(
    BuildContext context, {
    required String chatId,
    String? receiverId,
  }) {
    if (_isStandaloneDesktop(context)) {
      _selectDesktopConversation(chatId, receiverId: receiverId);
      final goRouter = GoRouter.maybeOf(context);
      if (goRouter != null) {
        goRouter.go('/chats');
        return Future<void>.value();
      }
    }

    if (isPackageMode) {
      return Navigator.pushReplacement(
        context,
        ChatModule.chatDetailRoute(chatId: chatId, receiverId: receiverId),
      );
    } else {
      return Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _buildStandaloneChatDetailPage(
            context,
            chatId: chatId,
            receiverId: receiverId,
          ),
          settings: RouteSettings(name: '/chat/$chatId'),
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/di/service_locator.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/presentation/pages/auth/forgot_password_page.dart';
import 'package:flutter_chat_app/presentation/pages/auth/login_page.dart';
import 'package:flutter_chat_app/presentation/pages/auth/register_page.dart';
import 'package:flutter_chat_app/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/presentation/pages/chat/chat_list_page.dart';
import 'package:flutter_chat_app/presentation/pages/chat/create_group_page.dart';
import 'package:flutter_chat_app/presentation/pages/error_page.dart';
import 'package:flutter_chat_app/presentation/pages/notification_settings_page.dart';
import 'package:flutter_chat_app/presentation/pages/profile/edit_profile_page.dart';
import 'package:flutter_chat_app/presentation/pages/profile/profile_page.dart';
import 'package:flutter_chat_app/presentation/pages/settings/app_settings_page.dart';
import 'package:flutter_chat_app/presentation/pages/settings/chat_settings_page.dart';
import 'package:flutter_chat_app/presentation/pages/settings/privacy_settings_page.dart';
import 'package:flutter_chat_app/presentation/pages/splash_page.dart';
import 'package:flutter_chat_app/presentation/pages/user/contacts_page.dart';
import 'package:flutter_chat_app/presentation/pages/user/search_users_page.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Router instance
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authBloc = context.read<AuthBloc>();
      final isLoggedIn = authBloc.state.isAuthenticated;
      final isOnboarded = authBloc.state.isOnboarded;
      final isLoggingIn = state.matchedLocation.startsWith('/login') || 
                          state.matchedLocation.startsWith('/register') ||
                          state.matchedLocation.startsWith('/forgot-password');
      final isSplash = state.matchedLocation == '/splash';
      
      // Allow splash to proceed
      if (isSplash) return null;
      
      // If not logged in and not on login pages, redirect to login
      if (!isLoggedIn && !isLoggingIn) return '/login';
      
      // If logged in but not onboarded, redirect to onboarding
      if (isLoggedIn && !isOnboarded && !state.matchedLocation.startsWith('/onboarding')) {
        return '/onboarding';
      }
      
      // If logged in and trying to access login pages, redirect to home
      if (isLoggedIn && isOnboarded && isLoggingIn) return '/chats';
      
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      
      // Main app shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return child;
        },
        routes: [
          // Chats
          GoRoute(
            path: '/chats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new-group',
                builder: (context, state) => const CreateGroupPage(),
              ),
              GoRoute(
                path: ':chatId',
                builder: (context, state) {
                  final chatId = state.pathParameters['chatId']!;
                  return ChatDetailsPage(chatId: chatId);
                },
              ),
            ],
          ),
          
          // Contacts
          GoRoute(
            path: '/contacts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ContactsPage(),
            ),
          ),
          
          // Search
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchUsersPage(),
            ),
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfilePage(),
              ),
            ],
          ),
          
          // Settings
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AppSettingsPage(),
            ),
            routes: [
              GoRoute(
                path: 'chat',
                builder: (context, state) => const ChatSettingsPage(),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacySettingsPage(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationSettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
} 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/presentation/pages/auth/forgot_password_page.dart';
import 'package:flutter_chat_app/presentation/pages/auth/login_page.dart';
import 'package:flutter_chat_app/presentation/pages/auth/register_page.dart';
import 'package:flutter_chat_app/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/presentation/pages/chat/chat_list_page.dart';
import 'package:flutter_chat_app/presentation/pages/chat/create_group_page.dart';
import 'package:flutter_chat_app/presentation/pages/error_page.dart';
import 'package:flutter_chat_app/presentation/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Router instance
  static GoRouter router(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);
    
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final authState = authBloc.state;
        final isLoggedIn = authState.isAuthenticated;
        final isOnboarded = authState.isOnboarded;
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
          ],
        ),
      ],
      errorBuilder: (context, state) => ErrorPage(error: state.error),
    );
  }
} 
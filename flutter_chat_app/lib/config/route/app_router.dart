import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/features/auth/presentation/pages/auth/forgot_password_page.dart';
import 'package:flutter_chat_app/features/auth/presentation/pages/auth/login_page.dart';
import 'package:flutter_chat_app/features/auth/presentation/pages/auth/register_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_details_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/chat_list_page.dart';
import 'package:flutter_chat_app/features/chat/presentation/pages/chat/create_group_page.dart';
import 'package:flutter_chat_app/presentation/pages/error_page.dart';
import 'package:flutter_chat_app/presentation/pages/permissions/permissions_onboarding_page.dart';
import 'package:flutter_chat_app/presentation/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final _refreshListenable = _AuthBlocListenable();

  /// Router instance
  static GoRouter router(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);
    _refreshListenable.attach(authBloc);
    
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      debugLogDiagnostics: true,
      refreshListenable: _refreshListenable,
      redirect: (context, state) {
        final authState = authBloc.state;
        final isLoggedIn = authState.isAuthenticated;
        final isOnboarded = authState.isOnboarded;
        final isAuthResolving = authState is AuthInitial ||
            (authState is AuthLoading && authState.operation == 'check');
        final isLoggingIn = state.matchedLocation.startsWith('/login') || 
                          state.matchedLocation.startsWith('/register') ||
                          state.matchedLocation.startsWith('/forgot-password');
        final isSplash = state.matchedLocation == '/splash';
        final isOnboarding = state.matchedLocation.startsWith('/onboarding');
        final isHomeAlias = state.matchedLocation == '/home';
        
        // Splash acts as an auth gate: stay while checking, then route to target
        if (isSplash) {
          if (authState is AuthAuthenticated) {
            return authState.isOnboarded ? '/chats' : '/onboarding';
          }
          if (authState is AuthUnauthenticated) {
            return '/login';
          }
          if (authState is AuthError) {
            return '/login';
          }
          return null;
        }

        // While resolving auth state, force to splash to avoid redirect flicker
        if (isAuthResolving) return '/splash';

        // Normalize /home to /chats (legacy navigation paths)
        if (isHomeAlias) return '/chats';
        
        // If not logged in and not on login pages, redirect to login
        if (!isLoggedIn && !isLoggingIn) return '/login';
        
        // If logged in but not onboarded, redirect to onboarding
        if (isLoggedIn && !isOnboarded && !isOnboarding) return '/onboarding';

        // If already onboarded but still on onboarding, go to home
        if (isLoggedIn && isOnboarded && isOnboarding) return '/chats';
        
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

        // Legacy home alias
        GoRoute(
          path: '/home',
          redirect: (context, state) => '/chats',
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

        // Onboarding
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const PermissionsOnboardingPage(),
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

class _AuthBlocListenable extends ChangeNotifier {
  StreamSubscription<AuthState>? _sub;
  AuthBloc? _bloc;

  void attach(AuthBloc bloc) {
    if (identical(_bloc, bloc)) return;

    _bloc = bloc;
    _sub?.cancel();
    _sub = bloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
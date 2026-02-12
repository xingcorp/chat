import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/localization/error_message_provider.dart';
import 'package:flutter_chat_app/core/monitoring/i_analytics_service.dart';
import 'package:flutter_chat_app/core/monitoring/i_crash_reporter.dart';
import 'package:flutter_chat_app/core/monitoring/i_performance_monitor.dart';

/// Configuration for initializing the chat module as a package.
///
/// Host apps create a [ChatConfig] and pass it to [ChatModule.initialize]
/// to set up the chat module with their own auth, URLs, and customization.
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
/// ```
class ChatConfig {
  /// Base URL for the API server.
  final String baseUrl;

  /// GraphQL HTTP endpoint URL.
  final String graphqlUrl;

  /// GraphQL WebSocket endpoint URL for subscriptions.
  final String graphqlWsUrl;

  /// Socket.IO server URL for realtime events.
  final String socketUrl;

  /// Current access token. Used for initial authentication.
  /// Updated internally when [onTokenRefresh] succeeds.
  final String accessToken;

  /// Current refresh token. Optional — only needed if the chat module
  /// should store it for [TokenRepository] compatibility.
  final String? refreshToken;

  /// ID of the currently authenticated user.
  final String currentUserId;

  /// Username of the currently authenticated user.
  /// Used by [PackageModeAuthBloc] to create the User entity.
  final String? currentUserName;

  /// Email of the currently authenticated user.
  /// Used by [PackageModeAuthBloc] to create the User entity.
  final String? currentUserEmail;

  /// Full name of the currently authenticated user.
  /// Used by [PackageModeAuthBloc] to create the User entity.
  final String? currentUserFullName;

  /// Avatar URL of the currently authenticated user.
  /// Used by [PackageModeAuthBloc] to create the User entity.
  final String? currentUserAvatar;

  /// Called when the access token needs to be refreshed (e.g., after 401).
  /// Should return the new access token, or null if refresh failed.
  final Future<String?> Function()? onTokenRefresh;

  /// Called when authentication has expired and cannot be refreshed.
  /// Host app should navigate to login screen.
  final void Function()? onAuthExpired;

  /// Called when a token has been successfully refreshed.
  /// Host app can update its own token storage if needed.
  final void Function(String newAccessToken)? onTokenRefreshed;

  /// Called when a user profile avatar/name is tapped in chat.
  /// Host app can navigate to profile screen.
  final void Function(String userId)? onUserProfileTap;

  /// Locale for the chat UI. If null, uses platform default.
  final Locale? locale;

  /// Theme for the chat UI. If null, inherits from host app.
  final ThemeData? theme;

  /// Custom performance monitor. If null, uses [NoOpPerformanceMonitor].
  final IPerformanceMonitor? performanceMonitor;

  /// Custom crash reporter. If null, uses [NoOpCrashReporter].
  final ICrashReporter? crashReporter;

  /// Custom analytics service. If null, uses [NoOpAnalyticsService].
  final IAnalyticsService? analyticsService;

  /// Custom error message provider. If null, uses default Vietnamese messages.
  final ErrorMessageProvider? errorMessageProvider;

  /// Whether to hide the bottom navigation bar in chat pages.
  /// When true, the chat module will not show its own bottom navigation.
  /// Useful when embedding chat in a host app that has its own navigation.
  /// Defaults to false.
  final bool hideBottomNavBar;

  const ChatConfig({
    required this.baseUrl,
    required this.graphqlUrl,
    required this.graphqlWsUrl,
    required this.socketUrl,
    required this.accessToken,
    required this.currentUserId,
    this.currentUserName,
    this.currentUserEmail,
    this.currentUserFullName,
    this.currentUserAvatar,
    this.refreshToken,
    this.onTokenRefresh,
    this.onAuthExpired,
    this.onTokenRefreshed,
    this.onUserProfileTap,
    this.locale,
    this.theme,
    this.performanceMonitor,
    this.crashReporter,
    this.analyticsService,
    this.errorMessageProvider,
    this.hideBottomNavBar = false,
  });

  /// Creates a copy with the given fields replaced.
  ChatConfig copyWith({
    String? baseUrl,
    String? graphqlUrl,
    String? graphqlWsUrl,
    String? socketUrl,
    String? accessToken,
    String? refreshToken,
    String? currentUserId,
    String? currentUserName,
    String? currentUserEmail,
    String? currentUserFullName,
    String? currentUserAvatar,
    Future<String?> Function()? onTokenRefresh,
    void Function()? onAuthExpired,
    void Function(String)? onTokenRefreshed,
    void Function(String)? onUserProfileTap,
    Locale? locale,
    ThemeData? theme,
    IPerformanceMonitor? performanceMonitor,
    ICrashReporter? crashReporter,
    IAnalyticsService? analyticsService,
    ErrorMessageProvider? errorMessageProvider,
    bool? hideBottomNavBar,
  }) {
    return ChatConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      graphqlUrl: graphqlUrl ?? this.graphqlUrl,
      graphqlWsUrl: graphqlWsUrl ?? this.graphqlWsUrl,
      socketUrl: socketUrl ?? this.socketUrl,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserName: currentUserName ?? this.currentUserName,
      currentUserEmail: currentUserEmail ?? this.currentUserEmail,
      currentUserFullName: currentUserFullName ?? this.currentUserFullName,
      currentUserAvatar: currentUserAvatar ?? this.currentUserAvatar,
      onTokenRefresh: onTokenRefresh ?? this.onTokenRefresh,
      onAuthExpired: onAuthExpired ?? this.onAuthExpired,
      onTokenRefreshed: onTokenRefreshed ?? this.onTokenRefreshed,
      onUserProfileTap: onUserProfileTap ?? this.onUserProfileTap,
      locale: locale ?? this.locale,
      theme: theme ?? this.theme,
      performanceMonitor: performanceMonitor ?? this.performanceMonitor,
      crashReporter: crashReporter ?? this.crashReporter,
      analyticsService: analyticsService ?? this.analyticsService,
      errorMessageProvider: errorMessageProvider ?? this.errorMessageProvider,
      hideBottomNavBar: hideBottomNavBar ?? this.hideBottomNavBar,
    );
  }
}

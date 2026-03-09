/// Flutter Chat Module - Reusable chat package for Flutter apps.
///
/// Provides a complete chat experience (1-1, group chat, media, reactions,
/// offline-first, realtime) that any Flutter app can integrate by passing
/// a [ChatConfig] with server URLs and an access token.
///
/// ## Quick Start
///
/// **1. Add dependency** (in host app's `pubspec.yaml`):
/// ```yaml
/// dependencies:
///   flutter_chat_app:
///     path: ../flutter_chat_app   # or git url
/// ```
///
/// **2. Initialize** (once, after user login):
/// ```dart
/// import 'package:flutter_chat_app/flutter_chat_module.dart';
///
/// await ChatModule.initialize(ChatConfig(
///   baseUrl: 'https://api.example.com',
///   graphqlUrl: 'https://api.example.com/graphql',
///   graphqlWsUrl: 'wss://api.example.com/graphql',
///   socketUrl: 'wss://api.example.com/socket',
///   accessToken: userToken,
///   currentUserId: userId,
///   onTokenRefresh: () => myAuthService.refreshToken(),
///   onAuthExpired: () => navigator.pushReplacementNamed('/login'),
/// ));
/// ```
///
/// **3. Navigate to chat**:
/// ```dart
/// // Show conversation list
/// Navigator.push(context, ChatModule.chatListRoute());
///
/// // Open a specific conversation
/// Navigator.push(context, ChatModule.chatDetailRoute(chatId: 'abc123'));
///
/// // Or use the widgets directly
/// Scaffold(body: ChatModule.chatListPage());
/// ```
///
/// **4. Cleanup on logout**:
/// ```dart
/// await ChatModule.dispose();
/// ```
///
/// ## Customization
///
/// Override monitoring, error messages, or analytics by passing
/// custom implementations in [ChatConfig]:
///
/// ```dart
/// ChatConfig(
///   // ... required fields ...
///   performanceMonitor: MyPerformanceMonitor(),
///   crashReporter: MyCrashReporter(),
///   analyticsService: MyAnalyticsService(),
///   errorMessageProvider: EnglishErrorMessageProvider(),
/// )
/// ```
///
/// ## Architecture
///
/// The module uses Clean Architecture internally:
/// - **Presentation**: BLoC pattern with Flutter widgets
/// - **Domain**: Use cases, entities, repository interfaces
/// - **Data**: GraphQL + Socket.IO + Isar (offline DB)
/// - **Core**: DI (GetIt), networking, caching, monitoring
///
/// The host app never touches internal layers — only the public API
/// defined in this file.
library flutter_chat_module;

// ============================================================
// Module Entry Point & Configuration
// ============================================================

export 'chat_module.dart' show ChatModule;
export 'chat_config.dart' show ChatConfig;

// ============================================================
// Domain Entities — data models the host app will encounter
// when interacting with chat data (e.g. callbacks, events)
// ============================================================

export 'shared/domain/entities/chat.dart'
    show Chat, ChatType, GroupType, ConversationMember;
export 'shared/domain/entities/chat_message.dart'
    show
        ChatMessage,
        MessageSender,
        MessageReaction,
        MessageAttachment,
        ContentType,
        MessageStatus;
export 'shared/domain/entities/user.dart' show User;
export 'shared/domain/entities/attachment.dart'
    show Attachment, AttachmentType, AttachmentStatus;
export 'shared/domain/entities/message_type.dart' show MessageType;
export 'shared/domain/entities/message_queue_status.dart'
    show MessageQueueStatus;
export 'shared/domain/entities/message_error_type.dart' show MessageErrorType;

// ============================================================
// Auth Abstractions — host app may implement these for
// advanced token management scenarios
// ============================================================

export 'core/network/auth/token_provider.dart' show TokenProvider;
export 'core/network/auth/auth_delegate.dart'
    show AuthDelegate, NoOpAuthDelegate, CallbackAuthDelegate;

// ============================================================
// Customization Interfaces — host app can provide custom
// implementations via ChatConfig to replace NoOp defaults
// ============================================================

export 'core/monitoring/i_performance_monitor.dart'
    show IPerformanceMonitor, NoOpPerformanceMonitor;
export 'core/monitoring/i_crash_reporter.dart'
    show ICrashReporter, NoOpCrashReporter;
export 'core/monitoring/i_analytics_service.dart'
    show IAnalyticsService, NoOpAnalyticsService, AnalyticsEvent;
export 'core/localization/error_message_provider.dart'
    show
        ErrorMessageProvider,
        VietnameseErrorMessageProvider,
        EnglishErrorMessageProvider;
export 'core/services/chat_notification_payload.dart'
    show ChatNotificationPayload;

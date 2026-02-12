# Integration Guide — Flutter Chat Module

This guide shows how to add the **full chat experience** (conversations list, 1-1 chat, group chat, media sharing, reactions, offline queue, realtime messaging) to any existing Flutter app.

> **Single import, single init call, zero knowledge of internals required.**

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration Reference](#configuration-reference)
- [Navigation](#navigation)
- [Token Management](#token-management)
- [Customization](#customization)
- [Theming](#theming)
- [Lifecycle Management](#lifecycle-management)
- [Full Example](#full-example)
- [Architecture Overview](#architecture-overview)
- [Troubleshooting](#troubleshooting)

---

## Requirements

| Requirement | Version |
|---|---|
| Flutter SDK | >= 3.0.0 |
| Dart SDK | >= 3.0.0 |
| Backend API | GraphQL + Socket.IO compatible |

The backend must expose:
- A **GraphQL HTTP** endpoint (queries & mutations)
- A **GraphQL WebSocket** endpoint (subscriptions)
- A **Socket.IO** endpoint (realtime events, typing indicators, presence)
- Standard JWT auth (`Authorization: Bearer <token>`)

---

## Installation

Add the chat module as a dependency in your host app's `pubspec.yaml`:

```yaml
dependencies:
  flutter_chat_app:
    path: ../flutter_chat_app
```

Or via git:

```yaml
dependencies:
  flutter_chat_app:
    git:
      url: https://github.com/your-org/flutter_chat_app.git
      ref: main
```

Then run:

```bash
flutter pub get
```

### Standalone Mode Setup

If you're running flutter_chat_app as a **standalone app** (not as a package), you need to generate the `.env` file:

```bash
# Default: creates .env from .env.staging
dart run flutter_chat_app:setup

# For production environment
dart run flutter_chat_app:setup --env production

# Interactive mode - customize key values
dart run flutter_chat_app:setup --interactive

# Force overwrite existing .env
dart run flutter_chat_app:setup --force
```

> **Note:** When using flutter_chat_app as a **package** (via `ChatModule.initialize()`), you don't need `.env` — configuration is passed via `ChatConfig` instead.

---

## Quick Start

### 1. Single import

```dart
import 'package:flutter_chat_app/flutter_chat_module.dart';
```

This gives you access to:
- `ChatModule` — entry point (initialize, navigate, dispose)
- `ChatConfig` — configuration class
- Domain entities (`Chat`, `ChatMessage`, `User`, etc.)
- Customization interfaces (`IPerformanceMonitor`, `ICrashReporter`, etc.)

### 2. Initialize after login

```dart
await ChatModule.initialize(ChatConfig(
  baseUrl: 'https://api.yourserver.com',
  graphqlUrl: 'https://api.yourserver.com/graphql',
  graphqlWsUrl: 'wss://api.yourserver.com/graphql',
  socketUrl: 'wss://api.yourserver.com/socket',
  accessToken: currentUserToken,
  currentUserId: currentUserId,
  onTokenRefresh: () => yourAuthService.refreshToken(),
  onAuthExpired: () => yourRouter.go('/login'),
));
```

### 3. Navigate to chat

```dart
// Open conversations list
Navigator.push(context, ChatModule.chatListRoute());

// Open a specific conversation
Navigator.push(context, ChatModule.chatDetailRoute(chatId: 'abc123'));
```

### 4. Cleanup on logout

```dart
await ChatModule.dispose();
```

That's it. The entire chat UI, networking, caching, and offline support is handled internally.

---

## Configuration Reference

### Required fields

| Field | Type | Description |
|---|---|---|
| `baseUrl` | `String` | Base API URL (e.g. `https://api.example.com`) |
| `graphqlUrl` | `String` | GraphQL HTTP endpoint |
| `graphqlWsUrl` | `String` | GraphQL WebSocket endpoint for subscriptions |
| `socketUrl` | `String` | Socket.IO server URL |
| `accessToken` | `String` | JWT access token for the current user |
| `currentUserId` | `String` | ID of the authenticated user |

### Optional fields

| Field | Type | Default | Description |
|---|---|---|---|
| `refreshToken` | `String?` | `null` | Refresh token (stored internally for auto-refresh) |
| `onTokenRefresh` | `Future<String?> Function()?` | `null` | Called when a 401 is received. Return new access token or null |
| `onAuthExpired` | `void Function()?` | `null` | Called when token refresh also fails. Navigate to login |
| `onTokenRefreshed` | `void Function(String)?` | `null` | Called after successful token refresh. Sync with host storage |
| `onUserProfileTap` | `void Function(String userId)?` | `null` | Called when a user avatar/name is tapped. Navigate to profile |
| `locale` | `Locale?` | Platform default | Force a specific locale for chat UI |
| `theme` | `ThemeData?` | Inherited | Override theme (see [Theming](#theming)) |
| `performanceMonitor` | `IPerformanceMonitor?` | `NoOpPerformanceMonitor` | Custom performance monitoring |
| `crashReporter` | `ICrashReporter?` | `NoOpCrashReporter` | Custom crash reporting |
| `analyticsService` | `IAnalyticsService?` | `NoOpAnalyticsService` | Custom analytics tracking |
| `errorMessageProvider` | `ErrorMessageProvider?` | Vietnamese | Custom error messages (see [Customization](#customization)) |

---

## Navigation

### Option A: Route helpers (recommended)

Returns a `MaterialPageRoute` — the simplest approach:

```dart
// Conversations list
Navigator.push(context, ChatModule.chatListRoute());

// Conversation detail
Navigator.push(context, ChatModule.chatDetailRoute(chatId: conversationId));

// Create group
Navigator.push(context, ChatModule.createGroupRoute());
```

### Option B: Raw widgets

Use when you need custom routing (go_router, auto_route, etc.) or embed in a tab layout:

```dart
// In a go_router config
GoRoute(
  path: '/chat',
  builder: (context, state) => ChatModule.chatListPage(),
),
GoRoute(
  path: '/chat/:id',
  builder: (context, state) {
    final chatId = state.pathParameters['id']!;
    return ChatModule.chatDetailPage(chatId: chatId);
  },
),
```

```dart
// In a bottom nav tab
IndexedStack(
  index: currentTabIndex,
  children: [
    HomeTab(),
    ChatModule.chatListPage(),   // Chat tab
    ProfileTab(),
  ],
),
```

---

## Token Management

### Automatic refresh (recommended)

Pass `onTokenRefresh` in config. The chat module calls it when a 401 response is received:

```dart
ChatConfig(
  // ...
  onTokenRefresh: () async {
    // Call your auth service to get a new token
    final result = await authService.refreshAccessToken();
    return result.accessToken; // Return new token or null if failed
  },
  onAuthExpired: () {
    // Called when onTokenRefresh returns null (refresh failed)
    router.go('/login');
  },
  onTokenRefreshed: (newToken) {
    // Optional: sync the new token back to your own storage
    authService.updateLocalToken(newToken);
  },
)
```

### Manual token sync

When your host app refreshes its token independently (e.g., via a Dio interceptor), notify the chat module:

```dart
// In your auth interceptor or token refresh logic:
final newToken = await authApi.refresh();
await ChatModule.updateToken(newToken);
```

---

## Customization

### Error Messages (i18n)

By default, error messages are in Vietnamese. To use English or provide custom translations:

```dart
// Built-in English
ChatConfig(
  // ...
  errorMessageProvider: EnglishErrorMessageProvider(),
)

// Custom language
class JapaneseErrorMessages implements ErrorMessageProvider {
  const JapaneseErrorMessages();

  @override
  String getErrorMessage(String errorCode, {String? fallback}) {
    switch (errorCode) {
      case 'connection_failed': return '接続に失敗しました';
      case 'server_error': return 'サーバーエラー';
      default: return fallback ?? 'エラーが発生しました';
    }
  }

  @override
  List<String> getRecoveryGuidance(String category) => [];
}
```

### Performance Monitoring

```dart
class MyPerformanceMonitor implements IPerformanceMonitor {
  @override
  Future<void> startTrace(String name) async {
    // Start your APM trace (Datadog, New Relic, etc.)
  }

  @override
  Future<void> stopTrace(String name) async { /* ... */ }

  @override
  Future<void> recordMetric(String name, double value) async { /* ... */ }

  // ... implement remaining methods
}

ChatConfig(
  // ...
  performanceMonitor: MyPerformanceMonitor(),
)
```

### Crash Reporting

```dart
class SentryCrashReporter implements ICrashReporter {
  @override
  Future<void> recordError(dynamic error, StackTrace? stackTrace, {bool fatal = false}) async {
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  // ... implement remaining methods
}

ChatConfig(
  // ...
  crashReporter: SentryCrashReporter(),
)
```

### Analytics

```dart
class MixpanelAnalytics implements IAnalyticsService {
  @override
  Future<void> trackEvent(AnalyticsEvent event, {Map<String, dynamic>? parameters}) async {
    mixpanel.track(event.name, properties: parameters);
  }

  // ... implement remaining methods
}
```

---

## Theming

The chat UI inherits from the host app's `ThemeData` by default. To override:

```dart
ChatConfig(
  // ...
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    // Chat UI components use standard Material theme tokens
  ),
)
```

If no theme is provided, the chat module uses whatever `Theme.of(context)` returns from the host app's widget tree.

---

## Lifecycle Management

```
User Login
    │
    ▼
ChatModule.initialize(config)    ← Call once after successful login
    │
    ▼
Use chatListRoute() / chatDetailRoute()   ← Navigate freely
    │
    ▼
ChatModule.updateToken(newToken)  ← Call when host app refreshes token
    │
    ▼
ChatModule.dispose()              ← Call on logout (resets all state)
    │
    ▼
User logs in again → ChatModule.initialize(newConfig)
```

**Key behaviors:**
- `initialize()` is a no-op if already initialized (safe to call multiple times)
- `dispose()` clears all internal state, closes sockets, cleans caches
- After `dispose()`, you must call `initialize()` again before using any API
- Check `ChatModule.isInitialized` if unsure about current state

---

## Full Example

A complete host app integration:

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/flutter_chat_module.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: const LoginPage(),
    );
  }
}

// lib/pages/login_page.dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _login(BuildContext context) async {
    // 1. Your auth flow
    final authResult = await AuthService.login('user@example.com', 'password');

    // 2. Initialize chat module
    await ChatModule.initialize(ChatConfig(
      baseUrl: 'https://api.example.com',
      graphqlUrl: 'https://api.example.com/graphql',
      graphqlWsUrl: 'wss://api.example.com/graphql',
      socketUrl: 'wss://api.example.com/socket',
      accessToken: authResult.accessToken,
      currentUserId: authResult.userId,
      onTokenRefresh: () => AuthService.refresh(),
      onAuthExpired: () {
        ChatModule.dispose();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      },
    ));

    // 3. Go to home
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _login(context),
          child: const Text('Login'),
        ),
      ),
    );
  }
}

// lib/pages/home_page.dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My App')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Open chat list
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('Messages'),
            onPressed: () => Navigator.push(context, ChatModule.chatListRoute()),
          ),
          const SizedBox(height: 16),

          // Open specific conversation
          ElevatedButton.icon(
            icon: const Icon(Icons.person),
            label: const Text('Chat with Support'),
            onPressed: () => Navigator.push(
              context,
              ChatModule.chatDetailRoute(chatId: 'support-channel-id'),
            ),
          ),
          const SizedBox(height: 16),

          // Create group
          ElevatedButton.icon(
            icon: const Icon(Icons.group_add),
            label: const Text('New Group'),
            onPressed: () => Navigator.push(context, ChatModule.createGroupRoute()),
          ),
          const SizedBox(height: 32),

          // Logout
          TextButton(
            onPressed: () async {
              await ChatModule.dispose();
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
```

---

## Architecture Overview

The chat module is self-contained. The host app only interacts with the public API:

```
┌─────────────────────────────────────────────────┐
│                    Host App                      │
│                                                  │
│  ┌──────────────────────────────────────┐       │
│  │   import flutter_chat_module.dart     │       │
│  │                                       │       │
│  │   ChatModule.initialize(config)       │       │
│  │   ChatModule.chatListRoute()          │       │
│  │   ChatModule.chatDetailRoute(id)      │       │
│  │   ChatModule.updateToken(token)       │       │
│  │   ChatModule.dispose()                │       │
│  └───────────────┬──────────────────────┘       │
│                   │                              │
└───────────────────┼──────────────────────────────┘
                    │ (public API boundary)
┌───────────────────┼──────────────────────────────┐
│                   ▼                              │
│   ┌─────────────────────────────────────┐        │
│   │          ChatModule (DI)            │        │
│   │   BLoCs → UseCases → Repositories   │        │
│   └──────┬──────────┬──────────┬────────┘        │
│          │          │          │                  │
│   ┌──────▼──┐ ┌─────▼───┐ ┌───▼──────┐          │
│   │ GraphQL │ │Socket.IO│ │ Isar DB  │          │
│   │  Client │ │ Client  │ │ (offline)│          │
│   └─────────┘ └─────────┘ └──────────┘          │
│                                                  │
│          flutter_chat_app (package)              │
└──────────────────────────────────────────────────┘
```

**What the host app provides** (via ChatConfig):
- Server URLs and access token
- Token refresh callback
- Auth expired callback
- Optional: custom monitoring, analytics, crash reporting, error messages, theme

**What the chat module provides**:
- Full conversation list UI with search
- Chat detail UI with message input, media, reactions, replies
- Group creation UI
- Realtime messaging via Socket.IO
- GraphQL data layer with offline-first caching
- Automatic token refresh and retry on 401
- Typing indicators, read receipts, presence
- Media upload/download with progress
- Message queue for offline delivery

---

## Troubleshooting

### `StateError: ChatModule has not been initialized`

Call `ChatModule.initialize(config)` before navigating to any chat page. This is typically done right after user login.

### Token expired errors / 401s

Ensure `onTokenRefresh` returns a valid new token. If it returns `null`, the module calls `onAuthExpired`. Check your auth service's refresh logic.

### Chat not updating in realtime

Verify:
1. `socketUrl` is correct and accessible (HTTP/HTTPS, not WS/WSS — the module converts internally)
2. The backend Socket.IO server is running
3. The auth token is included in socket handshake (handled automatically)

### Dependency conflicts

If your host app uses a different version of a shared dependency (e.g., `get_it`, `flutter_bloc`), use dependency overrides in your `pubspec.yaml`:

```yaml
dependency_overrides:
  get_it: ^8.0.3
```

### Web platform issues

The module supports web via `kIsWeb` detection:
- Uses `InMemorySecureStorage` instead of `flutter_secure_storage`
- Uses `SharedPreferencesTokenStorage` instead of `SecureTokenStorage`
- Firebase initialization is handled conditionally

No additional configuration needed from the host app.

# Dual Deployment Mode Rules
# Applies to: flutter_chat_app/lib/**/*.dart

## FUNDAMENTAL RULE — NEVER FORGET

The Flutter chat app runs in **TWO modes**. ALL code changes MUST work in both:

| | Standalone App | Package Module |
|---|---|---|
| **Entry** | `main.dart` / `main_staging.dart` | `ChatModule.initialize(ChatConfig)` |
| **DI** | `configureDependencies()` | `ChatModuleInjection.initialize()` |
| **Shell** | `ChatAppShell.standalone()` | `ChatAppShell.package()` |
| **Auth** | Full login/register flow | Pre-authenticated (host token) |
| **Nav** | `go_router` full routing | Host app embeds pages as widgets |
| **Config** | `FlavorConfig` + env | `ChatConfig` object from host |
| **Cleanup** | Full `getIt.reset()` | Selective unregister (preserve host) |

## Key Files

| File | Purpose |
|---|---|
| `lib/flutter_chat_module.dart` | Public API barrel export — ONLY what host apps see |
| `lib/chat_module.dart` | Lifecycle: `initialize()`, `logout()`, `dispose()`, `updateToken()` |
| `lib/chat_config.dart` | Config object: URLs, token, userId, callbacks |
| `lib/core/di/injection.dart` | Standalone DI setup |
| `lib/core/di/chat_module_injection.dart` | Package mode DI (12-step from ChatConfig) |
| `lib/core/app/chat_app_shell.dart` | Dual-mode BLoC providers |
| `lib/core/app/package_mode_auth_repository.dart` | No-op auth for package mode |
| `lib/core/services/chat_module_event_bus.dart` | Event streams for host integration |

## MUST Follow Rules

### 1. DI Registration
- ❌ Register only in `injection.dart` → breaks package mode
- ✅ Register in BOTH `injection.dart` AND `chat_module_injection.dart`
- If using `@injectable` / `@LazySingleton`, verify the auto-generated config covers both environments

### 2. Authentication
- ❌ Assume login flow exists → breaks package mode
- ❌ Access `AuthBloc` and expect `AuthCheckRequested` event
- ✅ Use `IAuthRepository` interface — works in both modes
- ✅ In package mode, `PackageModeAuthRepository` returns pre-configured token

### 3. Navigation / Pages
- ❌ Create pages that only work inside `go_router`
- ✅ Pages must work as standalone widgets (host app may embed directly)
- ✅ Provide both `ChatModule.chatListPage()` and `ChatModule.chatListRoute()` for new pages

### 4. GetIt / Dependency Injection
- ❌ Call `getIt.reset()` in package mode → destroys host app registrations
- ✅ Use selective `getIt.unregister<T>()` for cleanup
- ✅ Check `getIt.isRegistered<T>()` before accessing optional dependencies

### 5. Public API Surface
- ❌ Export Data layer classes (DTOs, datasources, mappers) to host apps
- ❌ Export BLoC internals (events, states) to host apps
- ✅ Export only via `flutter_chat_module.dart`: ChatModule, ChatConfig, domain entities, abstractions

### 6. Event Communication with Host App
- ❌ Require host app to depend on internal BLoCs
- ✅ Use `ChatModuleEventBus` streams: unreadCount, newMessage, FCM
- ✅ Wire callbacks from `ChatConfig` to `ChatModuleEventBus` in `chat_module_injection.dart`

### 7. Token Management
- Standalone: Managed by `IAuthRepository` with refresh flow
- Package: Host app calls `ChatModule.updateToken(newToken)` when token refreshes
- ✅ Use `TokenProvider` abstraction — works in both modes

### 8. Cleanup
- `ChatModule.logout()` — Clears Isar DB, GraphQL cache, local datasources, singletons (user data only)
- `ChatModule.dispose()` — Unregisters chat singletons, clears AppConfig (does NOT call `getIt.reset()`)
- ✅ New services should register cleanup logic in both `logout()` and `dispose()` methods

### 9. Testing
- ✅ Test both standalone AND package mode initialization paths
- ✅ Mock `ChatConfig` for package mode tests
- ✅ Verify cleanup doesn't affect host app dependencies

## Checklist Before Submitting Code

- [ ] New service registered in both DI files?
- [ ] New page works as embedded widget (no router dependency)?
- [ ] No `getIt.reset()` in package-mode code paths?
- [ ] Public types exported in `flutter_chat_module.dart`?
- [ ] Cleanup handled in both `logout()` and `dispose()`?
- [ ] Auth logic uses `IAuthRepository` interface (not concrete)?
- [ ] Host app events wired via `ChatModuleEventBus`?

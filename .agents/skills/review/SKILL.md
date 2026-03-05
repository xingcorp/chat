---
name: review
description: Comprehensive code review for Flutter chat app — architecture compliance, code style, UI, API integration, error handling, performance, dual-mode
---

# Code Review Skill

Use this skill to review changed/staged code against the project's mandatory patterns and rules.

## Architecture Compliance

- [ ] Clean Architecture layers respected (Domain has NO Flutter imports, Data has NO Presentation imports)
- [ ] BLoCs extend `BaseBloc`, not raw `Bloc`
- [ ] Widgets extend `BaseStatefulWidget` / `BaseStatelessWidget`, not raw Flutter widgets
- [ ] States use `@freezed` and extend `BaseState`
- [ ] Repository interfaces prefixed with `I` in domain layer
- [ ] Repository impls annotated with `@LazySingleton(as: IRepository)`
- [ ] Use cases extend `UseCase<ReturnType, Params>`

## Dual Deployment Mode

- [ ] New services registered in BOTH `injection.dart` AND `chat_module_injection.dart`
- [ ] New pages work as both routed pages (standalone) AND embedded widgets (package)
- [ ] No `getIt.reset()` in package-mode code paths
- [ ] Auth uses `IAuthRepository` interface (not concrete implementation)
- [ ] Public types exported in `flutter_chat_module.dart` if host app needs them
- [ ] Cleanup logic in both `ChatModule.logout()` and `ChatModule.dispose()`
- [ ] Host app events wired via `ChatModuleEventBus`

## Code Style

- [ ] Package imports only (no relative imports)
- [ ] Single quotes for strings
- [ ] `const` constructors where possible
- [ ] `final` over `var` for immutables
- [ ] No `print()` — Logger only
- [ ] No `!` null assertion — use `?.` / `??`
- [ ] No `as` type cast — use `is` checks

## UI Compliance

- [ ] All text uses `AppText(context.l10n.xxx)` — no hardcoded strings
- [ ] All buttons use `AppButton` — no `ElevatedButton` etc
- [ ] All colors from `AppColors` — no `Colors.*` or hex
- [ ] All dimensions from `AppDimens` — no magic numbers
- [ ] Dark mode support considered

## API Integration

- [ ] GraphQL operations use correct backend names (`chatConversationList`, `chatMessageAdd`, etc.)
- [ ] Field mapping correct (`message`→`content`, `urls`→`mediaUrls`, `imgUrl`→`avatarUrl`)
- [ ] Pagination uses correct approach (cursor for messages, offset for conversations)

## Error Handling

- [ ] All repository methods return `Either<Failure, T>`
- [ ] BLoC handles both fold branches (failure + success)
- [ ] Network connectivity checked before remote calls
- [ ] Streams and subscriptions disposed in `close()` / `dispose()`

## Performance

- [ ] `const` widgets used for static content
- [ ] Lists use `ListView.builder` (via `AppListView`) not `Column` with `children`
- [ ] No unnecessary rebuilds
- [ ] Resources disposed properly

## Output

Provide specific feedback with code examples for each issue found.
Run `flutter analyze` and report any issues.

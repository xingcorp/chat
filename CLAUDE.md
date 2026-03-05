# Sharitek Office Chat — Monorepo

> Real-time chat application with offline-first architecture. NestJS backend + Flutter frontend.

## Monorepo Structure

```
├── src/                    # Backend: NestJS (TypeScript) — GraphQL-first, Socket.IO
├── flutter_chat_app/       # Frontend: Flutter (Dart) — Clean Architecture, BLoC, Offline-first
├── docs/                   # Documentation
└── .claude/                # Claude Code configuration
```

## ⚠️ CRITICAL: Flutter Dual Deployment Mode

The Flutter app (`flutter_chat_app/`) supports **TWO running modes**. ALWAYS consider both modes when making changes:

| Mode | Entry Point | DI Setup | Auth | Navigation |
|---|---|---|---|---|
| **Standalone App** | `main.dart`, `main_staging.dart`, `main_production.dart` | `configureDependencies()` | Full login/register flow | `go_router` with full routing |
| **Package Module** | `ChatModule.initialize(ChatConfig)` | `ChatModuleInjection.initialize()` | Pre-authenticated from host app token | Host app controls routing |

### Key Files for Dual Mode
- `lib/flutter_chat_module.dart` — Public API export (ONLY what host apps can access)
- `lib/chat_module.dart` — Lifecycle manager (`initialize`, `logout`, `dispose`, `updateToken`)
- `lib/chat_config.dart` — Configuration object passed by host app
- `lib/core/di/chat_module_injection.dart` — Package mode DI (12-step init from ChatConfig)
- `lib/core/app/chat_app_shell.dart` — Dual-mode shell (`ChatAppShell.standalone()` vs `ChatAppShell.package()`)
- `lib/core/app/package_mode_auth_repository.dart` — No-op auth for package mode
- `lib/core/services/chat_module_event_bus.dart` — Event streams for host app integration

### Rules When Modifying Code
1. **New features/services** — Ensure they work in BOTH modes (standalone DI + ChatModuleInjection)
2. **New public API** — Export via `flutter_chat_module.dart`, never expose Data layer internals
3. **DI registrations** — Register in both `injection.dart` AND `chat_module_injection.dart` if needed
4. **Auth-dependent code** — Handle both full auth (standalone) and pre-authenticated (package mode)
5. **Navigation** — Pages must be usable as both routed pages (standalone) AND embedded widgets (package)
6. **Cleanup** — Respect selective cleanup: `logout()` clears user data, `dispose()` preserves host app registrations
7. **Shared GetIt** — In package mode, chat module shares GetIt with host app. NEVER call `getIt.reset()` in package mode
8. **Event Bus** — Use `ChatModuleEventBus` for host app communication (unread count, new messages, FCM)

## Commands

```bash
# Flutter
cd flutter_chat_app
flutter pub get                                              # Install dependencies
flutter analyze                                              # Lint
flutter test                                                 # Run tests
dart run build_runner build --delete-conflicting-outputs      # Code generation (freezed, json, injectable, isar)
flutter gen-l10n                                             # Generate localization files

# Backend
cd src
npm install                                                  # Install dependencies
npm run start:dev                                            # Start dev server
npm run test                                                 # Run tests
npm run lint                                                 # Lint
```

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | NestJS, TypeScript, GraphQL (code-first), Socket.IO, TypeORM |
| Database | PostgreSQL (conversations/members), DynamoDB (messages), Redis (cache/pubsub), OpenSearch |
| Frontend | Flutter 3.x, Dart, BLoC, Freezed, GetIt + Injectable, Isar (offline), Socket.IO |
| Auth | JWT Bearer token, verified in GlobalGuard |

## Architecture (Flutter)

```
Presentation (UI + BLoC) → Domain (Entities + UseCases) → Data (Models + Repos + Sources)
```

Data flow: `User Action → BLoC Event → UseCase → Repository → DataSource → API/Isar`

### Layer Import Rules

| Layer | CAN import | CANNOT import |
|---|---|---|
| Domain (`lib/domain/`) | dartz, equatable, other domain | Flutter, Data, Presentation |
| Data (`lib/data/`) | Domain, infrastructure (http, isar, json) | Flutter UI, Presentation |
| Presentation (`lib/presentation/`) | Domain, Flutter, BLoC | Data (models, datasources) |

## Critical Rules

### ALWAYS
- Use `const` constructors wherever possible
- Use package imports (never relative imports)
- Use single quotes for strings
- Use `final` over `var` for immutables
- Use `is` type checks (not `as` casts)
- Use `??` / `?.` operators (not `!` null assertion)
- Use Logger service for logging (never `print()`)
- Use `context.l10n` for all UI strings (never hardcode)
- Use `App*` design system components (never direct Flutter widgets)
- Use `AppColors`, `AppDimens`, `AppConstants` (never hardcoded values)
- Return `Either<Failure, T>` from all repository methods
- Extend `BaseBloc`, `BaseStatefulWidget`, `BaseStatelessWidget` (never raw Flutter classes)
- Run `dart run build_runner build --delete-conflicting-outputs` after model/DTO changes
- Run `flutter gen-l10n` after adding new ARB strings

### NEVER
- Import Flutter packages in domain layer
- Use `print()` or `debugPrint()` — use Logger
- Use `!` null assertion operator
- Use `as` for type casting — use `is` checks
- Use `var` for immutable variables — use `final`
- Use `Text()`, `ElevatedButton()`, `TextField()` directly — use `AppText()`, `AppButton()`, `AppTextField()`
- Use `Colors.white`, `Color(0xFF...)` — use `AppColors.*`
- Use hardcoded dimensions `16.0`, `8.0` — use `AppDimens.*`
- Use `StatefulWidget`, `StatelessWidget`, `Bloc` directly — use base classes
- Modify files in `src/models/entities/` without understanding backend schema
- Push to main/master without PR review

## Naming Conventions

### Dart (Flutter)
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Private: `_prefix`
- Repository interfaces: `IFeatureRepository`
- Repository impls: `FeatureRepositoryImpl`
- Use cases: verb + noun (`SendMessage`, `GetMessages`)
- BLoCs: `FeatureBloc`, States: `FeatureState`, Events: `FeatureEvent`

### TypeScript (Backend)
- Files: `kebab-case.ts`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`

## Adding New Features (Order)

1. **Domain**: entity → repository interface (`I` prefix) → use case
2. **Data**: DTO/model (`@freezed` + `@JsonSerializable`) → mapper → datasource (remote + local) → repository impl (`@LazySingleton`)
3. **Presentation**: BLoC (event + state + bloc) → page → widgets
4. **Config**: DI registration → localization strings (ARB files) → routing
5. **Generate**: `dart run build_runner build --delete-conflicting-outputs` + `flutter gen-l10n`

## Error Handling Pattern

```
Domain:     Failure subclasses (ServerFailure, NetworkFailure, CacheFailure, ValidationFailure)
Data:       Exception classes → caught in repository → converted to Left(Failure)
Repository: check connectivity → try remote → cache locally → catch exceptions → return Either
BLoC:       result.fold((failure) => emitError(...), (data) => emit(SuccessState(...)))
```

## Performance Targets

- Startup: <2s | Memory: <150MB | Auth ops: <100ms | Message delivery: <100ms | UI: 60fps

## Project Status

⚠️ **CRITICAL**: The project has excellent architecture (95%) but incomplete implementation (35%).
- GraphQL operations in Flutter do NOT match backend API — see `chat-api-integration` steering file
- UseCase layer is mostly empty — needs 15+ use cases
- Real-time events only 40% implemented — missing reactions, edit, delete
- See `.kiro/PROJECT_STATUS_ANALYSIS.md` for full gap analysis

## Protected Areas

> Never modify files in `src/models/entities/` or backend database schemas unless explicitly asked.
> Never modify `.kiro/steering/` files unless explicitly asked.
> Never modify `flutter_chat_app/lib/core/base/` base classes unless explicitly asked.

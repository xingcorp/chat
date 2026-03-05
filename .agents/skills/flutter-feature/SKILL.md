---
name: flutter-feature
description: Scaffold a complete Clean Architecture feature for the Flutter chat app following all mandatory patterns (Domain → Data → Presentation)
---

# Flutter Feature Scaffold Skill

Use this skill when creating a new feature, adding a new screen, BLoC, use case, or repository for the Flutter chat app.

Do NOT use for backend (NestJS) changes, simple bug fixes, or config-only changes.

## CRITICAL: Dual Deployment Mode

Every new feature MUST work in BOTH modes:
- **Standalone App**: `main.dart` with `configureDependencies()` and `go_router`
- **Package Module**: `ChatModule.initialize(ChatConfig)` with `ChatModuleInjection.initialize()`

Register new services in BOTH `injection.dart` AND `chat_module_injection.dart`.
New pages must work as both routed pages AND embedded widgets.

## Step 1: Domain Layer

1. Create entity in `lib/domain/entities/` — pure Dart, no Flutter imports
2. Create repository interface in `lib/domain/repositories/` with `I` prefix
3. Create use case in `lib/domain/usecases/{feature}/` extending `UseCase<ReturnType, Params>`
4. All methods return `Either<Failure, T>`

## Step 2: Data Layer

1. Create DTO in `lib/data/dtos/` using `@freezed` + `@JsonSerializable`
   - Use `@JsonKey(name: 'backend_field')` for field mapping
   - Backend `message` → DTO `content`, `urls` → `mediaUrls`, `imgUrl` → `avatarUrl`
2. Create mapper in `lib/data/mappers/` for DTO ↔ Entity conversion
3. Create remote datasource in `lib/data/datasources/{feature}/` using correct GraphQL operations
   - Use correct backend names: `chatConversationList`, `chatMessageAdd`, etc.
4. Create local datasource using Isar for offline storage
5. Create repository impl in `lib/data/repositories/` with `@LazySingleton(as: IRepository)`
   - Pattern: Check connectivity → try remote → cache locally → catch exceptions → return Either

## Step 3: Presentation Layer

1. Create event file using `@freezed` in `lib/presentation/blocs/{feature}/`
2. Create state file using `@freezed` extending `BaseState`
3. Create BLoC extending `BaseBloc` with `@injectable`
4. Create page extending `BaseStatefulWidget`
5. Create widgets using `App*` design system components only
6. All strings via `context.l10n`, colors via `AppColors`, dimensions via `AppDimens`

## Step 4: Config

1. Register in DI — BOTH `lib/core/di/injection.dart` AND `lib/core/di/chat_module_injection.dart`
2. Add localization strings to `lib/l10n/app_en.arb` AND `lib/l10n/app_vi.arb`
3. Add route if needed
4. If public-facing, export in `lib/flutter_chat_module.dart`

## Step 5: Generate

```bash
cd flutter_chat_app
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
```

## Constraints

- MUST use base classes (`BaseBloc`, `BaseStatefulWidget`, `BaseStatelessWidget`)
- MUST use `App*` design system components (`AppText`, `AppButton`, `AppTextField`)
- MUST use `context.l10n` for all strings
- MUST use `Either<Failure, T>` for error handling
- MUST use `@injectable` annotations for DI
- NEVER import Flutter in domain layer
- NEVER use raw Flutter widgets (`Text`, `ElevatedButton`, etc.)
- NEVER hardcode strings, colors, or dimensions
- NEVER call `getIt.reset()` in package mode code paths

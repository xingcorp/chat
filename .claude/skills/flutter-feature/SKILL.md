# Flutter Feature Scaffold Skill

Use this skill when:
- Creating a new feature for the Flutter chat app
- Adding a new screen, BLoC, use case, or repository
- Implementing any chat-related functionality (messages, reactions, groups, etc.)

Do NOT use this skill for:
- Backend (NestJS) changes
- Simple bug fixes that don't require new files
- Configuration-only changes

## What this skill does

Scaffolds a complete Clean Architecture feature following the project's mandatory patterns:

### Step 1: Domain Layer
1. Create entity in `lib/domain/entities/` (pure Dart, no Flutter imports)
2. Create repository interface in `lib/domain/repositories/` with `I` prefix
3. Create use case in `lib/domain/usecases/{feature}/` extending `UseCase<ReturnType, Params>`
4. All methods return `Either<Failure, T>`

### Step 2: Data Layer
1. Create DTO in `lib/data/dtos/` using `@freezed` + `@JsonSerializable`
   - Use `@JsonKey(name: 'backend_field')` for field mapping
2. Create mapper in `lib/data/mappers/` for DTO ↔ Entity conversion
3. Create remote datasource in `lib/data/datasources/{feature}/` using correct GraphQL operations
4. Create local datasource using Isar for offline storage
5. Create repository impl in `lib/data/repositories/` with `@LazySingleton(as: IRepository)`
   - Check connectivity → try remote → cache locally → catch exceptions → return Either

### Step 3: Presentation Layer
1. Create event file using `@freezed` in `lib/presentation/blocs/{feature}/`
2. Create state file using `@freezed` extending `BaseState`
3. Create BLoC extending `BaseBloc` with `@injectable`
4. Create page extending `BaseStatefulWidget`
5. Create widgets using `App*` design system components only
6. All strings via `context.l10n`, colors via `AppColors`, dimensions via `AppDimens`

### Step 4: Config
1. Register in DI (`lib/core/di/chat_module_injection.dart`)
2. Add localization strings to `lib/l10n/app_en.arb` AND `lib/l10n/app_vi.arb`
3. Add route if needed

### Step 5: Generate
```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
```

## Constraints
- MUST use base classes (BaseBloc, BaseStatefulWidget, BaseStatelessWidget)
- MUST use App* design system components
- MUST use context.l10n for strings
- MUST use Either<Failure, T> for error handling
- MUST use @injectable annotations for DI
- NEVER import Flutter in domain layer
- NEVER use raw Flutter widgets (Text, ElevatedButton, etc.)
- NEVER hardcode strings, colors, or dimensions

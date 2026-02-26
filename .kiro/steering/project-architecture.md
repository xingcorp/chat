---
inclusion: always
---

# Project Architecture

> Core architecture rules. For base class patterns see base-class-patterns.md. For UI rules see design-system-usage.md.

## Key Source Files

- Base classes: #[[file:flutter_chat_app/lib/core/base/base_widget.dart]], #[[file:flutter_chat_app/lib/core/base/base_state.dart]]
- Base BLoC: #[[file:flutter_chat_app/lib/presentation/blocs/base/base_bloc.dart]]
- Error types: #[[file:flutter_chat_app/lib/core/error/failures.dart]], #[[file:flutter_chat_app/lib/core/error/exceptions.dart]]
- DI setup: #[[file:flutter_chat_app/lib/core/di/injection.dart]], #[[file:flutter_chat_app/lib/core/di/chat_module_injection.dart]]
- App config: #[[file:flutter_chat_app/lib/core/config/flavor_config.dart]]

## Monorepo Structure

- Backend: NestJS (TypeScript) → `src/`
- Frontend: Flutter (Dart) → `flutter_chat_app/`

## Clean Architecture Layers

```
Presentation (UI + BLoC) → Domain (Entities + UseCases) → Data (Models + Repos + Sources)
```

Data flow: `User Action → BLoC Event → UseCase → Repository → DataSource → API`

## Layer Import Rules

| Layer | CAN import | CANNOT import |
|---|---|---|
| Domain (`lib/domain/`) | dartz, equatable, other domain | Flutter, Data, Presentation, infrastructure |
| Data (`lib/data/`) | Domain, infrastructure (http, isar, json) | Flutter UI, Presentation |
| Presentation (`lib/presentation/`) | Domain, Flutter, BLoC | Data (models, datasources) |

## Directory Structure

```
flutter_chat_app/lib/
├── core/           # DI, network, storage, base classes, error handling
├── data/           # Models, DTOs, mappers, datasources, repository impls
├── domain/         # Entities, usecases, repository interfaces, services
├── presentation/   # BLoCs, pages, widgets
├── features/       # Feature-specific modules (chat, etc.)
├── config/         # Routes, themes, constants
└── main*.dart      # Entry points (staging, production)
```

## Core Principles

- Offline-first: Isar DB + sync queue
- State management: BLoC with `Either<Failure, T>`
- DI: GetIt + Injectable (`@injectable`, `@singleton`, `@lazySingleton`)
- Real-time: Socket.IO via EnhancedSocketManager
- Multi-flavor: Staging / Production via FlavorConfig

## Naming Conventions (Dart)

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/methods: `camelCase`
- Private: `_prefix`
- Repository interfaces: `IFeatureRepository`
- Repository impls: `FeatureRepositoryImpl`
- Use cases: verb + noun (`SendMessage`, `GetMessages`)
- BLoCs: `FeatureBloc`, States: `FeatureState`, Events: `FeatureEvent`
- Pages: `FeaturePage`, Widgets: descriptive name

## Code Style Rules

ALWAYS: `const` constructors, package imports, single quotes, `final` over `var`, `is` checks, `??`/`?.` operators, Logger service, `context.l10n`, design system components, dispose resources

NEVER: relative imports, double quotes, `print()`, `!` null assertion, `as` type cast, `var` for immutables, direct `Bloc`/`StatefulWidget`/`StatelessWidget`/`Text` widget

## Adding New Features (Order)

1. Domain: entity → repository interface (`I` prefix) → use case
2. Data: DTO/model → mapper → datasource (remote + local) → repository impl (`@LazySingleton`)
3. Presentation: BLoC (event + state + bloc) → page → widgets
4. Config: DI registration → localization strings (ARB files) → routing
5. Generate: `dart run build_runner build --delete-conflicting-outputs` + `flutter gen-l10n`

## Error Handling

- Domain: `Failure` subclasses (ServerFailure, NetworkFailure, CacheFailure, ValidationFailure)
- Data: `Exception` classes → caught in repository → converted to `Left(Failure)`
- Repository: check connectivity → try remote → cache locally → catch exceptions → return `Either`
- BLoC: `result.fold((failure) => emitError(...), (data) => emit(SuccessState(...)))`
- Mixin: #[[file:flutter_chat_app/lib/core/error/repository_error_mixin.dart]]

## Performance Targets

- Startup: <2s | Memory: <150MB | Auth ops: <100ms | Message delivery: <100ms | UI: 60fps

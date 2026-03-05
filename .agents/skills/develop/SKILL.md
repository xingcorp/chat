---
name: develop
description: Guided feature development workflow — Explore → Plan → Code → Verify — following Clean Architecture and all project patterns
---

# Feature Development Workflow

Use this skill when implementing a new Flutter feature for the Sharitek Office Chat app.

## CRITICAL: Dual Deployment Mode

Every new feature MUST work in BOTH:
- **Standalone App**: `main.dart`, `configureDependencies()`, `go_router`, full auth
- **Package Module**: `ChatModule.initialize(ChatConfig)`, `ChatModuleInjection`, embedded widgets, pre-auth

## 1. Explore

- Read the relevant steering files in `.kiro/steering/` for context
- Read `AGENTS.md` (root + flutter_chat_app) for patterns and rules
- Identify which layers need changes (domain, data, presentation)
- Check existing patterns in similar features
- Identify how the feature affects both deployment modes

## 2. Plan

- Propose a step-by-step implementation plan following Clean Architecture order:
  1. **Domain**: entity → repository interface (`I` prefix) → use case
  2. **Data**: DTO (`@freezed` + `@JsonSerializable`) → mapper → datasource (remote + local) → repository impl (`@LazySingleton`)
  3. **Presentation**: BLoC (event + state + bloc) → page → widgets
  4. **Config**: DI registration (BOTH injection files) → localization strings (ARB) → routing
- List all files that will be created or modified
- Describe test strategy
- Note any dual-mode considerations

## 3. Code (after plan approval)

- Implement ONE step at a time
- Follow ALL mandatory patterns:
  - `BaseBloc`, `BaseStatefulWidget`, `BaseStatelessWidget`
  - `@freezed` states extending `BaseState`
  - `App*` design system widgets only
  - `context.l10n` for all strings
  - `AppColors`, `AppDimens` for styling
  - `Either<Failure, T>` error handling
  - `@injectable` DI annotations
- Use correct backend API names (`chatConversationList`, `chatMessageAdd`, etc.)
- Map backend fields correctly (`message`→`content`, `urls`→`mediaUrls`, `imgUrl`→`avatarUrl`)
- Register in both DI files for dual-mode support

## 4. Verify

```bash
cd flutter_chat_app
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter test
```

- Confirm feature works in standalone mode
- Confirm feature works as embedded widget (package mode)
- Check no `getIt.reset()` in package-mode paths

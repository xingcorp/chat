---
name: simplify
description: Review and improve code quality across the Flutter chat app — base classes, design system, imports, patterns, errors, performance
---

# Simplify & Code Quality Skill

Use this skill when reviewing changed code for quality, refactoring to follow project patterns, cleaning up after feature implementation, or when asked to simplify/improve code.

Do NOT use for adding new features (use `flutter-feature`), API fixes (use `api-integration`), or architecture redesign.

## CRITICAL: Dual Deployment Mode

When reviewing code, verify it works in BOTH:
- **Standalone App** mode (full DI, full auth, go_router)
- **Package Module** mode (ChatModuleInjection, pre-auth, embedded widgets)

Check: DI registered in both files? Pages work as embedded widgets? No `getIt.reset()`?

## Check 1: Base Class Usage

- All BLoCs extend `BaseBloc` (not `Bloc`)
- All StatefulWidgets extend `BaseStatefulWidget` (not `StatefulWidget`)
- All StatelessWidgets extend `BaseStatelessWidget` (not `StatelessWidget`)
- All States extend `BaseState` with `@freezed`
- Replace any violations

## Check 2: Design System Compliance

- Replace `Text()` → `AppText()`
- Replace `ElevatedButton()` → `AppButton()`
- Replace `TextField()` → `AppTextField()`
- Replace `ListView()` → `AppListView()`
- Replace `AlertDialog()` → `AppAlertDialog`
- Replace `SnackBar()` → `AppSnackBar`
- Replace `CircularProgressIndicator()` → `AppProgressIndicator()`
- Replace `CircleAvatar()` → `AppAvatar()`
- Replace `Colors.*` → `AppColors.*`
- Replace hardcoded numbers → `AppDimens.*` / `AppConstants.*`
- Replace hardcoded strings → `context.l10n.*`

## Check 3: Import Organization

- Use package imports only (no relative imports)
- Group imports: dart → flutter → packages → project
- Remove unused imports
- Domain layer: NO Flutter, Data, or Presentation imports
- Data layer: NO Presentation imports
- Presentation layer: NO Data imports (use Domain entities)

## Check 4: Code Patterns

- Replace `var` with `final` for immutables
- Add `const` constructors where possible
- Replace `!` null assertions with `?.` / `??`
- Replace `as` casts with `is` checks
- Replace `print()` / `debugPrint()` with Logger
- Ensure `dispose()` / `close()` cleanup resources
- Use `safeSetState()` not `setState()` in BaseState

## Check 5: Error Handling

- All repository methods return `Either<Failure, T>`
- BLoC handles both failure and success in `fold`
- Connectivity check before remote calls
- Proper exception → Failure conversion
- Use `RepositoryErrorMixin` for consistent error handling

## Check 6: Reusability

- Extract repeated widgets into shared components
- Reuse existing `ErrorDisplayWidget`, `ConnectionStatusWidget`
- Consolidate duplicate logic into base classes or mixins
- Move magic constants to `AppConstants` or `AppDimens`

## Check 7: Performance

- Use `const` for static widgets
- Use `ListView.builder` (via `AppListView`) for long lists
- Avoid unnecessary rebuilds with proper `BlocBuilder` usage
- Dispose streams and subscriptions

## Output

For each issue found, provide:
1. File and line reference
2. Current code (what's wrong)
3. Fixed code (what it should be)
4. Brief explanation

# Simplify & Code Quality Skill

Use this skill when:
- Reviewing changed code for quality, reuse, and efficiency
- Refactoring existing code to follow project patterns
- Cleaning up code after a feature implementation
- Asked to simplify or improve code quality

Do NOT use this skill for:
- Adding new features (use flutter-feature skill)
- API integration fixes (use api-integration skill)
- Architecture redesign

## What this skill does

Reviews and improves code quality across the Flutter chat app.

### Check 1: Base Class Usage
- All BLoCs extend `BaseBloc` (not `Bloc`)
- All StatefulWidgets extend `BaseStatefulWidget` (not `StatefulWidget`)
- All StatelessWidgets extend `BaseStatelessWidget` (not `StatelessWidget`)
- All States extend `BaseState` with `@freezed`
- Replace any violations

### Check 2: Design System Compliance
- Replace `Text()` → `AppText()`
- Replace `ElevatedButton()` → `AppButton()`
- Replace `TextField()` → `AppTextField()`
- Replace `Colors.*` → `AppColors.*`
- Replace hardcoded numbers → `AppDimens.*` / `AppConstants.*`
- Replace hardcoded strings → `context.l10n.*`

### Check 3: Import Organization
- Use package imports only (no relative imports)
- Group imports: dart → flutter → packages → project
- Remove unused imports

### Check 4: Code Patterns
- Replace `var` with `final` for immutables
- Add `const` constructors where possible
- Replace `!` null assertions with `?.` / `??`
- Replace `as` casts with `is` checks
- Replace `print()` with Logger
- Ensure `dispose()` / `close()` cleanup resources

### Check 5: Error Handling
- All repository methods return `Either<Failure, T>`
- BLoC handles both failure and success in fold
- Connectivity check before remote calls
- Proper exception → Failure conversion

### Check 6: Reusability
- Extract repeated widgets into shared components
- Reuse existing `ErrorDisplayWidget`, `ConnectionStatusWidget`
- Consolidate duplicate logic into base classes or mixins
- Move magic constants to `AppConstants` or `AppDimens`

### Check 7: Performance
- Use `const` for static widgets
- Use `ListView.builder` (via `AppListView`) for long lists
- Avoid rebuilds with proper `BlocBuilder` usage
- Dispose streams and subscriptions

## Output
For each issue found, provide:
1. File and line reference
2. Current code (what's wrong)
3. Fixed code (what it should be)
4. Brief explanation

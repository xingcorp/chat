---
type: "agent_requested"
description: "Example description"
---
# Flutter Best Practices Rules
**Type:** Always  
**Description:** Flutter-specific best practices for messaging apps

## Widget Design
- Use `const` constructors whenever possible
- Keep widgets small and focused
- Extract complex widgets into separate classes
- Use `RepaintBoundary` for expensive widgets
- Prefer `StatelessWidget` over `StatefulWidget`

## State Management
- Use BLoC pattern for complex state
- One BLoC per feature/screen
- Use `freezed` for events and states
- Emit loading states for async operations
- Handle errors in BLoC, not in UI

## Performance
- Use `ListView.builder` for large lists
- Implement lazy loading for data
- Cache network images
- Use `AutomaticKeepAliveClientMixin` sparingly
- Profile memory usage regularly

## File Organization
- Use feature-based folder structure
- Group related files together
- Use `barrel exports` (index.dart files)
- Keep file names descriptive and consistent
- Separate UI, logic, and data concerns

## Naming Conventions
- Use `snake_case` for files: `user_profile_screen.dart`
- Use `PascalCase` for classes: `UserProfileScreen`
- Use `camelCase` for variables: `userName`
- Use descriptive names: `isLoading` not `flag`
- Avoid abbreviations: `message` not `msg`

## Error Handling
- Use `Either<Failure, T>` pattern
- Create specific failure types
- Handle network errors gracefully
- Show user-friendly error messages
- Log errors for debugging

## Testing
- Write unit tests for business logic
- Write widget tests for UI components
- Use `mockito` for mocking dependencies
- Test both success and failure scenarios
- Aim for >80% code coverage

## Dependencies
- Keep dependencies minimal
- Use specific versions in pubspec.yaml
- Regularly update dependencies
- Avoid deprecated packages
- Use official packages when available

## Code Quality
- Use `flutter analyze` regularly
- Follow `effective_dart` guidelines
- Use `dart format` for consistent formatting
- Enable all lint rules
- Fix warnings and hints promptly

# Base Patterns Enforcement - Project-Wide Mandate

> **STATUS**: 🚨 MANDATORY COMPLIANCE - Effective Immediately

## Overview

This document serves as the enforcement notice for base class patterns across the entire Flutter Chat App project. All developers, AI assistants, and code reviewers MUST adhere to these patterns without exception.

## What Changed

As of **2025-01-28**, the following base class patterns are now **MANDATORY**:

### 1. BLoC Layer
- ✅ **MUST** extend `BaseBloc<EventType, StateType>`
- ✅ **MUST** extend `BaseState` for all state classes
- ❌ **FORBIDDEN** to extend `Bloc` or create states without `BaseState`

### 2. Widget Layer
- ✅ **MUST** extend `BaseStatefulWidget` for stateful widgets
- ✅ **MUST** extend `BaseState<T>` for state classes
- ✅ **MUST** extend `BaseStatelessWidget` for stateless widgets
- ❌ **FORBIDDEN** to extend `StatefulWidget` or `StatelessWidget` directly

### 3. Constants
- ✅ **MUST** use `AppConstants` for all UI dimensions, durations, and limits
- ❌ **FORBIDDEN** to hardcode values like `16.0`, `8.0`, `Duration(milliseconds: 300)`

### 4. Logging
- ✅ **MUST** use `Logger` for all logging
- ❌ **FORBIDDEN** to use `print()` or `debugPrint()`

### 5. Localization
- ✅ **MUST** use `context.l10n` for all user-facing strings
- ❌ **FORBIDDEN** to hardcode strings in UI

### 6. Dependency Injection
- ✅ **MUST** use `@injectable` or `@LazySingleton` annotations
- ❌ **FORBIDDEN** to manually instantiate dependencies

### 7. Widget Composition
- ✅ **MUST** reuse existing common widgets (`ErrorDisplayWidget`, `ConnectionStatusWidget`)
- ❌ **FORBIDDEN** to create duplicate error/loading widgets

### 8. Performance
- ✅ **MUST** use `const` constructors wherever possible
- ❌ **FORBIDDEN** to omit `const` when applicable

## Why This Matters

### Without Base Classes (❌ WRONG):
```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial());
  
  void addReaction(String messageId, String emoji) {
    print('Adding reaction'); // No logging
    emit(ChatLoading()); // No error handling
  }
}
```

**Problems:**
- ❌ No error handling or classification
- ❌ No logging integration
- ❌ No analytics tracking
- ❌ No performance monitoring
- ❌ No crash reporting
- ❌ Inconsistent patterns across codebase

### With Base Classes (✅ CORRECT):
```dart
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  final AddReactionUseCase _addReactionUseCase;
  final Logger _logger;
  
  ChatBloc({
    required AddReactionUseCase addReactionUseCase,
    required Logger logger,
  }) : _addReactionUseCase = addReactionUseCase,
       _logger = logger,
       super(const ChatState.initial());
  
  Future<void> _onAddReaction(event, emit) async {
    _logger.i('Adding reaction: ${event.emojiCode}');
    emitLoading(message: 'Adding reaction...');
    
    final result = await _addReactionUseCase(
      messageId: event.messageId,
      emojiCode: event.emojiCode,
    );
    
    result.fold(
      (failure) => emitError(failure.message, error: failure),
      (message) => emit(ChatState.messageUpdated(message: message)),
    );
  }
}
```

**Benefits:**
- ✅ Automatic error handling and classification
- ✅ Built-in logging with Logger
- ✅ Analytics integration
- ✅ Performance monitoring
- ✅ Crash reporting
- ✅ Consistent patterns across codebase
- ✅ Easier maintenance and debugging

## Enforcement Mechanism

### 1. Code Review
All pull requests will be reviewed for compliance. Non-compliant code will be **REJECTED**.

### 2. AI Assistant Instructions
All AI assistants (including this one) are instructed to:
- Always use base classes
- Never generate code that violates these patterns
- Suggest refactoring when encountering non-compliant code

### 3. Steering Files
The `.kiro/steering/base-class-patterns.md` file is automatically loaded by AI assistants to ensure compliance.

### 4. Checklist
Before committing, verify:
- [ ] All BLoCs extend `BaseBloc`
- [ ] All States extend `BaseState`
- [ ] All StatefulWidgets extend `BaseStatefulWidget`
- [ ] All StatelessWidgets extend `BaseStatelessWidget`
- [ ] All constants use `AppConstants`
- [ ] All logging uses `Logger`
- [ ] All strings use `context.l10n`
- [ ] All DI uses `@injectable`
- [ ] All common widgets are reused
- [ ] All widgets use `const` where possible

## Migration Plan

### For Existing Code
1. **Identify** non-compliant code
2. **Refactor** to use base classes
3. **Test** thoroughly
4. **Commit** with clear migration notes

### For New Code
1. **Always** start with base classes
2. **Never** extend Flutter classes directly
3. **Always** use `AppConstants`, `Logger`, `context.l10n`

## Resources

- **Full Documentation**: `.kiro/steering/base-class-patterns.md`
- **Base Classes Location**:
  - BLoC: `flutter_chat_app/lib/presentation/blocs/base/base_bloc.dart`
  - State: `flutter_chat_app/lib/presentation/blocs/base/base_state.dart`
  - Widget: `flutter_chat_app/lib/core/base/base_widget.dart`
  - Constants: `flutter_chat_app/lib/core/constants/app_constants.dart`

## Questions?

If you have questions about these patterns:
1. Read the full documentation in `.kiro/steering/base-class-patterns.md`
2. Review existing code that follows these patterns
3. Ask the team lead or senior developers

## Summary

**This is not optional. This is mandatory.**

All code written for this project MUST follow these base class patterns. No exceptions. No compromises.

---

**Effective Date**: 2025-01-28  
**Status**: ACTIVE - MANDATORY COMPLIANCE  
**Enforcement**: Code Review Required  
**Last Updated**: 2025-01-28

# Kiro Hooks - Complete Guide

## 📋 Overview

This directory contains a comprehensive set of hooks for the Sharitek Office Management project, covering both Flutter frontend and NestJS backend development.

## 🎯 Hook Categories

### 1. Code Quality & Review

#### **flutter-code-review.kiro.hook**
- **Trigger**: When Flutter files are edited
- **Purpose**: Review Flutter code for architecture, performance, and best practices
- **Checks**: Clean Architecture, BLoC pattern, const usage, null safety, localization

#### **nestjs-code-review.kiro.hook**
- **Trigger**: When NestJS files are edited
- **Purpose**: Review backend code for patterns and best practices
- **Checks**: Module organization, DI, GraphQL patterns, error handling

#### **import-organizer.kiro.hook**
- **Trigger**: When any Dart/TS file is edited
- **Purpose**: Validate import organization and ordering
- **Checks**: Package imports (no relative), proper ordering, path aliases

#### **file-size-monitor.kiro.hook**
- **Trigger**: When any Dart/TS file is edited
- **Purpose**: Monitor file size and suggest splitting large files
- **Limits**: Warning >400 lines, Critical >600 lines

### 2. Architecture Validation

#### **domain-layer-guard.kiro.hook** 🚨 CRITICAL
- **Trigger**: When domain layer files are edited
- **Purpose**: Enforce strict domain layer rules
- **Checks**: No Flutter imports, no infrastructure dependencies, pure business logic

#### **bloc-pattern-validator.kiro.hook**
- **Trigger**: When BLoC files are edited
- **Purpose**: Validate BLoC implementation with Freezed
- **Checks**: Event/State design, error handling, disposal, Either<Failure, T>

#### **repository-pattern-validator.kiro.hook**
- **Trigger**: When repository files are edited
- **Purpose**: Validate repository implementation
- **Checks**: Interface implementation, error handling, Either<Failure, T>, offline-first

#### **graphql-pattern-validator.kiro.hook**
- **Trigger**: When GraphQL resolvers are edited
- **Purpose**: Validate GraphQL patterns in NestJS
- **Checks**: Decorators, input validation, resolver structure, naming conventions

### 3. Dependency Injection

#### **dependency-injection-validator.kiro.hook**
- **Trigger**: When services/repositories/blocs are edited
- **Purpose**: Validate proper DI usage
- **Checks**: Injectable annotations, constructor injection, no direct instantiation

### 4. Offline & Real-time

#### **offline-first-validator.kiro.hook**
- **Trigger**: When repositories/sync services are edited
- **Purpose**: Validate offline-first patterns
- **Checks**: Cache-first strategy, sync queue, optimistic updates, conflict resolution

#### **realtime-pattern-validator.kiro.hook**
- **Trigger**: When Socket.IO files are edited
- **Purpose**: Validate real-time messaging patterns
- **Checks**: Connection management, event handling, room management, error handling

### 5. Security & Best Practices

#### **security-checker.kiro.hook** 🔒
- **Trigger**: When any Dart/TS file is edited
- **Purpose**: Scan for security vulnerabilities
- **Checks**: Hardcoded credentials, sensitive data exposure, input validation, SQL injection

#### **localization-enforcer.kiro.hook**
- **Trigger**: When presentation layer files are edited
- **Purpose**: Detect hardcoded UI strings
- **Checks**: Text widgets, error messages, enforce context.l10n usage

### 6. Code Generation & Testing

#### **code-generation-reminder.kiro.hook**
- **Trigger**: When models/entities/blocs are edited
- **Purpose**: Remind to run build_runner
- **Checks**: @freezed, @JsonSerializable, @collection, @injectable annotations

#### **test-coverage-reminder.kiro.hook**
- **Trigger**: When business logic files are edited
- **Purpose**: Remind to update tests
- **Checks**: Corresponding test files, test coverage, suggest test cases

### 7. Documentation

#### **documentation-updater.kiro.hook**
- **Trigger**: When public APIs are edited
- **Purpose**: Remind to update documentation
- **Checks**: Doc comments, API documentation, README updates, CHANGELOG

### 8. Pre-Commit

#### **pre-commit-validation.kiro.hook** 🚀 MANUAL
- **Trigger**: User-triggered (manual button)
- **Purpose**: Comprehensive pre-commit checklist
- **Runs**: Flutter analyze, tests, code quality checks, architecture validation

## 🎮 Usage

### Automatic Hooks
Most hooks run automatically when you edit matching files. They will:
1. Analyze your changes
2. Provide feedback in chat
3. Suggest improvements
4. Show code examples

### Manual Hooks
Some hooks need to be triggered manually:

**Pre-Commit Validation:**
1. Open Command Palette
2. Search for "Kiro: Run Hook"
3. Select "Pre-Commit Validation"
4. Review the comprehensive checklist

## 🔧 Configuration

### Enable/Disable Hooks
Edit the hook file and change:
```json
{
  "enabled": true  // Set to false to disable
}
```

### Modify Patterns
Adjust file patterns to match your needs:
```json
{
  "when": {
    "type": "fileEdited",
    "patterns": [
      "flutter_chat_app/lib/**/*.dart",  // Add or remove patterns
      "src/**/*.ts"
    ]
  }
}
```

### Customize Prompts
Edit the `then.prompt` field to adjust what the hook checks for.

## 📊 Hook Priority

**Critical (Always Run):**
1. domain-layer-guard.kiro.hook
2. security-checker.kiro.hook
3. bloc-pattern-validator.kiro.hook

**High Priority:**
1. flutter-code-review.kiro.hook
2. nestjs-code-review.kiro.hook
3. repository-pattern-validator.kiro.hook
4. offline-first-validator.kiro.hook

**Medium Priority:**
1. localization-enforcer.kiro.hook
2. dependency-injection-validator.kiro.hook
3. import-organizer.kiro.hook
4. performance-analyzer.kiro.hook

**Low Priority (Informational):**
1. code-generation-reminder.kiro.hook
2. test-coverage-reminder.kiro.hook
3. documentation-updater.kiro.hook
4. file-size-monitor.kiro.hook

## 🎯 Best Practices

### For Developers

1. **Run Pre-Commit Validation** before every commit
2. **Pay attention to Critical hooks** (domain-layer-guard, security-checker)
3. **Address warnings** from High Priority hooks
4. **Review suggestions** from Medium/Low Priority hooks

### For Team Leads

1. **Enforce Critical hooks** - these catch architecture violations
2. **Review hook feedback** in code reviews
3. **Customize hooks** for team-specific patterns
4. **Add new hooks** for recurring issues

### For New Team Members

1. **Read hook feedback** - it teaches best practices
2. **Ask questions** if hook suggestions are unclear
3. **Learn patterns** from hook examples
4. **Use Pre-Commit Validation** to learn the checklist

## 🔄 Maintenance

### Adding New Hooks

1. Create new `.kiro.hook` file
2. Follow the JSON schema
3. Test with sample files
4. Document in this README

### Updating Hooks

1. Edit the hook file
2. Test changes
3. Update documentation
4. Notify team of changes

### Removing Hooks

1. Set `"enabled": false` first (test period)
2. If no issues, delete the file
3. Update this README

## 📚 Resources

- [Kiro Hooks Guide](./../HOOKS_GUIDE.md)
- [Project Architecture](./../steering/project-architecture.md)
- [Flutter Best Practices](./../steering/flutter-best-practices.md)
- [NestJS Patterns](./../steering/backend-nestjs-patterns.md)

## 🤝 Contributing

When adding new hooks:
1. Follow existing patterns
2. Provide clear, actionable feedback
3. Include code examples
4. Test thoroughly
5. Document in this README

## 📝 Notes

- Hooks run in Kiro's context, not in your terminal
- Hook feedback appears in the chat
- Hooks don't block your work - they provide guidance
- You can disable hooks temporarily if needed
- Hooks learn from your project's patterns

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-27  
**Maintainer**: Senior Flutter/Mobile Architect  
**Total Hooks**: 18

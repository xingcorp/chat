# 📋 Complete Hooks List

## ✅ Active Hooks (20)

### 🔴 CRITICAL Priority (3)

1. **domain-layer-guard.kiro.hook**
   - Enforces domain layer purity
   - Prevents Flutter/infrastructure imports
   - Triggers: `flutter_chat_app/lib/domain/**/*.dart`

2. **security-checker.kiro.hook**
   - Scans for security vulnerabilities
   - Detects hardcoded credentials
   - Triggers: `**/*.dart`, `**/*.ts`

3. **error-handling-validator.kiro.hook**
   - Validates Either<Failure, T> pattern
   - Ensures proper error handling
   - Triggers: repositories, usecases, blocs

### 🟡 HIGH Priority (7)

4. **bloc-pattern-validator.kiro.hook**
   - Validates BLoC with Freezed
   - Checks event/state design
   - Triggers: `flutter_chat_app/lib/presentation/bloc/**/*.dart`

5. **repository-pattern-validator.kiro.hook**
   - Validates repository implementation
   - Checks offline-first patterns
   - Triggers: `flutter_chat_app/lib/data/repositories/**/*.dart`

6. **flutter-code-review.kiro.hook**
   - Reviews Flutter code quality
   - Checks architecture compliance
   - Triggers: `flutter_chat_app/lib/**/*.dart`

7. **nestjs-code-review.kiro.hook**
   - Reviews NestJS code quality
   - Checks module organization
   - Triggers: `src/**/*.ts`

8. **offline-first-validator.kiro.hook**
   - Validates offline-first patterns
   - Checks cache strategy
   - Triggers: repositories, sync services

9. **realtime-pattern-validator.kiro.hook**
   - Validates Socket.IO patterns
   - Checks connection management
   - Triggers: socket managers, gateways

10. **performance-targets-validator.kiro.hook**
    - Validates performance targets
    - Checks startup, memory, fps
    - Triggers: main, initialization, pages

11. **pre-commit-validation.kiro.hook** (MANUAL)
    - Comprehensive pre-commit checklist
    - Runs all validations
    - Trigger: User-triggered

### 🟢 MEDIUM Priority (6)

12. **localization-enforcer.kiro.hook**
    - Enforces localization usage
    - Detects hardcoded strings
    - Triggers: `flutter_chat_app/lib/presentation/**/*.dart`

13. **dependency-injection-validator.kiro.hook**
    - Validates DI patterns
    - Checks @injectable usage
    - Triggers: repositories, services, blocs

14. **import-organizer.kiro.hook**
    - Organizes imports
    - Enforces package imports
    - Triggers: `**/*.dart`, `**/*.ts`

15. **performance-analyzer.kiro.hook**
    - Analyzes performance issues
    - Checks widget optimization
    - Triggers: widgets, pages, screens

16. **graphql-pattern-validator.kiro.hook**
    - Validates GraphQL patterns
    - Checks resolvers, types
    - Triggers: `src/models/resolvers/**/*.ts`

17. **file-size-monitor.kiro.hook**
    - Monitors file size
    - Warns at >400 lines
    - Triggers: `**/*.dart`, `**/*.ts`

### 🔵 INFO Priority (4)

18. **code-generation-reminder.kiro.hook**
    - Reminds to run build_runner
    - Detects @freezed, @JsonSerializable
    - Triggers: models, entities, blocs

19. **test-coverage-reminder.kiro.hook**
    - Reminds to update tests
    - Suggests test cases
    - Triggers: usecases, repositories, blocs

20. **documentation-updater.kiro.hook**
    - Reminds to update docs
    - Checks doc comments
    - Triggers: public APIs

## ❌ Disabled/Deprecated Hooks (5)

21. **demo-hook.kiro.hook** (Disabled)
    - Demo hook for testing
    - Replaced by specific hooks

22. **flutter-analyze-on-save.kiro.hook** (Old Format)
    - Old format hook
    - Use flutter-code-review instead

23. **pre-commit-checklist.kiro.hook** (Old Format)
    - Old format hook
    - Use pre-commit-validation instead

24. **auto-update-tests.kiro.hook** (Old Format)
    - Old format hook
    - Use test-coverage-reminder instead

25. **clean-architecture-validator.kiro.hook** (Old Format)
    - Old format hook
    - Use domain-layer-guard instead

## 📊 Summary

```
Total Hooks:          25
Active Hooks:         20
Disabled Hooks:       1
Deprecated Hooks:     4

By Priority:
  🔴 CRITICAL:        3
  🟡 HIGH:            7
  🟢 MEDIUM:          6
  🔵 INFO:            4

By Technology:
  Flutter Only:       8
  NestJS Only:        2
  Both:              10

By Trigger:
  Automatic:         19
  Manual:             1
```

## 🎯 Quick Reference

### Most Important Hooks (Top 5)
1. domain-layer-guard (CRITICAL)
2. security-checker (CRITICAL)
3. error-handling-validator (CRITICAL)
4. bloc-pattern-validator (HIGH)
5. repository-pattern-validator (HIGH)

### Most Frequently Triggered
1. flutter-code-review
2. import-organizer
3. localization-enforcer
4. file-size-monitor
5. code-generation-reminder

### Best for Learning
1. flutter-code-review
2. bloc-pattern-validator
3. repository-pattern-validator
4. error-handling-validator
5. offline-first-validator

## 📁 File Organization

```
.kiro/hooks/
├── Documentation/
│   ├── INDEX.md                          # This index
│   ├── README.md                         # Complete guide
│   ├── HOOKS_OVERVIEW.md                 # Visual overview
│   ├── SETUP_COMPLETE.md                 # Setup guide
│   ├── INSTALLATION_SUMMARY.md           # Installation summary
│   └── HOOKS_LIST.md                     # This file
│
├── Architecture/ (6 hooks)
│   ├── domain-layer-guard.kiro.hook
│   ├── bloc-pattern-validator.kiro.hook
│   ├── repository-pattern-validator.kiro.hook
│   ├── graphql-pattern-validator.kiro.hook
│   ├── offline-first-validator.kiro.hook
│   └── realtime-pattern-validator.kiro.hook
│
├── Code Quality/ (6 hooks)
│   ├── flutter-code-review.kiro.hook
│   ├── nestjs-code-review.kiro.hook
│   ├── import-organizer.kiro.hook
│   ├── file-size-monitor.kiro.hook
│   ├── error-handling-validator.kiro.hook
│   └── performance-targets-validator.kiro.hook
│
├── Security/ (3 hooks)
│   ├── security-checker.kiro.hook
│   ├── localization-enforcer.kiro.hook
│   └── dependency-injection-validator.kiro.hook
│
├── Testing & Docs/ (3 hooks)
│   ├── test-coverage-reminder.kiro.hook
│   ├── documentation-updater.kiro.hook
│   └── code-generation-reminder.kiro.hook
│
├── Utilities/ (2 hooks)
│   ├── pre-commit-validation.kiro.hook
│   └── performance-analyzer.kiro.hook
│
└── Deprecated/ (5 hooks)
    ├── demo-hook.kiro.hook
    ├── flutter-analyze-on-save.kiro.hook
    ├── pre-commit-checklist.kiro.hook
    ├── auto-update-tests.kiro.hook
    └── clean-architecture-validator.kiro.hook
```

## 🚀 Usage

### View All Hooks
```bash
ls -la .kiro/hooks/*.hook
```

### Count Active Hooks
```bash
grep -l '"enabled": true' .kiro/hooks/*.hook | wc -l
```

### Find Hooks by Pattern
```bash
grep -l 'flutter_chat_app/lib/domain' .kiro/hooks/*.hook
```

### Check Hook Status
```bash
grep '"enabled"' .kiro/hooks/*.hook
```

## 📖 Documentation

- **[INDEX.md](./INDEX.md)** - Complete index with search
- **[README.md](./README.md)** - Full documentation
- **[HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md)** - Visual diagrams
- **[SETUP_COMPLETE.md](./SETUP_COMPLETE.md)** - Setup guide
- **[INSTALLATION_SUMMARY.md](./INSTALLATION_SUMMARY.md)** - Summary

---

**Last Updated**: 2025-01-27  
**Version**: 1.0.0  
**Total Hooks**: 25 (20 active, 5 deprecated)

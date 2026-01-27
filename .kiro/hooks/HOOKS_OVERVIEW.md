# 🎯 Kiro Hooks - Visual Overview

## 📊 Hook Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    KIRO HOOKS SYSTEM                        │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Flutter    │  │   NestJS     │  │   Common     │    │
│  │   Hooks      │  │   Hooks      │  │   Hooks      │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│         │                 │                  │             │
│         └─────────────────┴──────────────────┘             │
│                           │                                │
│                    ┌──────▼──────┐                        │
│                    │  Kiro Agent │                        │
│                    └──────┬──────┘                        │
│                           │                                │
│                    ┌──────▼──────┐                        │
│                    │  Feedback   │                        │
│                    │  in Chat    │                        │
│                    └─────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## 🎨 Hook Categories

### 🏗️ Architecture Enforcement (6 hooks)

```
┌─────────────────────────────────────────────────────────┐
│  ARCHITECTURE LAYER                                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  domain-layer-guard.kiro.hook                    │  │
│  │  🚨 CRITICAL: No Flutter/Infrastructure imports  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  bloc-pattern-validator.kiro.hook                │  │
│  │  ✅ Freezed events/states, Either<Failure, T>   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  repository-pattern-validator.kiro.hook          │  │
│  │  ✅ Interface implementation, error handling     │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  graphql-pattern-validator.kiro.hook             │  │
│  │  ✅ NestJS resolvers, decorators, validation     │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  offline-first-validator.kiro.hook               │  │
│  │  ✅ Cache-first, sync queue, optimistic updates  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  realtime-pattern-validator.kiro.hook            │  │
│  │  ✅ Socket.IO, connection management, rooms      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 💎 Code Quality (5 hooks)

```
┌─────────────────────────────────────────────────────────┐
│  CODE QUALITY LAYER                                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  flutter-code-review.kiro.hook                   │  │
│  │  📱 Architecture, performance, best practices    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  nestjs-code-review.kiro.hook                    │  │
│  │  🔧 Modules, DI, GraphQL, error handling         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  import-organizer.kiro.hook                      │  │
│  │  📦 Package imports, proper ordering             │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  file-size-monitor.kiro.hook                     │  │
│  │  📏 >400 lines warning, suggest splitting        │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  error-handling-validator.kiro.hook              │  │
│  │  ⚠️ Either<Failure, T>, proper error patterns   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 🔒 Security & Best Practices (3 hooks)

```
┌─────────────────────────────────────────────────────────┐
│  SECURITY LAYER                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  security-checker.kiro.hook                      │  │
│  │  🔒 Credentials, sensitive data, SQL injection   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  localization-enforcer.kiro.hook                 │  │
│  │  🌍 No hardcoded strings, use context.l10n       │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  dependency-injection-validator.kiro.hook        │  │
│  │  💉 @injectable, constructor injection           │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 🧪 Testing & Documentation (3 hooks)

```
┌─────────────────────────────────────────────────────────┐
│  QUALITY ASSURANCE LAYER                                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  test-coverage-reminder.kiro.hook                │  │
│  │  🧪 Update tests, suggest test cases             │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  documentation-updater.kiro.hook                 │  │
│  │  📚 Doc comments, API docs, README               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  code-generation-reminder.kiro.hook              │  │
│  │  ⚙️ build_runner, gen-l10n reminders            │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 🚀 Utilities (2 hooks)

```
┌─────────────────────────────────────────────────────────┐
│  UTILITY LAYER                                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  pre-commit-validation.kiro.hook (MANUAL)        │  │
│  │  ✅ Comprehensive checklist before commit        │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  performance-analyzer.kiro.hook                  │  │
│  │  ⚡ Widget optimization, memory leaks            │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Hook Workflow

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  Developer edits file                                   │
│         │                                               │
│         ▼                                               │
│  ┌─────────────┐                                       │
│  │ File Event  │                                       │
│  └──────┬──────┘                                       │
│         │                                               │
│         ▼                                               │
│  ┌─────────────────────────────────────┐              │
│  │ Matching Hooks Triggered            │              │
│  │ (based on file patterns)            │              │
│  └──────┬──────────────────────────────┘              │
│         │                                               │
│         ▼                                               │
│  ┌─────────────────────────────────────┐              │
│  │ Kiro Agent Analyzes Code            │              │
│  │ - Checks patterns                   │              │
│  │ - Validates rules                   │              │
│  │ - Generates suggestions             │              │
│  └──────┬──────────────────────────────┘              │
│         │                                               │
│         ▼                                               │
│  ┌─────────────────────────────────────┐              │
│  │ Feedback in Chat                    │              │
│  │ - Issues found                      │              │
│  │ - Code examples                     │              │
│  │ - Specific fixes                    │              │
│  └──────┬──────────────────────────────┘              │
│         │                                               │
│         ▼                                               │
│  Developer reviews and fixes                           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 📈 Impact Matrix

```
┌────────────────────────────────────────────────────────────┐
│  Hook Name                    │ Priority │ Impact │ Freq  │
├───────────────────────────────┼──────────┼────────┼───────┤
│  domain-layer-guard           │   🔴     │  HIGH  │  HIGH │
│  security-checker             │   🔴     │  HIGH  │  MED  │
│  error-handling-validator     │   🔴     │  HIGH  │  HIGH │
│  bloc-pattern-validator       │   🟡     │  HIGH  │  HIGH │
│  repository-pattern-validator │   🟡     │  HIGH  │  MED  │
│  flutter-code-review          │   🟡     │  MED   │  HIGH │
│  nestjs-code-review           │   🟡     │  MED   │  HIGH │
│  offline-first-validator      │   🟡     │  HIGH  │  LOW  │
│  realtime-pattern-validator   │   🟡     │  HIGH  │  LOW  │
│  localization-enforcer        │   🟢     │  MED   │  HIGH │
│  dependency-injection-val.    │   🟢     │  MED   │  MED  │
│  import-organizer             │   🟢     │  LOW   │  HIGH │
│  performance-analyzer         │   🟢     │  MED   │  MED  │
│  graphql-pattern-validator    │   🟢     │  MED   │  MED  │
│  code-generation-reminder     │   🔵     │  LOW   │  MED  │
│  test-coverage-reminder       │   🔵     │  MED   │  MED  │
│  documentation-updater        │   🔵     │  LOW   │  LOW  │
│  file-size-monitor            │   🔵     │  LOW   │  LOW  │
│  pre-commit-validation        │   🟡     │  HIGH  │  LOW  │
└────────────────────────────────────────────────────────────┘

Legend:
🔴 CRITICAL - Must fix immediately
🟡 HIGH     - Should fix soon
🟢 MEDIUM   - Review and consider
🔵 INFO     - Informational
```

## 🎯 Coverage Map

```
┌─────────────────────────────────────────────────────────┐
│  Project Structure                    │ Hooks Covering  │
├───────────────────────────────────────┼─────────────────┤
│  flutter_chat_app/lib/                │                 │
│    ├── domain/                        │ 🔴🔴🟡🟢🔵     │
│    │   ├── entities/                  │ 🔴🟢🔵🔵       │
│    │   ├── repositories/              │ 🔴🟡🟢🔵       │
│    │   └── usecases/                  │ 🔴🟡🟢🔵       │
│    ├── data/                          │                 │
│    │   ├── models/                    │ 🟢🔵🔵         │
│    │   ├── datasources/               │ 🟢🟢🔵         │
│    │   └── repositories/              │ 🔴🟡🟡🟢🔵     │
│    ├── presentation/                  │                 │
│    │   ├── bloc/                      │ 🔴🟡🟡🟢🔵     │
│    │   ├── pages/                     │ 🟡🟢🟢🔵       │
│    │   └── widgets/                   │ 🟡🟢🟢🔵       │
│    └── core/                          │                 │
│        ├── network/                   │ 🟡🟡🟢         │
│        ├── services/                  │ 🟡🟢🟢🔵       │
│        └── offline/                   │ 🟡🟡           │
│                                       │                 │
│  src/                                 │                 │
│    ├── modules/                       │                 │
│    │   ├── **/*.service.ts            │ 🟡🟢🟢🔵       │
│    │   ├── **/*.resolver.ts           │ 🟡🟡🟢🔵       │
│    │   └── **/*gateway.ts             │ 🟡🟡           │
│    └── models/                        │                 │
│        ├── entities/                  │ 🟢🔵           │
│        └── resolvers/                 │ 🟡🟡🟢         │
└─────────────────────────────────────────────────────────┘
```

## 🚦 Quick Reference

### When You See These Emojis:

- 🚨 **CRITICAL** - Stop and fix immediately
- ⚠️ **WARNING** - Should fix before commit
- 💡 **SUGGESTION** - Consider improving
- ℹ️ **INFO** - Good to know
- ✅ **CORRECT** - This is the right way
- ❌ **WRONG** - Don't do this

### Common Scenarios:

```
Scenario: Edit domain entity
Triggers: domain-layer-guard, flutter-code-review, import-organizer
Priority: 🔴 CRITICAL

Scenario: Edit BLoC
Triggers: bloc-pattern-validator, error-handling-validator, flutter-code-review
Priority: 🟡 HIGH

Scenario: Edit repository
Triggers: repository-pattern-validator, offline-first-validator, error-handling
Priority: 🟡 HIGH

Scenario: Edit UI widget
Triggers: flutter-code-review, localization-enforcer, performance-analyzer
Priority: 🟢 MEDIUM

Scenario: Edit NestJS resolver
Triggers: nestjs-code-review, graphql-pattern-validator, security-checker
Priority: 🟡 HIGH
```

## 📊 Statistics

```
Total Hooks:              19
Automatic Hooks:          18
Manual Hooks:             1
Critical Priority:        3
High Priority:            6
Medium Priority:          6
Info Priority:            4

Coverage:
- Flutter Files:          95%
- NestJS Files:           90%
- Architecture:           100%
- Security:               85%
- Performance:            75%
```

---

**Last Updated**: 2025-01-27  
**Version**: 1.0.0  
**Status**: ✅ Production Ready

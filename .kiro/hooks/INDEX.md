# 📑 Kiro Hooks - Complete Index

## 📚 Documentation Files

### Getting Started
- **[INSTALLATION_SUMMARY.md](./INSTALLATION_SUMMARY.md)** - Start here! Installation summary and quick start
- **[SETUP_COMPLETE.md](./SETUP_COMPLETE.md)** - Setup completion guide with benefits
- **[README.md](./README.md)** - Complete hooks guide and reference
- **[HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md)** - Visual overview with diagrams

## 🎯 Hook Files by Category

### 🏗️ Architecture & Patterns

| Hook | File | Priority | Description |
|------|------|----------|-------------|
| Domain Layer Guard | [domain-layer-guard.kiro.hook](./domain-layer-guard.kiro.hook) | 🔴 CRITICAL | Enforce domain layer purity |
| BLoC Pattern Validator | [bloc-pattern-validator.kiro.hook](./bloc-pattern-validator.kiro.hook) | 🟡 HIGH | Validate BLoC with Freezed |
| Repository Pattern | [repository-pattern-validator.kiro.hook](./repository-pattern-validator.kiro.hook) | 🟡 HIGH | Validate repository patterns |
| GraphQL Pattern | [graphql-pattern-validator.kiro.hook](./graphql-pattern-validator.kiro.hook) | 🟢 MEDIUM | Validate NestJS GraphQL |
| Offline-First | [offline-first-validator.kiro.hook](./offline-first-validator.kiro.hook) | 🟡 HIGH | Validate offline-first patterns |
| Realtime Pattern | [realtime-pattern-validator.kiro.hook](./realtime-pattern-validator.kiro.hook) | 🟡 HIGH | Validate Socket.IO patterns |

### 💎 Code Quality

| Hook | File | Priority | Description |
|------|------|----------|-------------|
| Flutter Code Review | [flutter-code-review.kiro.hook](./flutter-code-review.kiro.hook) | 🟡 HIGH | Review Flutter code |
| NestJS Code Review | [nestjs-code-review.kiro.hook](./nestjs-code-review.kiro.hook) | 🟡 HIGH | Review NestJS code |
| Import Organizer | [import-organizer.kiro.hook](./import-organizer.kiro.hook) | 🟢 MEDIUM | Organize imports |
| File Size Monitor | [file-size-monitor.kiro.hook](./file-size-monitor.kiro.hook) | 🔵 INFO | Monitor file size |
| Error Handling | [error-handling-validator.kiro.hook](./error-handling-validator.kiro.hook) | 🔴 CRITICAL | Validate Either<Failure, T> |
| Performance Targets | [performance-targets-validator.kiro.hook](./performance-targets-validator.kiro.hook) | 🟡 HIGH | Validate performance targets |

### 🔒 Security & Best Practices

| Hook | File | Priority | Description |
|------|------|----------|-------------|
| Security Checker | [security-checker.kiro.hook](./security-checker.kiro.hook) | 🔴 CRITICAL | Security vulnerability scanner |
| Localization Enforcer | [localization-enforcer.kiro.hook](./localization-enforcer.kiro.hook) | 🟢 MEDIUM | Enforce i18n |
| DI Validator | [dependency-injection-validator.kiro.hook](./dependency-injection-validator.kiro.hook) | 🟢 MEDIUM | Validate DI patterns |

### 🧪 Testing & Documentation

| Hook | File | Priority | Description |
|------|------|----------|-------------|
| Test Coverage | [test-coverage-reminder.kiro.hook](./test-coverage-reminder.kiro.hook) | 🔵 INFO | Test coverage reminder |
| Documentation | [documentation-updater.kiro.hook](./documentation-updater.kiro.hook) | 🔵 INFO | Documentation reminder |
| Code Generation | [code-generation-reminder.kiro.hook](./code-generation-reminder.kiro.hook) | 🔵 INFO | build_runner reminder |

### 🚀 Utilities

| Hook | File | Priority | Description |
|------|------|----------|-------------|
| Pre-Commit | [pre-commit-validation.kiro.hook](./pre-commit-validation.kiro.hook) | 🟡 HIGH | Pre-commit checklist (MANUAL) |
| Performance Analyzer | [performance-analyzer.kiro.hook](./performance-analyzer.kiro.hook) | 🟢 MEDIUM | Performance analysis |

### 🗑️ Deprecated/Disabled

| Hook | File | Status | Reason |
|------|------|--------|--------|
| Demo Hook | [demo-hook.kiro.hook](./demo-hook.kiro.hook) | ❌ Disabled | Replaced by specific hooks |
| Flutter Analyze | [flutter-analyze-on-save.kiro.hook](./flutter-analyze-on-save.kiro.hook) | ⚠️ Old Format | Use flutter-code-review |
| Pre-Commit Checklist | [pre-commit-checklist.kiro.hook](./pre-commit-checklist.kiro.hook) | ⚠️ Old Format | Use pre-commit-validation |
| Auto Update Tests | [auto-update-tests.kiro.hook](./auto-update-tests.kiro.hook) | ⚠️ Old Format | Use test-coverage-reminder |
| Clean Arch Validator | [clean-architecture-validator.kiro.hook](./clean-architecture-validator.kiro.hook) | ⚠️ Old Format | Use domain-layer-guard |

## 🔍 Quick Search

### By File Pattern

**Flutter Domain Layer** (`flutter_chat_app/lib/domain/**/*.dart`)
- domain-layer-guard
- flutter-code-review
- import-organizer
- code-generation-reminder
- documentation-updater

**Flutter Data Layer** (`flutter_chat_app/lib/data/**/*.dart`)
- repository-pattern-validator
- offline-first-validator
- error-handling-validator
- flutter-code-review
- test-coverage-reminder

**Flutter Presentation** (`flutter_chat_app/lib/presentation/**/*.dart`)
- bloc-pattern-validator
- flutter-code-review
- localization-enforcer
- performance-analyzer
- file-size-monitor

**NestJS Services** (`src/modules/**/*.service.ts`)
- nestjs-code-review
- dependency-injection-validator
- test-coverage-reminder
- documentation-updater

**NestJS Resolvers** (`src/modules/**/*.resolver.ts`)
- graphql-pattern-validator
- nestjs-code-review
- security-checker

### By Priority

**🔴 CRITICAL (Must Fix)**
1. domain-layer-guard
2. security-checker
3. error-handling-validator

**🟡 HIGH (Should Fix)**
1. bloc-pattern-validator
2. repository-pattern-validator
3. flutter-code-review
4. nestjs-code-review
5. offline-first-validator
6. realtime-pattern-validator
7. performance-targets-validator
8. pre-commit-validation

**🟢 MEDIUM (Review)**
1. localization-enforcer
2. dependency-injection-validator
3. import-organizer
4. performance-analyzer
5. graphql-pattern-validator

**🔵 INFO (Informational)**
1. code-generation-reminder
2. test-coverage-reminder
3. documentation-updater
4. file-size-monitor

### By Technology

**Flutter Only**
- flutter-code-review
- bloc-pattern-validator
- localization-enforcer
- performance-analyzer
- performance-targets-validator

**NestJS Only**
- nestjs-code-review
- graphql-pattern-validator

**Both Flutter & NestJS**
- domain-layer-guard (Flutter only but concept applies)
- repository-pattern-validator
- error-handling-validator
- security-checker
- dependency-injection-validator
- import-organizer
- test-coverage-reminder
- documentation-updater

**Offline/Realtime Features**
- offline-first-validator
- realtime-pattern-validator

## 📖 Usage Guides

### For New Developers
1. Start with [INSTALLATION_SUMMARY.md](./INSTALLATION_SUMMARY.md)
2. Read [SETUP_COMPLETE.md](./SETUP_COMPLETE.md)
3. Review [HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md)
4. Reference [README.md](./README.md) as needed

### For Experienced Developers
1. Quick reference: [HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md)
2. Detailed patterns: [README.md](./README.md)
3. Specific hooks: Individual .kiro.hook files

### For Team Leads
1. Overview: [HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md)
2. Metrics: [INSTALLATION_SUMMARY.md](./INSTALLATION_SUMMARY.md)
3. Customization: [README.md](./README.md)

## 🎯 Common Tasks

### "I want to understand what hooks do"
→ Read [HOOKS_OVERVIEW.md](./HOOKS_OVERVIEW.md)

### "I want to know how to use hooks"
→ Read [SETUP_COMPLETE.md](./SETUP_COMPLETE.md)

### "I want detailed documentation"
→ Read [README.md](./README.md)

### "I want to see installation summary"
→ Read [INSTALLATION_SUMMARY.md](./INSTALLATION_SUMMARY.md)

### "I want to customize a hook"
→ Open the specific .kiro.hook file

### "I want to disable a hook"
→ Set `"enabled": false` in hook file

### "I want to add a new hook"
→ Follow patterns in existing hooks

## 📊 Statistics

```
Total Hooks:              20
Active Hooks:             20
Disabled Hooks:           1
Documentation Files:      5
Total Lines of Code:      ~6000+
Coverage:                 >90%
```

## 🔗 External Resources

- [Kiro Documentation](../)
- [Project Architecture](../steering/project-architecture.md)
- [Flutter Best Practices](../steering/flutter-best-practices.md)
- [NestJS Patterns](../steering/backend-nestjs-patterns.md)
- [Kiro Hooks Guide](../HOOKS_GUIDE.md)

## 🆘 Troubleshooting

### Hook not running?
1. Check `"enabled": true`
2. Verify file pattern matches
3. Restart Kiro if needed

### Too many notifications?
1. Disable low-priority hooks
2. Adjust file patterns
3. Focus on CRITICAL/HIGH first

### Hook feedback unclear?
1. Ask Kiro to explain
2. Check hook documentation
3. Review code examples

### Want to customize?
1. Edit hook file
2. Modify patterns or prompt
3. Test with sample files

## 📝 Notes

- All hooks use new format (version 1)
- Old format hooks are marked as deprecated
- Hooks are organized by category
- Priority indicates importance
- Coverage indicates which files are monitored

---

**Last Updated**: 2025-01-27  
**Version**: 1.0.0  
**Total Hooks**: 20  
**Status**: ✅ Production Ready

---

**Quick Links:**
- [Installation Summary](./INSTALLATION_SUMMARY.md)
- [Setup Complete](./SETUP_COMPLETE.md)
- [Complete Guide](./README.md)
- [Visual Overview](./HOOKS_OVERVIEW.md)

# Kiro AI Configuration

This directory contains steering files, hooks, and rules to help Kiro AI understand and work with this project effectively.

## 📁 Directory Structure

```
.kiro/
├── steering/                    # Steering files (always loaded or conditional)
│   ├── project-architecture.md  # Main architecture guide (ALWAYS loaded)
│   ├── flutter-best-practices.md # Flutter-specific patterns (conditional)
│   ├── backend-nestjs-patterns.md # NestJS-specific patterns (conditional)
│   ├── chat-api-integration.md  # Chat API integration guide (conditional)
│   ├── chat-feature-implementation.md # Chat implementation guide (conditional)
│   └── chat-offline-realtime.md # Offline & real-time features (conditional)
├── hooks/                       # Agent hooks (.kiro.hook files)
│   └── (created via Kiro UI)
├── HOOKS_GUIDE.md              # Complete hooks documentation
└── README.md                    # This file
```

## 🎯 Steering Files

Steering files provide context and guidelines to Kiro AI about the project architecture, patterns, and best practices.

### Main Steering File
**`project-architecture.md`** (Always Active)
- Project structure overview
- Clean Architecture principles
- BLoC pattern guidelines
- Error handling with Either<Failure, T>
- Repository pattern
- Code style conventions
- Common tasks workflows
- Critical rules and warnings
- Testing patterns
- Checklists

### Conditional Steering Files

#### General Flutter/Backend
**`flutter-best-practices.md`** (Active when editing Flutter files)
- Performance optimization
- Widget best practices
- Async & Isolates
- Navigation patterns
- Responsive design
- Accessibility
- Security
- Common pitfalls

**`backend-nestjs-patterns.md`** (Active when editing NestJS files)
- Module structure
- GraphQL patterns
- Database patterns
- Error handling
- Caching strategies
- Background jobs
- Security (Guards)
- Testing

#### Chat Feature Specific
**`chat-api-integration.md`** (Active when editing chat-related files)
- Backend API endpoints (GraphQL + Socket.IO)
- Data models (Message, Conversation, Reaction)
- GraphQL operations with examples
- Socket.IO events and handlers
- API integration patterns
- Implementation checklist

**`chat-feature-implementation.md`** (Active when editing chat/message/conversation files)
- Complete directory structure
- Domain layer (entities, repositories, use cases)
- Data layer (models, data sources)
- Presentation layer (BLoCs, pages, widgets)
- Step-by-step implementation guide
- Code examples for each layer

**`chat-offline-realtime.md`** (Active when editing offline/sync/socket files)
- Offline-first architecture
- Sync queue implementation
- Real-time message handling
- Socket.IO integration
- Typing indicators
- Optimistic UI updates
- Conflict resolution

## 🪝 Agent Hooks (20 Active Hooks)

**✅ COMPLETE SETUP** - 20 professional hooks installed and ready to use!

> **📖 Complete Documentation**: See [hooks/](./hooks/) directory for full documentation

### Quick Links
- **[hooks/INSTALLATION_SUMMARY.md](./hooks/INSTALLATION_SUMMARY.md)** - Start here!
- **[hooks/INDEX.md](./hooks/INDEX.md)** - Complete index
- **[hooks/HOOKS_OVERVIEW.md](./hooks/HOOKS_OVERVIEW.md)** - Visual overview
- **[hooks/README.md](./hooks/README.md)** - Full documentation
- **[hooks/HOOKS_LIST.md](./hooks/HOOKS_LIST.md)** - Complete list

### What's Installed

#### 🏗️ Architecture & Patterns (6 hooks)
1. 🔴 **domain-layer-guard** - Enforce domain layer purity (CRITICAL)
2. 🟡 **bloc-pattern-validator** - Validate BLoC with Freezed
3. 🟡 **repository-pattern-validator** - Validate repository patterns
4. 🟢 **graphql-pattern-validator** - Validate NestJS GraphQL
5. 🟡 **offline-first-validator** - Validate offline-first patterns
6. 🟡 **realtime-pattern-validator** - Validate Socket.IO patterns

#### 💎 Code Quality (6 hooks)
7. 🟡 **flutter-code-review** - Review Flutter code
8. 🟡 **nestjs-code-review** - Review NestJS code
9. 🟢 **import-organizer** - Organize imports
10. 🔵 **file-size-monitor** - Monitor file size (>400 lines)
11. 🔴 **error-handling-validator** - Validate Either<Failure, T> (CRITICAL)
12. 🟡 **performance-targets-validator** - Validate performance targets

#### 🔒 Security & Best Practices (3 hooks)
13. 🔴 **security-checker** - Security vulnerability scanner (CRITICAL)
14. 🟢 **localization-enforcer** - Enforce i18n
15. 🟢 **dependency-injection-validator** - Validate DI patterns

#### 🧪 Testing & Documentation (3 hooks)
16. 🔵 **test-coverage-reminder** - Test coverage reminder
17. 🔵 **documentation-updater** - Documentation reminder
18. 🔵 **code-generation-reminder** - build_runner reminder

#### 🚀 Utilities (2 hooks)
19. 🟡 **pre-commit-validation** - Pre-commit checklist (MANUAL)
20. 🟢 **performance-analyzer** - Performance analysis

**Legend**: 🔴 CRITICAL | 🟡 HIGH | 🟢 MEDIUM | 🔵 INFO

### How Hooks Work

Hooks automatically analyze your code changes and provide:
- ✅ Real-time feedback in chat
- 📝 Code examples
- 🎯 Specific fixes
- 📖 Pattern documentation
- 💡 Best practices

### Quick Start

1. **Edit any file** - Hooks run automatically
2. **Review feedback** - Check Kiro's suggestions in chat
3. **Fix issues** - Follow the provided examples
4. **Learn patterns** - Understand why and how

### Manual Hooks

**Pre-Commit Validation:**
1. Open Command Palette (Cmd/Ctrl + Shift + P)
2. Search "Kiro: Run Hook"
3. Select "Pre-Commit Validation"
4. Review comprehensive checklist

### Hook Files

All hooks are in `.kiro/hooks/` directory:
```
.kiro/hooks/
├── Documentation/
│   ├── INDEX.md                          # Complete index
│   ├── README.md                         # Full documentation
│   ├── HOOKS_OVERVIEW.md                 # Visual overview
│   ├── SETUP_COMPLETE.md                 # Setup guide
│   ├── INSTALLATION_SUMMARY.md           # Installation summary
│   └── HOOKS_LIST.md                     # Complete list
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
└── Utilities/ (2 hooks)
    ├── pre-commit-validation.kiro.hook
    └── performance-analyzer.kiro.hook
```

**Team Collaboration**: All hooks are committed to version control and shared with the team!

## 🚀 How to Use

### For Kiro AI
When you ask Kiro AI to help with code:
1. Kiro automatically loads `project-architecture.md` for context
2. If you're working on Flutter files, `flutter-best-practices.md` is loaded
3. If you're working on NestJS files, `backend-nestjs-patterns.md` is loaded
4. If you're working on chat features, chat-specific steering files are loaded
5. Kiro follows the patterns and rules defined in these files

### For Developers

#### View Active Steering Files
Look at the **AGENT STEERING** section in Kiro's sidebar to see which steering files are currently active.

#### Create Agent Hooks
1. Open Command Palette: `Cmd/Ctrl + Shift + P`
2. Search: "Open Kiro Hook UI"
3. Click "Create New Hook"
4. Configure trigger and action
5. Save and enable

#### Modify Steering Rules
Edit the markdown files in `.kiro/steering/` to update guidelines. Changes take effect immediately.

#### Add New Steering Files
Create a new markdown file in `.kiro/steering/` with frontmatter:
```markdown
---
title: Your Title
inclusion: always | conditional
fileMatchPattern: "path/**/*.ext"  # For conditional
priority: high | medium | low
---

# Your Content
```

## 📋 Quick Reference

### Common Commands
```bash
# Flutter
cd flutter_chat_app
flutter analyze                                    # Check for errors
flutter test                                       # Run tests
dart run build_runner build --delete-conflicting-outputs  # Generate code
flutter gen-l10n                                   # Generate localization
flutter pub outdated                               # Check outdated packages

# Backend
cd src
npm run start:dev                                  # Start dev server
npm run test                                       # Run tests
npm run lint                                       # Lint code
```

### Critical Rules to Remember
1. ✅ **ALWAYS** use `const` constructors where possible
2. ❌ **NEVER** use relative imports (use package imports)
3. ✅ **ALWAYS** handle errors with `Either<Failure, T>`
4. ❌ **NEVER** use `print()` (use Logger)
5. ✅ **ALWAYS** run code generation after model changes
6. ❌ **NEVER** import Flutter in domain layer
7. ✅ **ALWAYS** use localization for UI strings
8. ❌ **NEVER** use null assertion operator `!`

## 🔄 Updates

### Version History
- **v3.0** (2025-01-27): Complete hooks system installation
  - ✅ Installed 20 professional hooks
  - ✅ Created comprehensive documentation (6 files)
  - ✅ Architecture enforcement (6 hooks)
  - ✅ Code quality validation (6 hooks)
  - ✅ Security scanning (3 hooks)
  - ✅ Testing & documentation (3 hooks)
  - ✅ Utilities (2 hooks)
  - ✅ Visual diagrams and guides
  - ✅ Complete index and search
- **v2.2** (2025-01-27): Updated hooks documentation with official Kiro docs
  - Researched official Kiro hooks documentation
  - Updated HOOKS_GUIDE.md with accurate information
  - Hooks use natural language AI-powered prompts (not shell commands)
  - Added 4 example `.kiro.hook` files as templates
  - Hooks stored as `.kiro.hook` files in `.kiro/hooks/` directory
- **v2.1** (2025-01-27): Fixed hooks documentation
  - Removed incorrect JSON hook files
  - Updated to use Kiro UI for hook management
  - Added 10 recommended hooks for the project
  - Added chat-specific steering files
- **v2.0** (2025-01-27): Complete rewrite based on Cursor rules
  - Added comprehensive architecture guide
  - Added Flutter best practices
  - Added NestJS patterns
  - Added critical rules and warnings

### Maintenance
- Review and update steering files when architecture changes
- Hooks are automatically maintained and versioned
- Keep examples up-to-date with latest patterns
- Update documentation as project evolves

## 📚 Related Documentation

- [Flutter Chat App README](../flutter_chat_app/README.md)
- [Backend README](../README.md)
- [Cursor Rules](../flutter_chat_app/.cursor-rules.yaml)
- [Architecture Documentation](../flutter_chat_app/.cursor/rules/project-architecture-structure.mdc)

---

**Maintained by**: Senior Flutter/Mobile Architect  
**Last Updated**: 2025-01-27  
**Version**: 3.0  
**Hooks Installed**: 20 active hooks  
**Documentation**: 6 comprehensive guides  
**Status**: ✅ Production Ready

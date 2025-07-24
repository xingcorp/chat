# Flutter Messaging App - Development Rules

This directory contains comprehensive development rules for building enterprise-grade Flutter messaging applications following WhatsApp/Telegram/Messenger standards.

## 📋 Rules Overview

### Core Principles
- **[clean-code.md](./clean-code.md)** - Clean code principles for readable, maintainable code
- **[clean-architecture.md](./clean-architecture.md)** - Clean Architecture layers and dependency rules
- **[solid-principles.md](./solid-principles.md)** - SOLID principles for object-oriented design

### Flutter Specific
- **[flutter-best-practices.md](./flutter-best-practices.md)** - Flutter-specific best practices and conventions
- **[messaging-app-patterns.md](./messaging-app-patterns.md)** - Patterns specific to messaging applications
- **[performance-optimization.md](./performance-optimization.md)** - Performance optimization techniques

### Quality Assurance
- **[testing-standards.md](./testing-standards.md)** - Comprehensive testing standards and practices
- **[error-handling.md](./error-handling.md)** - Error handling strategies and patterns
- **[security-guidelines.md](./security-guidelines.md)** - Security best practices

## 🎯 Performance Targets

All rules are designed to achieve these enterprise-grade targets:
- **App Startup**: <2s cold start
- **Message Delivery**: <100ms latency
- **Memory Usage**: <150MB peak
- **UI Rendering**: 60fps consistent
- **Connection Recovery**: <5s

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│              Presentation               │
│         (UI, BLoC, Widgets)            │
├─────────────────────────────────────────┤
│               Domain                    │
│      (Entities, Use Cases, Repos)      │
├─────────────────────────────────────────┤
│                Data                     │
│    (Repository Impl, Data Sources)     │
├─────────────────────────────────────────┤
│              External                   │
│   (Frameworks, DB, Network, Device)    │
└─────────────────────────────────────────┘
```

## 🔧 Key Technologies

- **State Management**: BLoC pattern with `flutter_bloc`
- **Dependency Injection**: `get_it` with `injectable`
- **Data Classes**: `freezed` for immutable models
- **Error Handling**: `either_dart` for functional error handling
- **Real-time**: WebSocket with auto-reconnection
- **Local Storage**: `hive` or `sqflite` with encryption

## 📱 Messaging Features

- Real-time messaging with <100ms delivery
- Offline-first architecture with sync
- Typing indicators and read receipts
- Message status tracking
- File and media sharing
- Push notifications
- End-to-end encryption

## 🧪 Testing Strategy

- **Unit Tests**: Business logic and utilities
- **Widget Tests**: UI components and interactions
- **Integration Tests**: End-to-end user flows
- **Golden Tests**: Visual regression testing
- **Coverage Target**: >80% code coverage

## 🚀 Getting Started

1. Read [clean-code.md](./clean-code.md) for fundamental principles
2. Understand [clean-architecture.md](./clean-architecture.md) for project structure
3. Follow [flutter-best-practices.md](./flutter-best-practices.md) for Flutter-specific guidelines
4. Implement [messaging-app-patterns.md](./messaging-app-patterns.md) for real-time features
5. Apply [performance-optimization.md](./performance-optimization.md) for enterprise performance
6. Use [testing-standards.md](./testing-standards.md) for comprehensive testing
7. Follow [error-handling.md](./error-handling.md) for robust error management
8. Implement [security-guidelines.md](./security-guidelines.md) for secure messaging

## 📚 Additional Resources

- [Uncle Bob's Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Documentation](https://flutter.dev/docs)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [BLoC Library](https://bloclibrary.dev/)

## 🎯 Success Metrics

- Zero critical build errors
- <50 analyzer warnings
- >80% test coverage
- Performance targets met
- Security guidelines followed
- Clean architecture maintained

---

**Remember**: These rules ensure enterprise-grade code quality matching industry standards while maintaining clean, maintainable, and performant Flutter architecture.

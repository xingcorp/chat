# Flutter Chat App

A modern, feature-rich Flutter chat application with offline-first capability, built with clean architecture principles.

## Features

- Real-time messaging with typing indicators
- Online/offline status indicators
- Message read receipts
- Group chat support
- File and image sharing
- Push notifications
- Dark/light theme support
- Localization support
- Offline message queue
- End-to-end encryption (planned)
- Voice messages (planned)
- Video calls (planned)

## Architecture

The application follows Clean Architecture principles with the following layers:

### Presentation Layer
- **Pages**: UI components and screens
- **Widgets**: Reusable UI components
- **BLoCs**: Business Logic Components for state management
- **View Models**: Presentation-specific models

### Domain Layer
- **Entities**: Core business models
- **Repositories**: Abstract definition of data operations
- **Use Cases**: Business logic operations

### Data Layer
- **Repositories**: Implementation of domain repositories
- **Data Sources**: Remote and local data providers
- **Models**: Data transfer objects

### Core
- **Network**: API clients and network utilities
- **Storage**: Local storage utilities
- **Common**: Shared utilities, extensions, and constants

## Tech Stack

- **State Management**: Flutter BLoC
- **Dependency Injection**: GetIt
- **Local Database**: Isar DB
- **API Client**: Dio
- **Realtime Communication**: Socket.IO
- **Authentication**: Firebase Auth
- **File Storage**: Firebase Storage
- **Notifications**: Firebase Cloud Messaging
- **Analytics/Crashlytics**: Firebase Analytics & Crashlytics

## Getting Started

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Create a `.env` file based on `.env.example`
4. Run the app: `flutter run`

## Development Guidelines

- Follow the project architecture
- Write tests for all new features
- Use meaningful commit messages following conventional commits
- Document all public APIs
- Use linter and formatter before committing

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
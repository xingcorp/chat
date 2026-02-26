---
inclusion: fileMatch
fileMatchPattern: "flutter_chat_app/lib/**/*{chat,message,conversation}*.dart"
---

# Chat Feature Implementation

> Rules and patterns for implementing chat features. Refer to base-class-patterns and project-architecture for general rules.

## Layer Order

Always implement in this order: Domain → Data → Presentation → DI registration → Code generation.

## Key Source Files

- Repository interfaces: #[[file:flutter_chat_app/lib/domain/repositories/i_message_repository.dart]]
- Repository impl: #[[file:flutter_chat_app/lib/data/repositories/message_repository_impl.dart]]
- Message BLoC: #[[file:flutter_chat_app/lib/presentation/blocs/message/message_bloc.dart]]
- Message state: #[[file:flutter_chat_app/lib/presentation/blocs/message/message_state.dart]]
- GraphQL operations: #[[file:flutter_chat_app/lib/data/graphql/chat_operations.dart]]
- DTOs: #[[file:flutter_chat_app/lib/data/dtos/message_dto.dart]]
- Mappers: #[[file:flutter_chat_app/lib/data/mappers/message_mapper.dart]]
- Socket event mapper: #[[file:flutter_chat_app/lib/data/mappers/socket_io_event_mapper.dart]]
- DI registration: #[[file:flutter_chat_app/lib/core/di/chat_module_injection.dart]]

## Domain Layer Rules

- Entities go in `lib/domain/entities/`
- Repository interfaces in `lib/domain/repositories/` prefixed with `I`
- Use cases in `lib/domain/usecases/message/` or `lib/domain/usecases/chat_info/`
- Every use case extends `UseCase<ReturnType, Params>` from `core/usecases/usecase.dart`
- Return `Either<Failure, T>` for all repository methods
- NO Flutter/infrastructure imports in domain layer

## Data Layer Rules

- DTOs use `@freezed` + `@JsonSerializable` in `lib/data/dtos/`
- Mappers in `lib/data/mappers/` handle DTO ↔ Entity conversion
- Remote datasources in `lib/data/datasources/message/` call GraphQL via `graphql_client.dart`
- Local datasources use Isar for offline storage
- Repository impls in `lib/data/repositories/` annotated with `@LazySingleton(as: IRepository)`

## Presentation Layer Rules

- BLoC files in `lib/presentation/blocs/{feature}/` with separate event, state, bloc files
- States use `@freezed` and extend `BaseState`
- BLoCs extend `BaseBloc<Event, State>` and use `@injectable`
- Dispose all stream subscriptions in `close()`
- Use optimistic updates for send operations: show temp message → replace on server response

## Message-Specific Patterns

- Messages are ordered by `createdAt DESC` (newest first)
- Pagination uses cursor-based approach with `lastKey` (conversationId + createdAt timestamp)
- Temp message IDs use format: `temp_{timestamp}`
- Message statuses: `local → sending → sent → delivered → read → failed`
- Merge strategy for combining local + remote messages: #[[file:flutter_chat_app/lib/data/strategies/message_merge_strategy.dart]]
- Socket event buffering during loading: #[[file:flutter_chat_app/lib/presentation/blocs/message/socket_event_buffer.dart]]

## After Changes

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n  # if new user-facing strings added
```

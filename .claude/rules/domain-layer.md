# Domain Layer Rules
# Applies to: flutter_chat_app/lib/domain/**/*.dart

## ABSOLUTE RULES — NO EXCEPTIONS

1. **NO Flutter imports** — Domain layer must be pure Dart
   - ❌ `import 'package:flutter/...';`
   - ❌ `import 'package:flutter_bloc/...';`
   - ✅ `import 'package:dartz/dartz.dart';`
   - ✅ `import 'package:equatable/equatable.dart';`

2. **NO Data layer imports**
   - ❌ `import 'package:flutter_chat_app/data/...';`

3. **NO Presentation layer imports**
   - ❌ `import 'package:flutter_chat_app/presentation/...';`

4. **Repository interfaces MUST use `I` prefix**
   - ✅ `abstract class IMessageRepository`
   - ❌ `abstract class MessageRepository`

5. **All repository methods MUST return `Either<Failure, T>`**
   - ✅ `Future<Either<Failure, List<ChatMessage>>> getMessages(...);`
   - ❌ `Future<List<ChatMessage>> getMessages(...);`

6. **Use cases MUST extend `UseCase<ReturnType, Params>`**
   ```dart
   class SendMessageUseCase extends UseCase<ChatMessage, SendMessageParams> {
     @override
     Future<Either<Failure, ChatMessage>> call(SendMessageParams params);
   }
   ```

7. **Entities MUST be immutable**
   - Use `const` constructors
   - Use `final` fields
   - Consider `@freezed` for complex entities

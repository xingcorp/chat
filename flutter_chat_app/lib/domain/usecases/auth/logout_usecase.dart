/// Logout Use Case
/// 
/// Handles user logout business logic following Clean Architecture.
/// Encapsulates logout flow with proper cleanup and error handling.
/// 
/// Author: Senior Flutter/Mobile Architect
library logout_usecase;

import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/domain/repositories/auth_repository.dart';

/// Logout use case implementation
/// 
/// Handles user logout with proper cleanup and error handling.
/// Follows Clean Architecture principles by encapsulating business logic.
class LogoutUseCase implements NoParamsUseCase<void> {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call() async {
    try {
      // Perform logout through repository
      await repository.logout();
      
      // Additional business logic can be added here
      // For example: clear local cache, cancel subscriptions, etc.
      await _performCleanup();
      
      return const Right(null);
    } catch (e) {
      // Convert exceptions to appropriate failures
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Perform cleanup operations after logout
  Future<void> _performCleanup() async {
    // Additional cleanup logic would go here
    // For example:
    // - Clear cached user data
    // - Cancel real-time subscriptions
    // - Clear sensitive information from memory
    // - Reset app state to initial values
  }

  /// Map exceptions to appropriate failures
  Failure _mapExceptionToFailure(dynamic exception) {
    if (exception is NetworkException) {
      return NetworkFailure(message: exception.message);
    } else if (exception is ServerException) {
      return ServerFailure(message: exception.message);
    } else {
      return UnknownFailure(message: 'Đã xảy ra lỗi không xác định: ${exception.toString()}');
    }
  }
}

/// Custom exceptions for logout
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

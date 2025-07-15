/// Base Use Case Interface
/// 
/// Defines the contract for all use cases in the domain layer.
/// Follows Clean Architecture principles with proper error handling.
/// 
/// Author: Senior Flutter/Mobile Architect
library usecase;

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/result.dart';

/// Base interface for all use cases
///
/// [Type] - The return type of the use case
/// [Params] - The parameters required by the use case
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Result<Type>> call(Params params);
}

/// Use case that doesn't require parameters
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters
  Future<Result<Type>> call();
}

/// Stream-based use case for real-time data
abstract class StreamUseCase<Type, Params> {
  /// Execute the use case and return a stream
  Stream<Result<Type>> call(Params params);
}

/// Stream use case that doesn't require parameters
abstract class NoParamsStreamUseCase<Type> {
  /// Execute the use case and return a stream without parameters
  Stream<Result<Type>> call();
}

/// Synchronous use case for immediate operations
abstract class SyncUseCase<Type, Params> {
  /// Execute the use case synchronously
  Result<Type> call(Params params);
}

/// Synchronous use case that doesn't require parameters
abstract class NoParamsSyncUseCase<Type> {
  /// Execute the use case synchronously without parameters
  Result<Type> call();
}

/// No parameters class for use cases that don't need input
class NoParams {
  const NoParams();
}

/// Base class for use case parameters
abstract class UseCaseParams {
  const UseCaseParams();
}

/// Mixin for use cases that require authentication
mixin AuthenticatedUseCase<Type, Params> on UseCase<Type, Params> {
  /// Check if user is authenticated before executing use case
  Future<Result<Type>> executeAuthenticated(
    Params params,
    Future<Result<Type>> Function() execution,
  ) async {
    // This would typically check authentication status
    // For now, we'll assume authentication is handled elsewhere
    return await execution();
  }
}

/// Mixin for use cases that require network connectivity
mixin NetworkAwareUseCase<Type, Params> on UseCase<Type, Params> {
  /// Execute use case with network awareness
  Future<Result<Type>> executeWithNetworkCheck(
    Params params,
    Future<Result<Type>> Function() execution,
  ) async {
    // This would typically check network connectivity
    // For now, we'll assume network checking is handled elsewhere
    return await execution();
  }
}

/// Mixin for use cases that support caching
mixin CacheableUseCase<Type, Params> on UseCase<Type, Params> {
  /// Execute use case with caching support
  Future<Result<Type>> executeWithCache(
    Params params,
    String cacheKey,
    Future<Result<Type>> Function() execution,
  ) async {
    // This would typically implement caching logic
    // For now, we'll execute directly
    return await execution();
  }
}

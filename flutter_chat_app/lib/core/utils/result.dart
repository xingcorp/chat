/// Result Pattern Implementation
/// 
/// Built-in Dart implementation of Result pattern to replace dartz Either.
/// Provides type-safe error handling without external dependencies.
/// 
/// Author: Senior Flutter/Mobile Architect
library result;

import 'package:flutter_chat_app/core/error/failures.dart';

/// Result type for handling success and failure cases
/// 
/// Replaces dartz Either<Failure, T> with built-in Dart implementation.
/// Provides type-safe error handling and functional programming patterns.
sealed class Result<T> {
  const Result();

  /// Create a success result
  const factory Result.success(T value) = Success<T>;

  /// Create a failure result
  const factory Result.failure(Failure failure) = Failed<T>;

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failed<T>;

  /// Get success value or null
  T? get valueOrNull => switch (this) {
    Success<T>(value: final value) => value,
    Failed<T>() => null,
  };

  /// Get failure or null
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Failed<T>(failure: final failure) => failure,
  };

  /// Transform success value
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(value: final value) => Result.success(transform(value)),
    Failed<T>(failure: final failure) => Result.failure(failure),
  };

  /// Transform failure
  Result<T> mapFailure(Failure Function(Failure failure) transform) => switch (this) {
    Success<T>() => this,
    Failed<T>(failure: final failure) => Result.failure(transform(failure)),
  };

  /// Chain operations (flatMap)
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success<T>(value: final value) => transform(value),
    Failed<T>(failure: final failure) => Result.failure(failure),
  };

  /// Handle both success and failure cases
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) => switch (this) {
    Success<T>(value: final value) => onSuccess(value),
    Failed<T>(failure: final failure) => onFailure(failure),
  };

  /// Get value or throw exception
  T get value => switch (this) {
    Success<T>(value: final value) => value,
    Failed<T>(failure: final failure) => throw Exception(failure.message),
  };

  /// Get value or return default
  T getOrElse(T defaultValue) => switch (this) {
    Success<T>(value: final value) => value,
    Failed<T>() => defaultValue,
  };

  /// Get value or compute default
  T getOrElseCompute(T Function() computeDefault) => switch (this) {
    Success<T>(value: final value) => value,
    Failed<T>() => computeDefault(),
  };

  /// Execute side effect on success
  Result<T> onSuccess(void Function(T value) action) {
    if (this case Success<T>(value: final value)) {
      action(value);
    }
    return this;
  }

  /// Execute side effect on failure
  Result<T> onFailure(void Function(Failure failure) action) {
    if (this case Failed<T>(failure: final failure)) {
      action(failure);
    }
    return this;
  }

  /// Filter success values
  Result<T> where(bool Function(T value) predicate, Failure Function() orElse) => switch (this) {
    Success<T>(value: final value) when predicate(value) => this,
    Success<T>() => Result.failure(orElse()),
    Failed<T>() => this,
  };

  @override
  String toString() => switch (this) {
    Success<T>(value: final value) => 'Success($value)',
    Failed<T>(failure: final failure) => 'Failed($failure)',
  };

  @override
  bool operator ==(Object other) => switch ((this, other)) {
    (Success<T>(value: final a), Success<T>(value: final b)) => a == b,
    (Failed<T>(failure: final a), Failed<T>(failure: final b)) => a == b,
    _ => false,
  };

  @override
  int get hashCode => switch (this) {
    Success<T>(value: final value) => value.hashCode,
    Failed<T>(failure: final failure) => failure.hashCode,
  };
}

/// Success case of Result
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);
}

/// Failure case of Result
final class Failed<T> extends Result<T> {
  final Failure failure;

  const Failed(this.failure);
}

/// Extension methods for Future<Result<T>>
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Transform async success value
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async {
    final result = await this;
    return switch (result) {
      Success<T>(value: final value) => Result.success(await transform(value)),
      Failed<T>(failure: final failure) => Result.failure(failure),
    };
  }

  /// Chain async operations
  Future<Result<R>> flatMapAsync<R>(Future<Result<R>> Function(T value) transform) async {
    final result = await this;
    return switch (result) {
      Success<T>(value: final value) => await transform(value),
      Failed<T>(failure: final failure) => Result.failure(failure),
    };
  }

  /// Handle async result
  Future<R> foldAsync<R>(
    Future<R> Function(Failure failure) onFailure,
    Future<R> Function(T value) onSuccess,
  ) async {
    final result = await this;
    return switch (result) {
      Success<T>(value: final value) => await onSuccess(value),
      Failed<T>(failure: final failure) => await onFailure(failure),
    };
  }
}

/// Extension methods for List<Result<T>>
extension ListResultExtension<T> on List<Result<T>> {
  /// Combine all results into single result
  Result<List<T>> sequence() {
    final values = <T>[];
    for (final result in this) {
      switch (result) {
        case Success<T>(value: final value):
          values.add(value);
        case Failed<T>(failure: final failure):
          return Result.failure(failure);
      }
    }
    return Result.success(values);
  }

  /// Get all successful values
  List<T> successes() {
    return [
      for (final result in this)
        if (result case Success<T>(value: final value)) value
    ];
  }

  /// Get all failures
  List<Failure> failures() {
    return [
      for (final result in this)
        if (result case Failed<T>(failure: final failure)) failure
    ];
  }
}

/// Utility functions for Result
class ResultUtils {
  /// Try to execute a function and wrap result
  static Result<T> tryCall<T>(T Function() fn) {
    try {
      return Result.success(fn());
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }

  /// Try to execute an async function and wrap result
  static Future<Result<T>> tryCallAsync<T>(Future<T> Function() fn) async {
    try {
      final value = await fn();
      return Result.success(value);
    } catch (e) {
      return Result.failure(UnexpectedFailure(message: e.toString()));
    }
  }

  /// Combine two results
  static Result<(T1, T2)> combine2<T1, T2>(
    Result<T1> result1,
    Result<T2> result2,
  ) {
    return switch ((result1, result2)) {
      (Success<T1>(value: final v1), Success<T2>(value: final v2)) => 
        Result.success((v1, v2)),
      (Failed<T1>(failure: final f), _) => Result.failure(f),
      (_, Failed<T2>(failure: final f)) => Result.failure(f),
    };
  }

  /// Combine three results
  static Result<(T1, T2, T3)> combine3<T1, T2, T3>(
    Result<T1> result1,
    Result<T2> result2,
    Result<T3> result3,
  ) {
    return switch ((result1, result2, result3)) {
      (
        Success<T1>(value: final v1),
        Success<T2>(value: final v2),
        Success<T3>(value: final v3)
      ) => Result.success((v1, v2, v3)),
      (Failed<T1>(failure: final f), _, _) => Result.failure(f),
      (_, Failed<T2>(failure: final f), _) => Result.failure(f),
      (_, _, Failed<T3>(failure: final f)) => Result.failure(f),
    };
  }
}

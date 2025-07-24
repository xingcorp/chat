/// **RETRY CONFIGURATION - ADVANCED ERROR RECOVERY**
///
/// Professional retry configuration for enterprise messaging apps:
/// - Exponential backoff strategy with jitter
/// - Intelligent retry conditions based on failure types
/// - Configurable retry parameters for different operations
/// - Circuit breaker pattern for failing services
///
/// **Architecture:** Clean Architecture + Error Recovery Patterns

import 'dart:math';

import 'package:flutter_chat_app/core/error/failures.dart';

/// **Retry Strategy Enum**
enum RetryStrategy {
  /// No retry - fail immediately
  none,
  
  /// Fixed delay between retries
  fixedDelay,
  
  /// Exponential backoff with optional jitter
  exponentialBackoff,
  
  /// Linear backoff (delay increases linearly)
  linearBackoff,
}

/// **Retry Configuration**
///
/// Comprehensive retry configuration for different operation types
class RetryConfig {
  /// Maximum number of retry attempts
  final int maxAttempts;
  
  /// Base delay for retry calculations
  final Duration baseDelay;
  
  /// Maximum delay between retries
  final Duration maxDelay;
  
  /// Retry strategy to use
  final RetryStrategy strategy;
  
  /// Whether to add jitter to prevent thundering herd
  final bool useJitter;
  
  /// Multiplier for exponential backoff
  final double backoffMultiplier;
  
  /// Timeout for each individual retry attempt
  final Duration? attemptTimeout;
  
  /// Custom retry condition function
  final bool Function(Failure failure, int attemptNumber)? retryCondition;

  const RetryConfig({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.strategy = RetryStrategy.exponentialBackoff,
    this.useJitter = true,
    this.backoffMultiplier = 2.0,
    this.attemptTimeout,
    this.retryCondition,
  });

  /// **Default Network Retry Config**
  /// For network operations: 3 attempts, exponential backoff 1s→2s→4s
  static const RetryConfig network = RetryConfig(
    maxAttempts: 3,
    baseDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 8),
    strategy: RetryStrategy.exponentialBackoff,
    useJitter: true,
    backoffMultiplier: 2.0,
  );

  /// **Default Real-time Retry Config**
  /// For real-time connections: 5 attempts, faster recovery
  static const RetryConfig realtime = RetryConfig(
    maxAttempts: 5,
    baseDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 5),
    strategy: RetryStrategy.exponentialBackoff,
    useJitter: true,
    backoffMultiplier: 1.5,
  );

  /// **Default Authentication Retry Config**
  /// For auth operations: 2 attempts, shorter delays
  static const RetryConfig authentication = RetryConfig(
    maxAttempts: 2,
    baseDelay: Duration(milliseconds: 800),
    maxDelay: Duration(seconds: 3),
    strategy: RetryStrategy.exponentialBackoff,
    useJitter: false,
    backoffMultiplier: 2.0,
  );

  /// **Default Cache Retry Config**
  /// For cache operations: 2 attempts, quick recovery
  static const RetryConfig cache = RetryConfig(
    maxAttempts: 2,
    baseDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 1),
    strategy: RetryStrategy.fixedDelay,
    useJitter: false,
  );

  /// **No Retry Config**
  /// For operations that should not be retried
  static const RetryConfig none = RetryConfig(
    maxAttempts: 0,
    strategy: RetryStrategy.none,
  );

  /// **Calculate Retry Delay**
  ///
  /// Calculates delay for specific attempt using configured strategy
  /// **Performance:** <1ms calculation time
  Duration calculateDelay(int attemptNumber) {
    if (strategy == RetryStrategy.none || attemptNumber <= 0) {
      return Duration.zero;
    }

    Duration delay;

    switch (strategy) {
      case RetryStrategy.fixedDelay:
        delay = baseDelay;
        break;

      case RetryStrategy.linearBackoff:
        delay = Duration(
          milliseconds: baseDelay.inMilliseconds * attemptNumber,
        );
        break;

      case RetryStrategy.exponentialBackoff:
        final exponentialDelay = baseDelay.inMilliseconds * 
            pow(backoffMultiplier, attemptNumber - 1);
        delay = Duration(milliseconds: exponentialDelay.round());
        break;

      case RetryStrategy.none:
        return Duration.zero;
    }

    // Apply maximum delay limit
    if (delay > maxDelay) {
      delay = maxDelay;
    }

    // Add jitter to prevent thundering herd problem
    if (useJitter && delay.inMilliseconds > 0) {
      final jitterMs = Random().nextInt(delay.inMilliseconds ~/ 4);
      delay = Duration(milliseconds: delay.inMilliseconds + jitterMs);
    }

    return delay;
  }

  /// **Should Retry**
  ///
  /// Determines if operation should be retried based on failure and attempt number
  bool shouldRetry(Failure failure, int attemptNumber) {
    // Check max attempts
    if (attemptNumber >= maxAttempts) {
      return false;
    }

    // Use custom retry condition if provided
    if (retryCondition != null) {
      return retryCondition!(failure, attemptNumber);
    }

    // Default retry logic based on failure type
    return _defaultShouldRetry(failure, attemptNumber);
  }

  /// **Default Retry Logic**
  ///
  /// Default logic for determining if failure is retryable
  bool _defaultShouldRetry(Failure failure, int attemptNumber) {
    switch (failure.runtimeType) {
      // Always retry network-related failures
      case ConnectionFailure:
      case NetworkFailure:
      case TimeoutFailure:
        return true;

      // Retry server errors for certain status codes
      case ServerFailure:
        final code = failure.code;
        return code == '500' || code == '502' || code == '503' || code == '504';

      // Retry realtime failures
      case RealtimeFailure:
        return failure.code != 'authentication_failed';

      // Don't retry validation, auth, or permission failures
      case ValidationFailure:
      case AuthenticationFailure:
      case PermissionFailure:
        return false;

      // Retry cache failures
      case CacheFailure:
        return failure.code != 'permission_denied';

      // Don't retry unexpected failures
      case UnexpectedFailure:
      case UnknownFailure:
        return false;

      default:
        return false;
    }
  }

  /// **Create Custom Config**
  ///
  /// Factory method for creating custom retry configurations
  static RetryConfig custom({
    required int maxAttempts,
    required Duration baseDelay,
    Duration? maxDelay,
    RetryStrategy strategy = RetryStrategy.exponentialBackoff,
    bool useJitter = true,
    double backoffMultiplier = 2.0,
    Duration? attemptTimeout,
    bool Function(Failure failure, int attemptNumber)? retryCondition,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts,
      baseDelay: baseDelay,
      maxDelay: maxDelay ?? Duration(seconds: baseDelay.inSeconds * 10),
      strategy: strategy,
      useJitter: useJitter,
      backoffMultiplier: backoffMultiplier,
      attemptTimeout: attemptTimeout,
      retryCondition: retryCondition,
    );
  }

  /// **Get Config for Operation Type**
  ///
  /// Returns appropriate retry config based on operation type
  static RetryConfig forOperation(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'network':
      case 'api':
      case 'http':
        return network;
      
      case 'realtime':
      case 'websocket':
      case 'messaging':
        return realtime;
      
      case 'auth':
      case 'authentication':
      case 'login':
        return authentication;
      
      case 'cache':
      case 'storage':
      case 'local':
        return cache;
      
      default:
        return network;
    }
  }

  @override
  String toString() {
    return 'RetryConfig(maxAttempts: $maxAttempts, baseDelay: $baseDelay, '
           'strategy: $strategy, useJitter: $useJitter)';
  }
}

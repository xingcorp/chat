/// **BLOC ERROR HANDLING MIXIN - STANDARDIZED ERROR PATTERNS**
///
/// Professional error handling mixin for BLoC layer following clean architecture:
/// - Consistent Either<Failure, T> pattern handling
/// - Vietnamese user-friendly error messages
/// - Proper loading states and error recovery
/// - Performance monitoring and logging
///
/// **Architecture:** Clean Architecture + SOLID principles + BLoC pattern

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/localization/error_localization_service.dart';
import 'package:flutter_chat_app/core/utils/either.dart';

/// **BLoC Error Handling Mixin**
///
/// Provides standardized error handling methods for all BLoCs
/// Following single responsibility principle and clean architecture
mixin BlocErrorMixin<Event, State> on BlocBase<State> {
  /// Logger instance for error tracking
  Logger get logger => Logger();

  /// Error localization service instance
  ErrorLocalizationService get _errorLocalizationService =>
      ErrorLocalizationService.instance;

  /// **Handle Either Result**
  ///
  /// Processes Either<Failure, T> results and emits appropriate states
  /// **Performance:** <10ms state transition
  /// **Strategy:** Consistent error handling with proper state management
  void handleEitherResult<T>(
    Either<Failure, T> result, {
    required State Function(T data) onSuccess,
    required State Function(Failure failure) onFailure,
    String? operationName,
  }) {
    final stopwatch = Stopwatch()..start();
    
    result.fold(
      (failure) {
        stopwatch.stop();
        
        logger.e(
          '❌ BLoC operation failed: ${operationName ?? 'unknown'} (${stopwatch.elapsedMilliseconds}ms)',
          error: failure,
        );
        
        // Log localized user message for debugging
        final localizedMessage = _errorLocalizationService.getLocalizedErrorMessage(failure);
        logger.w('💬 Localized message: $localizedMessage');
        
        emit(onFailure(failure));
      },
      (data) {
        stopwatch.stop();
        
        logger.i(
          '✅ BLoC operation success: ${operationName ?? 'unknown'} (${stopwatch.elapsedMilliseconds}ms)',
        );
        
        emit(onSuccess(data));
      },
    );
  }

  /// **Handle Either Result with Loading**
  ///
  /// Handles Either result with loading state management
  Future<void> handleEitherResultWithLoading<T>(
    Future<Either<Failure, T>> operation, {
    required State loadingState,
    required State Function(T data) onSuccess,
    required State Function(Failure failure) onFailure,
    String? operationName,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.d('🚀 Starting BLoC operation: ${operationName ?? 'unknown'}');
      
      // Emit loading state
      emit(loadingState);
      
      // Execute operation
      final result = await operation;
      
      stopwatch.stop();
      
      // Handle result
      handleEitherResult(
        result,
        onSuccess: onSuccess,
        onFailure: onFailure,
        operationName: operationName,
      );
      
    } catch (exception, stackTrace) {
      stopwatch.stop();
      
      logger.e(
        '💥 BLoC operation exception: ${operationName ?? 'unknown'} (${stopwatch.elapsedMilliseconds}ms)',
        error: exception,
        stackTrace: stackTrace,
      );
      
      // Create unexpected failure
      final failure = UnexpectedFailure(
        message: 'Unexpected error in BLoC: ${exception.toString()}',
        code: 'bloc_exception',
        details: {
          'operation': operationName,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'bloc_type': runtimeType.toString(),
        },
      );
      
      emit(onFailure(failure));
    }
  }

  /// **Get User-Friendly Error Message**
  ///
  /// Extracts user-friendly Vietnamese message from failure
  String getUserErrorMessage(Failure failure) {
    // Use the failure's built-in user message
    final userMessage = failure.userMessage;
    
    // Log technical details for debugging
    logger.d('🔍 Technical error: ${failure.message} (${failure.code})');
    
    return userMessage;
  }

  /// **Check if Error is Recoverable**
  ///
  /// Determines if error can be recovered with retry
  bool isRecoverableError(Failure failure) {
    return failure.isRecoverable;
  }

  /// **Get Error Category**
  ///
  /// Gets error category for analytics and UI handling
  String getErrorCategory(Failure failure) {
    return failure.category;
  }

  /// **Get Error Display Information**
  ///
  /// Returns comprehensive error information for UI display
  DisplayError getErrorDisplayInfo(
    Failure failure, {
    Map<String, dynamic>? context,
    bool includeRecovery = true,
  }) {
    return _errorLocalizationService.formatErrorForDisplay(
      failure,
      context: context,
      includeRecovery: includeRecovery,
    );
  }

  /// **Get Localized Error Message with Context**
  ///
  /// Returns contextualized error message for specific operations
  String getLocalizedErrorMessage(
    Failure failure, {
    Map<String, dynamic>? context,
  }) {
    return _errorLocalizationService.getErrorMessageWithContext(
      failure,
      context: context,
    );
  }

  /// **Get Recovery Guidance**
  ///
  /// Returns step-by-step recovery guidance for the error
  List<String> getRecoveryGuidance(Failure failure) {
    return _errorLocalizationService.getRecoveryGuidance(failure);
  }

  /// **Handle Validation Errors**
  ///
  /// Specialized handling for validation failures with field errors
  Map<String, String> getFieldErrors(Failure failure) {
    if (failure is ValidationFailure && failure.fieldErrors != null) {
      return failure.fieldErrors!;
    }
    return {};
  }

  /// **Log Performance Metrics**
  ///
  /// Logs BLoC performance metrics for monitoring
  void logBlocPerformance({
    required String operation,
    required Duration duration,
    bool success = true,
    String? errorType,
    Map<String, dynamic>? additionalData,
  }) {
    final metrics = {
      'bloc_type': runtimeType.toString(),
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'success': success,
      if (errorType != null) 'error_type': errorType,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };
    
    if (success) {
      logger.i('📊 BLoC Performance: $operation completed in ${duration.inMilliseconds}ms');
    } else {
      logger.w('📊 BLoC Performance: $operation failed in ${duration.inMilliseconds}ms ($errorType)');
    }
    
    // TODO: Send metrics to analytics service
    // AnalyticsService.trackBlocPerformance(metrics);
  }

  /// **Handle Network Errors with Retry**
  ///
  /// Specialized handling for network errors with retry capability
  void handleNetworkError(
    Failure failure, {
    required VoidCallback onRetry,
    required State Function(Failure failure, {VoidCallback? retryAction}) errorStateBuilder,
  }) {
    if (failure is ConnectionFailure || 
        failure is NetworkFailure || 
        failure is TimeoutFailure) {
      
      logger.w('🔄 Network error detected, providing retry option');
      
      emit(errorStateBuilder(failure, retryAction: onRetry));
    } else {
      emit(errorStateBuilder(failure));
    }
  }

  /// **Handle Authentication Errors**
  ///
  /// Specialized handling for authentication failures
  void handleAuthError(
    Failure failure, {
    required VoidCallback onReauthenticate,
    required State Function(Failure failure, {VoidCallback? authAction}) errorStateBuilder,
  }) {
    if (failure is AuthenticationFailure) {
      logger.w('🔐 Authentication error detected, providing re-auth option');
      
      emit(errorStateBuilder(failure, authAction: onReauthenticate));
    } else {
      emit(errorStateBuilder(failure));
    }
  }

  /// **Emit Safe State**
  ///
  /// Safely emits state with error handling
  void emitSafe(State state, {String? context}) {
    try {
      if (!isClosed) {
        emit(state);
        logger.t('📤 State emitted: ${state.runtimeType} ${context != null ? '($context)' : ''}');
      } else {
        logger.w('⚠️ Attempted to emit state on closed BLoC: ${state.runtimeType}');
      }
    } catch (exception, stackTrace) {
      logger.e(
        '💥 Error emitting state: ${state.runtimeType}',
        error: exception,
        stackTrace: stackTrace,
      );
    }
  }

  /// **Create Error State with Context**
  ///
  /// Helper to create error states with additional context
  Map<String, dynamic> createErrorContext({
    required String operation,
    Map<String, dynamic>? additionalContext,
  }) {
    return {
      'operation': operation,
      'bloc_type': runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalContext,
    };
  }
}

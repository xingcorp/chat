# 🚨 **UNIFIED ERROR HANDLING STRATEGY**

## 🎯 **ERROR HANDLING OBJECTIVES**

**Primary Goal**: Implement consistent, enterprise-grade error handling across all layers  
**Target**: 90% error handling uniformity (from current 30%)  
**Timeline**: Week 2 of consolidation roadmap  
**Risk Level**: Medium (affects user experience)  

## 📊 **CURRENT ERROR HANDLING LANDSCAPE**

### **Error Handling Pattern Distribution**
- **BaseBloc Enterprise Pattern**: 15% (3 BLoCs)
- **Either Functional Pattern**: 30% (repositories)
- **Manual Exception Throwing**: 35% (various methods)
- **Silent Error Handling**: 20% (problematic cases)

### **Critical Issues Identified**
1. **Inconsistent User Feedback**: Some errors silent, others verbose
2. **No Centralized Error Analytics**: Missing error tracking
3. **Poor Error Recovery**: Limited retry mechanisms
4. **Fragmented Error Types**: Multiple error classification systems

## 🏛️ **UNIFIED ERROR ARCHITECTURE**

### **Error Type Hierarchy**

```dart
// lib/core/error/error_types.dart
enum ErrorType {
  // Network-related errors
  network,
  timeout,
  noConnection,
  
  // Authentication & Authorization
  authentication,
  authorization,
  tokenExpired,
  
  // Data & Validation
  validation,
  parsing,
  notFound,
  
  // Server-related
  server,
  maintenance,
  rateLimit,
  
  // Client-related
  general,
  unexpected,
  permission,
}

enum ErrorSeverity {
  low,      // Non-blocking, background operations
  medium,   // User-facing but recoverable
  high,     // Blocks user workflow
  critical, // App-breaking, requires immediate attention
}
```

### **Unified Failure Classes**

```dart
// lib/core/error/failures.dart
abstract class Failure extends Equatable {
  final String message;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? code;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final bool shouldRetry;
  final Duration? retryAfter;

  const Failure({
    required this.message,
    required this.type,
    this.severity = ErrorSeverity.medium,
    this.code,
    this.details,
    DateTime? timestamp,
    this.shouldRetry = false,
    this.retryAfter,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [message, type, severity, code, details, shouldRetry];
}

// Specific failure implementations
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network error occurred',
    super.code,
    super.details,
    super.shouldRetry = true,
    super.retryAfter = const Duration(seconds: 5),
  }) : super(
    type: ErrorType.network,
    severity: ErrorSeverity.medium,
  );
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Authentication failed',
    super.code,
    super.details,
  }) : super(
    type: ErrorType.authentication,
    severity: ErrorSeverity.high,
  );
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> fieldErrors;
  
  const ValidationFailure({
    super.message = 'Validation failed',
    this.fieldErrors = const {},
    super.code,
    super.details,
  }) : super(
    type: ErrorType.validation,
    severity: ErrorSeverity.medium,
  );
}
```

### **Enhanced BaseBloc Error Handling**

```dart
// lib/presentation/blocs/base/base_bloc.dart
abstract class BaseBloc<EventType, StateType> extends Bloc<EventType, StateType> {
  final AnalyticsService _analyticsService;
  final CrashReporter _crashReporter;
  final Logger _logger;
  final ErrorRecoveryService _errorRecoveryService;

  BaseBloc({
    required AnalyticsService analyticsService,
    required CrashReporter crashReporter,
    required Logger logger,
    required ErrorRecoveryService errorRecoveryService,
    required StateType initialState,
  }) : _analyticsService = analyticsService,
       _crashReporter = crashReporter,
       _logger = logger,
       _errorRecoveryService = errorRecoveryService,
       super(initialState);

  /// Unified error handling with comprehensive reporting
  Future<void> handleError(
    Failure failure, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    // 1. Log error with context
    _logger.e(
      '[${runtimeType.toString()}] ${failure.type.name}: ${failure.message}',
      error: failure,
      stackTrace: stackTrace,
    );

    // 2. Report to crash analytics
    await _reportToCrashAnalytics(failure, stackTrace, context);

    // 3. Track error analytics
    await _trackErrorAnalytics(failure, context);

    // 4. Attempt error recovery
    final recoveryAction = await _errorRecoveryService.getRecoveryAction(failure);
    
    // 5. Emit appropriate error state
    await _emitErrorState(failure, recoveryAction);

    // 6. Schedule retry if applicable
    if (failure.shouldRetry && recoveryAction.shouldAutoRetry) {
      _scheduleRetry(failure, recoveryAction);
    }
  }

  /// Execute operation with comprehensive error handling
  Future<void> executeWithErrorHandling<T>({
    required Future<Either<Failure, T>> Function() operation,
    required void Function(T) onSuccess,
    void Function(Failure)? onError,
    String? operationName,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await operation();
      
      result.fold(
        (failure) async {
          await handleError(
            failure,
            context: {
              ...?context,
              'operation': operationName,
              'bloc': runtimeType.toString(),
            },
          );
          onError?.call(failure);
        },
        (data) => onSuccess(data),
      );
    } catch (e, stackTrace) {
      final failure = UnexpectedFailure(
        message: 'Unexpected error in $operationName: ${e.toString()}',
        details: {'originalError': e.toString()},
      );
      
      await handleError(
        failure,
        stackTrace: stackTrace,
        context: context,
      );
      onError?.call(failure);
    }
  }
}
```

## 🔄 **ERROR HANDLING MIGRATION STRATEGY**

### **Phase 1: Core Error Infrastructure (Days 1-2)**

#### **Step 1: Implement Error Type System**
```dart
// Create comprehensive error type definitions
// Implement failure class hierarchy
// Create error mapping utilities
// Set up error analytics infrastructure
```

#### **Step 2: Enhance BaseBloc**
```dart
// Add comprehensive error handling to BaseBloc
// Implement error recovery service
// Create error state management
// Add retry mechanisms
```

### **Phase 2: Repository Error Standardization (Days 3-4)**

#### **Step 3: Repository Error Mapping**
```dart
// lib/core/error/repository_error_mapper.dart
class RepositoryErrorMapper {
  static Failure mapExceptionToFailure(dynamic exception) {
    if (exception is SocketException) {
      return const NetworkFailure(
        message: 'No internet connection',
        code: 'NO_CONNECTION',
        shouldRetry: true,
      );
    }
    
    if (exception is TimeoutException) {
      return const NetworkFailure(
        message: 'Request timeout',
        code: 'TIMEOUT',
        shouldRetry: true,
        retryAfter: Duration(seconds: 10),
      );
    }
    
    if (exception is GraphQLException) {
      return _mapGraphQLException(exception);
    }
    
    return UnexpectedFailure(
      message: 'Unexpected error: ${exception.toString()}',
      details: {'originalException': exception.toString()},
    );
  }

  static Failure _mapGraphQLException(GraphQLException exception) {
    final errors = exception.graphqlErrors;
    
    if (errors.any((e) => e.extensions?['code'] == 'UNAUTHENTICATED')) {
      return const AuthenticationFailure(
        message: 'Authentication required',
        code: 'UNAUTHENTICATED',
      );
    }
    
    if (errors.any((e) => e.extensions?['code'] == 'VALIDATION_ERROR')) {
      return ValidationFailure(
        message: 'Validation failed',
        code: 'VALIDATION_ERROR',
        fieldErrors: _extractFieldErrors(errors),
      );
    }
    
    return ServerFailure(
      message: errors.first.message,
      code: errors.first.extensions?['code'],
    );
  }
}
```

### **Phase 3: BLoC Error Integration (Day 5)**

#### **Step 4: Migrate BLoCs to Unified Error Handling**
```dart
// Before: Manual error handling
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  Future<void> _onLoadChats(_LoadChats event, Emitter<ChatState> emit) async {
    try {
      final chats = await _chatRepository.getChats();
      emit(ChatState.loaded(chats: chats));
    } catch (e) {
      emit(ChatState.error(message: 'Failed to load chats: $e'));
    }
  }
}

// After: BaseBloc unified error handling
class ChatBloc extends BaseBloc<ChatEvent, ChatState> {
  Future<void> _onLoadChats(_LoadChats event, Emitter<ChatState> emit) async {
    await executeWithErrorHandling<List<Chat>>(
      operation: () => _chatRepository.getChats(),
      onSuccess: (chats) => emit(ChatState.loaded(chats: chats)),
      operationName: 'loadChats',
      context: {'userId': event.userId},
    );
  }
}
```

## 🎨 **USER-FACING ERROR HANDLING**

### **Error Display Components**

```dart
// lib/presentation/widgets/error/error_display_widget.dart
class ErrorDisplayWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDisplayWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getErrorColor(failure.severity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_getErrorIcon(failure.type)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getUserFriendlyMessage(failure),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
            ],
          ),
          if (failure.shouldRetry && onRetry != null) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  String _getUserFriendlyMessage(Failure failure) {
    switch (failure.type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.authentication:
        return 'Please log in again to continue.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.server:
        return 'Server is temporarily unavailable. Please try again later.';
      default:
        return failure.message;
    }
  }
}
```

### **Error Recovery Service**

```dart
// lib/core/services/error_recovery_service.dart
class ErrorRecoveryService {
  final AuthService _authService;
  final ConnectivityService _connectivityService;

  Future<ErrorRecoveryAction> getRecoveryAction(Failure failure) async {
    switch (failure.type) {
      case ErrorType.authentication:
        return ErrorRecoveryAction(
          type: RecoveryType.redirectToLogin,
          shouldAutoRetry: false,
          userMessage: 'Please log in again',
        );
        
      case ErrorType.network:
        final hasConnection = await _connectivityService.hasConnection;
        return ErrorRecoveryAction(
          type: hasConnection ? RecoveryType.retry : RecoveryType.waitForConnection,
          shouldAutoRetry: hasConnection,
          retryDelay: failure.retryAfter ?? const Duration(seconds: 5),
          userMessage: hasConnection 
            ? 'Retrying...' 
            : 'Waiting for internet connection',
        );
        
      case ErrorType.validation:
        return ErrorRecoveryAction(
          type: RecoveryType.showValidationErrors,
          shouldAutoRetry: false,
          userMessage: 'Please correct the errors and try again',
        );
        
      default:
        return ErrorRecoveryAction(
          type: RecoveryType.showError,
          shouldAutoRetry: failure.shouldRetry,
          retryDelay: failure.retryAfter,
        );
    }
  }
}
```

## 📊 **ERROR ANALYTICS & MONITORING**

### **Error Tracking Implementation**

```dart
// lib/core/monitoring/error_analytics.dart
class ErrorAnalytics {
  final AnalyticsService _analyticsService;
  final CrashReporter _crashReporter;

  Future<void> trackError(
    Failure failure, {
    String? userId,
    String? sessionId,
    Map<String, dynamic>? context,
  }) async {
    // Track error in analytics
    await _analyticsService.logEvent('error_occurred', {
      'error_type': failure.type.name,
      'error_severity': failure.severity.name,
      'error_code': failure.code,
      'error_message': failure.message,
      'should_retry': failure.shouldRetry,
      'user_id': userId,
      'session_id': sessionId,
      'timestamp': failure.timestamp.toIso8601String(),
      ...?context,
    });

    // Report critical errors to crash reporter
    if (failure.severity == ErrorSeverity.critical) {
      await _crashReporter.recordError(
        failure,
        null,
        reason: 'Critical error: ${failure.message}',
        information: context ?? {},
      );
    }
  }

  Future<void> trackErrorRecovery(
    Failure failure,
    ErrorRecoveryAction action,
    bool success,
  ) async {
    await _analyticsService.logEvent('error_recovery', {
      'error_type': failure.type.name,
      'recovery_type': action.type.name,
      'recovery_success': success,
      'auto_retry': action.shouldAutoRetry,
    });
  }
}
```

## 🎯 **SUCCESS METRICS**

### **Quantitative Targets**
- **Error Handling Uniformity**: 30% → 90%
- **User Error Feedback**: 60% → 95%
- **Error Recovery Rate**: 40% → 80%
- **Critical Error Reduction**: 50% reduction
- **Error Analytics Coverage**: 100%

### **Qualitative Improvements**
- **Consistent User Experience**: Unified error messages
- **Better Error Debugging**: Comprehensive error context
- **Improved Error Recovery**: Automatic retry mechanisms
- **Enhanced Monitoring**: Real-time error tracking

---

**Next**: Review `05_state_management_consolidation.md` for BLoC pattern standardization.

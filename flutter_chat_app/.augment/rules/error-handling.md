# Error Handling Rules
**Type:** Always  
**Description:** Comprehensive error handling for Flutter messaging apps

## Error Handling Strategy
- Use `Either<Failure, T>` pattern for all operations
- Never throw exceptions in business logic
- Create specific failure types for different errors
- Handle errors at appropriate layer
- Provide user-friendly error messages

## Failure Types
- `NetworkFailure`: Connection, timeout, server errors
- `AuthFailure`: Authentication, authorization errors
- `ValidationFailure`: Input validation errors
- `CacheFailure`: Local storage errors
- `UnknownFailure`: Unexpected errors

## Repository Layer
- Catch all exceptions from data sources
- Convert exceptions to appropriate failures
- Log technical details for debugging
- Return Either<Failure, T> from all methods
- Handle network connectivity issues

## BLoC Layer
- Handle failures from repositories
- Emit appropriate error states
- Don't let exceptions bubble up to UI
- Log errors with context
- Provide retry mechanisms

## UI Layer
- Display user-friendly error messages
- Show loading states during operations
- Provide retry buttons for failed operations
- Handle offline scenarios gracefully
- Use snackbars or dialogs for errors

## Network Errors
- Handle connection timeouts
- Retry with exponential backoff
- Show offline indicators
- Queue operations when offline
- Validate responses before processing

## Validation Errors
- Validate inputs at UI layer
- Show field-specific error messages
- Prevent invalid data submission
- Use form validation libraries
- Provide clear validation rules

## Logging
- Log errors with sufficient context
- Include stack traces for debugging
- Use different log levels appropriately
- Don't log sensitive information
- Use structured logging format

## Recovery Strategies
- Automatic retry for transient errors
- Manual retry options for users
- Fallback to cached data when possible
- Graceful degradation of features
- Clear error state when resolved

## Testing Error Scenarios
- Test all failure paths
- Mock error conditions
- Verify error messages
- Test retry mechanisms
- Test error state recovery

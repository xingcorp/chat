# Testing Standards Rules
**Type:** Always  
**Description:** Comprehensive testing standards for Flutter messaging apps

## Test Types
- **Unit Tests**: Business logic, utilities, models
- **Widget Tests**: UI components, user interactions
- **Integration Tests**: End-to-end user flows
- **Golden Tests**: Visual regression testing

## Test Structure
- Use AAA pattern: Arrange, Act, Assert
- One assertion per test
- Descriptive test names
- Group related tests together
- Use `setUp` and `tearDown` appropriately

## Unit Testing
- Test all business logic
- Mock external dependencies
- Test both success and failure cases
- Use `mockito` for mocking
- Test edge cases and boundary conditions

## Widget Testing
- Test widget rendering
- Test user interactions
- Test state changes
- Use `testWidgets` function
- Pump widgets and verify output

## BLoC Testing
- Test all events and states
- Mock repository dependencies
- Test loading, success, and error states
- Use `bloc_test` package
- Verify state transitions

## Repository Testing
- Test data source interactions
- Mock network and database calls
- Test caching behavior
- Test offline scenarios
- Verify error handling

## Test Coverage
- Aim for >80% code coverage
- Focus on critical business logic
- Don't test framework code
- Use `flutter test --coverage`
- Review coverage reports regularly

## Test Data
- Use factory patterns for test data
- Create realistic test scenarios
- Use builders for complex objects
- Keep test data consistent
- Avoid hardcoded values

## Mocking Guidelines
- Mock external dependencies only
- Don't mock value objects
- Use interfaces for mocking
- Verify mock interactions
- Reset mocks between tests

## Performance Testing
- Test app startup time
- Test memory usage
- Test scroll performance
- Test network request timing
- Use profiling tools

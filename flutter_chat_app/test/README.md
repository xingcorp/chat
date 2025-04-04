# Flutter Chat App Testing Framework

This document provides guidelines on how to use and extend the testing framework in the Flutter Chat App project.

## Table of Contents

1. [Testing Structure](#testing-structure)
2. [Types of Tests](#types-of-tests)
3. [Test Coverage](#test-coverage)
4. [Running Tests](#running-tests)
5. [Writing New Tests](#writing-new-tests)
6. [Best Practices](#best-practices)

## Testing Structure

The testing framework is organized into four main categories:

```
test/
├── unit/              # Unit tests for individual components
├── integration/       # Integration tests for component interactions
├── widget/            # Widget tests for UI components
├── performance/       # Benchmark tests for performance measurement
├── test_coverage_script.dart # Script to generate coverage reports
└── README.md          # This file
```

## Types of Tests

### Unit Tests

Unit tests focus on testing individual components in isolation, such as services, repositories, and utilities.

Example files:
- `socket_manager_test.dart`: Tests for the SocketManager class
- `socket_analytics_test.dart`: Tests for the SocketAnalytics class

### Integration Tests

Integration tests verify that different components work correctly together, such as blocs interacting with services.

Example file:
- `chat_flow_automation_test.dart`: Tests the complete chat flow from login to sending/receiving messages

### Widget Tests

Widget tests ensure that UI components render correctly and respond appropriately to user interactions.

Example file:
- `widget_test.dart`: Basic widget tests for Flutter widgets

### Performance Tests

Performance tests measure the efficiency and resource usage of critical components.

Example file:
- `enhanced_socket_manager_benchmark_test.dart`: Performance benchmarks for SocketManager

## Test Coverage

We use the `test_coverage_script.dart` to generate and analyze test coverage reports. This script:

1. Runs all tests with coverage enabled
2. Generates an HTML report for easy visualization
3. Calculates overall coverage percentage
4. Identifies files with low coverage (<50%)
5. Tracks coverage history to monitor improvements

To generate a coverage report:

```bash
dart test/test_coverage_script.dart
```

The report will be available at `coverage/html/index.html` and a summary at `coverage/coverage_summary.txt`.

## Running Tests

### Running All Tests

```bash
flutter test
```

### Running Specific Test Categories

```bash
# Run unit tests only
flutter test test/unit/

# Run integration tests
flutter test test/integration/

# Run widget tests
flutter test test/widget/

# Run performance tests
flutter test test/performance/
```

### Running Individual Test Files

```bash
flutter test test/unit/socket_manager_test.dart
```

## Writing New Tests

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_chat_app/core/network/socket_manager.dart';

@GenerateMocks([Dependency1, Dependency2])
import 'your_test_file.mocks.dart';

void main() {
  late YourClass yourClass;
  late MockDependency1 mockDependency1;

  setUp(() {
    mockDependency1 = MockDependency1();
    yourClass = YourClass(dependency1: mockDependency1);
  });

  group('YourClass Tests', () {
    test('should perform expected behavior', () {
      // Arrange
      when(mockDependency1.someMethod()).thenReturn(expectedValue);
      
      // Act
      final result = yourClass.methodToTest();
      
      // Assert
      expect(result, equals(expectedValue));
      verify(mockDependency1.someMethod()).called(1);
    });
  });
}
```

### Benchmark Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

class YourBenchmark extends BenchmarkBase {
  YourBenchmark() : super('YourBenchmarkName');
  
  @override
  void run() {
    // The code to measure
    for (int i = 0; i < 1000; i++) {
      yourFunctionToMeasure();
    }
  }
  
  @override
  void setup() {
    // Setup code that runs before the benchmark
  }
  
  @override
  void teardown() {
    // Cleanup code that runs after the benchmark
  }
}

void main() {
  test('performance benchmark', () {
    final benchmark = YourBenchmark();
    final score = benchmark.measure();
    print('Score: $score operations/second');
    expect(score, greaterThan(0));
  });
}
```

## Best Practices

1. **Mock Dependencies**: Always mock external dependencies to ensure tests are isolated and deterministic.

2. **Test Coverage**: Aim for at least 80% code coverage. Prioritize testing critical components like networking and data persistence.

3. **Test Structure**: Follow the Arrange-Act-Assert pattern to make tests clear and maintainable.

4. **Test Independence**: Each test should be independent and not rely on the state from other tests.

5. **Clear Test Names**: Use descriptive test names that explain what is being tested and the expected outcome.

6. **Code Generation**: Use `@GenerateMocks` to generate mock classes. After adding the annotation, run:
   ```bash
   flutter pub run build_runner build
   ```

7. **Performance Testing**: For benchmark tests, run multiple iterations and take the average to account for variability.

8. **Test Edge Cases**: Don't just test the happy path. Include tests for error scenarios, edge cases, and boundary conditions.

9. **Regular Testing**: Run tests regularly, ideally as part of your CI/CD pipeline.

10. **Keep Tests Up-to-Date**: When changing code, update or add tests to ensure the test suite remains useful.

## Adding Dependencies

Make sure these dependencies are in your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.3.3
  benchmark_harness: ^2.0.0
  test_coverage: ^0.5.0
```

After adding these dependencies, run:

```bash
flutter pub get
``` 
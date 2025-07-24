# Flutter Chat App Development Rules - Enterprise Standards

## Rule 1: Eliminate Hardcoded Values

### ❌ PROHIBITED
- Hardcoded strings, numbers, colors, dimensions directly in code
- Magic numbers without explanation
- Inline configuration values
- Direct color hex codes in widgets

### ✅ REQUIRED
- All literal values extracted into named constants
- Use centralized constant files:
  - `lib/core/constants/app_constants.dart` - Application configuration
  - `lib/core/constants/app_colors.dart` - Color palette
  - `lib/core/constants/app_dimensions.dart` - Spacing and sizing
- SCREAMING_SNAKE_CASE for primitive constants
- PascalCase for configuration classes

### Examples

```dart
// ❌ INCORRECT - Hardcoded values
Container(
  padding: EdgeInsets.all(16.0),
  color: Color(0xFF2196F3),
  child: Text(
    'Hello World',
    style: TextStyle(fontSize: 18.0),
  ),
)

// ✅ CORRECT - Using constants
Container(
  padding: EdgeInsets.all(AppDimensions.PADDING_DEFAULT),
  color: AppColors.PRIMARY_BLUE,
  child: Text(
    AppStrings.HELLO_WORLD,
    style: TextStyle(fontSize: AppTextStyles.BODY_LARGE_SIZE),
  ),
)
```

## Rule 2: Maximize Code Reusability

### ❌ PROHIBITED
- Duplicating similar functionality
- Copy-pasting code blocks
- Creating new components without checking existing ones
- Hardcoding common patterns

### ✅ REQUIRED
- Extract common patterns into mixins, extensions, or utility classes
- Use generic types and parameterized functions
- Create reusable components in `lib/core/utils/reusable_components.dart`
- Document reusable components with usage examples

### Examples

```dart
// ❌ INCORRECT - Duplicated loading logic
class ScreenA extends StatefulWidget {
  bool _isLoading = false;
  
  Widget build(BuildContext context) {
    return _isLoading 
        ? CircularProgressIndicator()
        : actualContent();
  }
}

// ✅ CORRECT - Using reusable mixin
class ScreenA extends StatefulWidget with LoadingStateMixin {
  Widget build(BuildContext context) {
    return buildLoadingOverlay(
      child: actualContent(),
    );
  }
}
```

## Rule 3: Mandatory Existing Code Analysis

### 🔍 BEFORE IMPLEMENTING ANY NEW FEATURE

1. **Search the entire codebase** for similar functionality:
   ```bash
   # Use code analysis helper
   dart run lib/core/tools/code_analysis_helper.dart
   ```

2. **Review related files** in the same domain/layer:
   - Check `lib/domain/` for similar entities/use cases
   - Check `lib/data/` for similar repositories/data sources
   - Check `lib/presentation/` for similar BLoCs/widgets

3. **Check utility classes** for applicable existing solutions:
   - `lib/core/utils/` - Utility functions and extensions
   - `lib/core/mixins/` - Reusable mixins
   - `lib/core/base/` - Base classes and interfaces

4. **Document findings** and justify why existing code cannot be reused

### Required Analysis Checklist

- [ ] Searched for similar class names
- [ ] Searched for similar function names
- [ ] Reviewed existing utilities and mixins
- [ ] Checked for similar patterns in the same layer
- [ ] Documented why existing code cannot be extended/reused
- [ ] Obtained code review approval for new implementation

## Rule 4: Implementation Standards

### Architecture Compliance
- Follow Clean Architecture layers: Domain ← Data → Presentation
- Apply SOLID principles in all implementations
- Use established error handling patterns (Either<Failure, T>)
- Maintain consistency with existing BLoC patterns

### Code Organization
```
lib/
├── core/                    # Core utilities and shared code
│   ├── constants/          # Centralized constants
│   ├── error/              # Error handling
│   ├── utils/              # Utility functions and extensions
│   └── base/               # Base classes
├── domain/                 # Business logic layer
│   ├── entities/           # Business entities
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Business use cases
├── data/                   # Data layer
│   ├── models/             # Data models
│   ├── repositories/       # Repository implementations
│   └── datasources/        # Data sources
└── presentation/           # UI layer
    ├── blocs/              # BLoC state management
    ├── widgets/            # Reusable widgets
    └── screens/            # Screen implementations
```

### Naming Conventions
- **Files**: snake_case.dart
- **Classes**: PascalCase
- **Functions/Variables**: camelCase
- **Constants**: SCREAMING_SNAKE_CASE
- **Private members**: _prefixWithUnderscore

## Rule 5: Validation Process

### Pre-Submission Checklist

#### 1. Automated Checks
```bash
# Check for hardcoded values
grep -r "Color(0x" lib/ --include="*.dart"
grep -r "'[^']*'" lib/ --include="*.dart" | grep -v "import\|export"

# Run code analysis
flutter analyze lib/

# Run tests
flutter test
```

#### 2. Code Review Requirements
- [ ] No hardcoded values found
- [ ] Existing code analysis completed and documented
- [ ] Reusable components utilized where applicable
- [ ] Clean Architecture compliance verified
- [ ] Error handling follows established patterns
- [ ] Tests written and passing
- [ ] Documentation updated

#### 3. Peer Review Focus Areas
- **Reusability**: Could this be extracted into a reusable component?
- **Existing Code**: Is there similar functionality already implemented?
- **Constants**: Are all literal values properly extracted?
- **Architecture**: Does this follow Clean Architecture principles?
- **Error Handling**: Is error handling consistent with existing patterns?

### Documentation Requirements

#### For New Reusable Components
```dart
/// **COMPONENT NAME - PURPOSE**
///
/// Professional component description:
/// - Key feature 1
/// - Key feature 2
/// - Performance characteristics
/// - Usage constraints
///
/// **Architecture:** Clean Architecture + Design Pattern
///
/// **Usage Examples:**
/// 
/// ```dart
/// // Example usage
/// final component = ComponentName(
///   parameter: AppConstants.SOME_VALUE,
/// );
/// ```
class ComponentName {
  // Implementation
}
```

#### For Constants
```dart
/// **CONSTANT CATEGORY - DESCRIPTION**
///
/// Professional constant description:
/// - Purpose and usage
/// - Related constants
/// - Performance implications
///
/// **Usage Examples:**
/// 
/// ```dart
/// // ✅ CORRECT
/// Container(color: AppColors.PRIMARY_BLUE)
/// 
/// // ❌ INCORRECT  
/// Container(color: Color(0xFF2196F3))
/// ```
static const Color PRIMARY_BLUE = Color(0xFF2196F3);
```

## Enforcement

### Automated Tools
- Pre-commit hooks to check for hardcoded values
- CI/CD pipeline validation
- Code analysis reports in pull requests

### Manual Review
- Mandatory peer review for all code changes
- Architecture review for new features
- Regular code quality audits

### Consequences
- **First Violation**: Code review feedback and education
- **Repeated Violations**: Additional training required
- **Persistent Issues**: Escalation to technical lead

## Benefits

### Code Quality
- Consistent codebase with unified standards
- Reduced technical debt
- Improved maintainability

### Development Efficiency
- Faster development through code reuse
- Reduced debugging time
- Easier onboarding for new developers

### Enterprise Readiness
- Scalable architecture
- Professional code standards
- Production-ready quality

---

**Remember**: These rules ensure our Flutter chat app maintains enterprise-grade quality and follows industry best practices. Every line of code should reflect professional standards worthy of production deployment.

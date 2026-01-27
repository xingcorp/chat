# Pull Request Template

## Description
<!-- Provide a brief description of the changes in this PR -->

## Related Issue/Task
<!-- Link to the related issue or task -->
- Task: #[task_number]
- Issue: #[issue_number]

## Type of Change
<!-- Mark the relevant option with an 'x' -->
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Refactoring (no functional changes)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Test coverage improvement

## Changes Made
<!-- List the main changes made in this PR -->
- 
- 
- 

## Testing Performed
<!-- Describe the testing you have performed -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed
- [ ] Tested on Android
- [ ] Tested on iOS
- [ ] Tested on Web

## Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## Code Review Checklist
<!-- Reviewer should verify all items -->

### Architecture Compliance
- [ ] Follows Clean Architecture principles
- [ ] No layer violations (Domain doesn't import Flutter/infrastructure)
- [ ] Presentation doesn't import Data models directly
- [ ] Proper dependency injection used

### Code Quality
- [ ] Code follows naming conventions (snake_case files, PascalCase classes)
- [ ] No relative imports (uses package imports)
- [ ] No `print()` statements (uses Logger)
- [ ] No hardcoded strings (uses l10n)
- [ ] No null assertion operator (`!`)
- [ ] No type casting with `as` (uses `is` checks)
- [ ] Proper null safety
- [ ] Uses `const` constructors where possible

### Error Handling
- [ ] Uses `Either<Failure, T>` for error handling
- [ ] Proper exception handling in data sources
- [ ] User-friendly error messages
- [ ] Errors logged appropriately

### State Management
- [ ] BLoC pattern used correctly
- [ ] Events and states use Freezed
- [ ] Proper event handling
- [ ] Loading states handled
- [ ] Error states handled

### Testing
- [ ] Unit tests added for new code
- [ ] Tests cover happy path
- [ ] Tests cover error cases
- [ ] Tests pass locally
- [ ] Test coverage maintained or improved

### Performance
- [ ] No performance regressions
- [ ] Efficient algorithms used
- [ ] Proper pagination implemented (if applicable)
- [ ] Images optimized (if applicable)
- [ ] No memory leaks

### Security
- [ ] No hardcoded credentials
- [ ] Input validation implemented
- [ ] Data sanitization implemented
- [ ] Secure storage used for sensitive data

### Documentation
- [ ] Public APIs documented
- [ ] Complex logic explained with comments
- [ ] README updated (if needed)
- [ ] CHANGELOG updated (if needed)

### Localization
- [ ] All UI strings use l10n
- [ ] Translations added for both English and Vietnamese
- [ ] No hardcoded text in UI

### CI/CD
- [ ] CI pipeline passes
- [ ] No linting errors
- [ ] All tests pass
- [ ] Build succeeds

## Additional Notes
<!-- Any additional information for reviewers -->

## Reviewer Notes
<!-- Reviewers can add notes here -->

---

**Developer Checklist:**
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

**Reviewer Checklist:**
- [ ] Code follows project architecture and patterns
- [ ] All checklist items verified
- [ ] No blocking issues found
- [ ] Approved for merge

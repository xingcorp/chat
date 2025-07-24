# Clean Code Rules
**Type:** Always  
**Description:** Clean code principles for readable, maintainable Flutter code

## General Rules
- Follow standard conventions
- Keep it simple - simpler is always better
- Boy scout rule: leave code cleaner than you found it
- Always find root cause of problems

## Naming Conventions
- Use descriptive and unambiguous names
- Make meaningful distinctions
- Use pronounceable names: `UserService` not `UsrSvc`
- Use searchable names: `MAX_USERS` not `100`
- Replace magic numbers with named constants
- Avoid encodings and prefixes

## Functions
- Keep functions small (<20 lines)
- Do one thing only
- Use descriptive names: `sendMessage()` not `process()`
- Prefer fewer arguments (max 3)
- Have no side effects
- Don't use flag arguments - split into separate methods

## Classes
- Single responsibility principle
- Small number of instance variables
- Hide internal structure
- Do one thing well
- Prefer composition over inheritance

## Comments
- Try to explain yourself in code first
- Don't be redundant
- Don't add obvious noise
- Don't comment out code - just remove it
- Use comments for explanation of intent
- Use comments as warning of consequences

## Code Structure
- Separate concepts vertically
- Related code should appear close together
- Declare variables close to their usage
- Dependent functions should be close
- Keep lines short (<120 characters)
- Use white space to associate related things

## Error Handling
- Use exceptions for exceptional cases
- Provide context with exceptions
- Don't return null - use Optional or Either
- Don't pass null as arguments
- Handle errors at appropriate level

## Testing
- One assert per test
- Tests should be readable
- Tests should be fast
- Tests should be independent
- Tests should be repeatable
- Follow AAA pattern: Arrange, Act, Assert

---
type: "agent_requested"
description: "Example description"
---
# SOLID Principles Rules
**Type:** Always  
**Description:** SOLID principles for object-oriented design in Flutter

## Single Responsibility Principle (SRP)
- A class should have only one reason to change
- Each class should do one thing well
- Separate concerns into different classes
- Example: `UserRepository` only handles user data, not validation

## Open/Closed Principle (OCP)
- Open for extension, closed for modification
- Use inheritance and polymorphism
- Add new functionality without changing existing code
- Example: Add new notification types without modifying base class

## Liskov Substitution Principle (LSP)
- Subtypes must be substitutable for their base types
- Derived classes must honor base class contracts
- Don't strengthen preconditions or weaken postconditions
- Example: All `Repository` implementations must work the same way

## Interface Segregation Principle (ISP)
- Many specific interfaces better than one general interface
- Clients shouldn't depend on interfaces they don't use
- Split large interfaces into smaller, focused ones
- Example: `Readable` and `Writable` instead of `DataAccess`

## Dependency Inversion Principle (DIP)
- Depend on abstractions, not concretions
- High-level modules shouldn't depend on low-level modules
- Both should depend on abstractions
- Use dependency injection
- Example: Service depends on `IRepository` interface, not concrete implementation

## Flutter Applications
- Use abstract classes for contracts
- Implement interfaces in data layer
- Inject dependencies through constructors
- Use `get_it` for service location
- Apply to BLoCs, repositories, and services

## Benefits
- Easier to test and mock
- More flexible and maintainable
- Reduced coupling between components
- Easier to extend and modify
- Better code organization

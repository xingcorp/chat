# Clean Architecture Rules
**Type:** Always  
**Description:** Clean Architecture principles for Flutter messaging apps

## Architecture Layers
- **Domain**: Pure business logic, no external dependencies
- **Data**: Repository implementations, data sources, models
- **Presentation**: UI, BLoC state management, widgets
- **External**: Frameworks, databases, web services, device APIs

## Dependency Rule
- Source code dependencies point inward only
- Inner layers know nothing about outer layers
- No names from outer circles in inner circles
- Data formats from outer layers not used in inner layers

## Domain Layer
- Contains enterprise business rules
- Entities encapsulate core business logic
- Use cases orchestrate data flow
- Abstract repository interfaces
- No framework dependencies

## Data Layer
- Implements repository interfaces from domain
- Contains data sources (local, remote)
- Handles data transformation
- Manages caching strategies
- Implements offline-first approach

## Presentation Layer
- Contains UI components and state management
- BLoC/Cubit for state management
- Widgets for UI rendering
- Depends on domain layer only
- No direct data layer dependencies

## Crossing Boundaries
- Use dependency inversion principle
- Pass simple data structures across boundaries
- Don't pass entities or database rows
- Use interfaces to invert dependencies
- Apply dependency injection

## Benefits
- Independent of frameworks
- Testable business rules
- Independent of UI
- Independent of database
- Independent of external agencies

## Flutter Specific
- Use `get_it` for dependency injection
- Use `freezed` for immutable data classes
- Use `either_dart` for error handling
- Use `injectable` for code generation
- Separate feature folders by domain

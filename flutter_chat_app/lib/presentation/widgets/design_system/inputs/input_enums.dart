/// **INPUT ENUMS**
///
/// Enumerations for input field states and validation modes.

/// Input field state
///
/// Defines the visual state of the input field.
enum InputState {
  /// Normal state - default appearance
  normal,

  /// Focused state - user is interacting with field
  focused,

  /// Error state - validation failed
  error,

  /// Disabled state - field is not interactive
  disabled,
}

/// Auto-validation mode for input fields
///
/// Determines when validation should occur.
enum InputAutovalidateMode {
  /// Never auto-validate
  disabled,

  /// Validate on every change
  always,

  /// Validate only after first interaction
  onUserInteraction,
}

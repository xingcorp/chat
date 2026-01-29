/// **BUTTON ENUMS**
///
/// Enumerations for button variants and sizes in the design system.

/// Button variant types
///
/// Defines the visual style of the button.
enum ButtonVariant {
  /// Primary button - filled with primary color
  primary,

  /// Secondary button - filled with secondary color
  secondary,

  /// Text button - no background, text only
  text,

  /// Outlined button - transparent background with border
  outlined,
}

/// Button size variants
///
/// Defines the height and padding of the button.
enum ButtonSize {
  /// Small button - 32dp height
  small,

  /// Medium button - 48dp height (default)
  medium,

  /// Large button - 56dp height
  large,
}

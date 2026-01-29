/// **FORM COMPONENT ENUMS**
///
/// Enum definitions for form input components in the design system.
library;

/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Centralized enum definitions
///
/// **Usage**:
/// ```dart
/// AppCheckbox(
///   size: CheckboxSize.medium,
///   value: true,
///   onChanged: (value) => print(value),
/// )
///
/// AppSlider(
///   type: SliderType.range,
///   values: RangeValues(20, 80),
///   onChanged: (values) => print(values),
/// )
/// ```

/// Checkbox size variants
enum CheckboxSize {
  /// Small checkbox: 16dp
  small,

  /// Medium checkbox: 20dp (default)
  medium,

  /// Large checkbox: 24dp
  large,
}

/// Radio button size variants
enum RadioButtonSize {
  /// Small radio button: 16dp
  small,

  /// Medium radio button: 20dp (default)
  medium,

  /// Large radio button: 24dp
  large,
}

/// Switch size variants
enum SwitchSize {
  /// Small switch: 32dp width
  small,

  /// Medium switch: 40dp width (default)
  medium,

  /// Large switch: 48dp width
  large,
}

/// Slider type variants
enum SliderType {
  /// Continuous slider (smooth values)
  continuous,

  /// Discrete slider (stepped values)
  discrete,
}

/// Dropdown menu position
enum DropdownPosition {
  /// Position dropdown below the trigger
  below,

  /// Position dropdown above the trigger
  above,

  /// Automatically position based on available space
  auto,
}

/// Rating component size variants
enum RatingSize {
  /// Small rating: 16dp per star
  small,

  /// Medium rating: 24dp per star (default)
  medium,

  /// Large rating: 32dp per star
  large,
}

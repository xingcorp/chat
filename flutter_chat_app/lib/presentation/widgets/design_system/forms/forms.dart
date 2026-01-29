/// **FORM COMPONENTS**
///
/// Barrel file exporting all form input components.
library;

/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Barrel export for clean imports
///
/// **Usage**:
/// ```dart
/// import 'package:flutter_chat_app/presentation/widgets/design_system/forms/forms.dart';
///
/// // All form components available
/// AppCheckbox(...)
/// AppRadioGroup(...)
/// AppSwitch(...)
/// ```

// Components
export 'app_checkbox.dart';
export 'app_date_picker.dart';
export 'app_dropdown.dart';
export 'app_radio_button.dart';
export 'app_rating.dart';
export 'app_slider.dart';
export 'app_switch.dart';
export 'app_time_picker.dart';
// Enums
export 'form_enums.dart';

# Technical Design: Enterprise Design System & Common Widgets

## 🏗️ Architecture Overview

### Design System Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart (existing)
│   │   └── app_dimens.dart (NEW - comprehensive dimensions)
│   ├── theme/
│   │   ├── app_theme.dart (existing - enhanced)
│   │   ├── app_colors.dart (existing)
│   │   ├── app_text_styles.dart (existing)
│   │   ├── app_theme_data.dart (NEW - theme configuration)
│   │   └── app_theme_extensions.dart (NEW - theme extensions)
│   └── base/
│       ├── base_widget.dart (existing)
│       ├── base_dialog.dart (NEW)
│       └── base_bottom_sheet.dart (NEW)
├── presentation/
│   └── widgets/
│       └── design_system/
│           ├── buttons/
│           │   ├── app_button.dart
│           │   ├── app_icon_button.dart
│           │   ├── app_floating_action_button.dart
│           │   └── button_enums.dart
│           ├── inputs/
│   │   ├── app_text_field.dart
│   │   ├── app_text_area.dart
│   │   ├── app_search_field.dart
│   │   ├── app_password_field.dart
│   │   └── input_enums.dart
│   ├── cards/
│   │   ├── app_card.dart
│   │   └── card_enums.dart
│   ├── lists/
│   │   ├── app_list_view.dart
│   │   ├── app_grid_view.dart
│   │   ├── app_list_tile.dart
│   │   └── app_expansion_tile.dart
│   ├── dialogs/
│   │   ├── app_dialog.dart
│   │   ├── app_alert_dialog.dart
│   │   ├── app_confirm_dialog.dart
│   │   ├── app_bottom_sheet.dart
│   │   └── app_modal_bottom_sheet.dart
│   ├── feedback/
│   │   ├── app_snack_bar.dart
│   │   ├── app_toast.dart
│   │   ├── app_banner.dart
│   │   ├── app_progress_indicator.dart
│   │   └── app_shimmer.dart
│   ├── navigation/
│   │   ├── app_app_bar.dart
│   │   ├── app_bottom_navigation_bar.dart
│   │   ├── app_tab_bar.dart
│   │   └── app_drawer.dart
│   ├── media/
│   │   ├── app_avatar.dart
│   │   ├── app_image.dart
│   │   └── app_icon.dart
│   ├── badges/
│   │   ├── app_badge.dart
│   │   ├── app_chip.dart
│   │   └── app_tag.dart
│   ├── dividers/
│   │   ├── app_divider.dart
│   │   ├── app_vertical_divider.dart
│   │   └── app_section_divider.dart
│   └── states/
│       ├── app_empty_state.dart
│       ├── app_error_state.dart
│       ├── app_no_connection.dart
│       └── app_no_data.dart
```

## 🎨 Core Design System Components

### 1. AppDimens - Comprehensive Dimension System

**Purpose**: Centralized dimension management for consistent spacing, sizing, and layout.

**File**: `lib/core/constants/app_dimens.dart`

```dart
/// **ENTERPRISE DIMENSION SYSTEM**
///
/// Comprehensive dimension constants following 8px grid system.
/// All dimensions are in logical pixels (dp/pt).
///
/// **Usage**:
/// ```dart
/// Container(
///   padding: EdgeInsets.all(AppDimens.paddingMedium),
///   margin: EdgeInsets.symmetric(horizontal: AppDimens.marginSmall),
/// )
/// ```
class AppDimens {
  AppDimens._(); // Private constructor

  // ============================================================================
  // SPACING SYSTEM (8px grid)
  // ============================================================================
  
  /// Extra small spacing: 4dp
  static const double spaceXSmall = 4.0;
  
  /// Small spacing: 8dp
  static const double spaceSmall = 8.0;
  
  /// Medium spacing: 16dp (base unit)
  static const double spaceMedium = 16.0;
  
  /// Large spacing: 24dp
  static const double spaceLarge = 24.0;
  
  /// Extra large spacing: 32dp
  static const double spaceXLarge = 32.0;
  
  /// Extra extra large spacing: 40dp
  static const double spaceXXLarge = 40.0;
  
  /// Huge spacing: 48dp
  static const double spaceHuge = 48.0;

  // ============================================================================
  // PADDING SYSTEM
  // ============================================================================
  
  /// Extra small padding: 4dp
  static const double paddingXSmall = 4.0;
  
  /// Small padding: 8dp
  static const double paddingSmall = 8.0;
  
  /// Medium padding: 16dp (default)
  static const double paddingMedium = 16.0;
  
  /// Large padding: 24dp
  static const double paddingLarge = 24.0;
  
  /// Extra large padding: 32dp
  static const double paddingXLarge = 32.0;
  
  /// Screen edge padding: 16dp
  static const double paddingScreen = 16.0;
  
  /// Card padding: 16dp
  static const double paddingCard = 16.0;
  
  /// Dialog padding: 24dp
  static const double paddingDialog = 24.0;
  
  /// Bottom sheet padding: 16dp
  static const double paddingBottomSheet = 16.0;

  // ============================================================================
  // MARGIN SYSTEM
  // ============================================================================
  
  /// Extra small margin: 4dp
  static const double marginXSmall = 4.0;
  
  /// Small margin: 8dp
  static const double marginSmall = 8.0;
  
  /// Medium margin: 16dp (default)
  static const double marginMedium = 16.0;
  
  /// Large margin: 24dp
  static const double marginLarge = 24.0;
  
  /// Extra large margin: 32dp
  static const double marginXLarge = 32.0;

  // ============================================================================
  // BORDER RADIUS SYSTEM
  // ============================================================================
  
  /// No radius: 0dp
  static const double radiusNone = 0.0;
  
  /// Extra small radius: 4dp
  static const double radiusXSmall = 4.0;
  
  /// Small radius: 8dp
  static const double radiusSmall = 8.0;
  
  /// Medium radius: 12dp (default)
  static const double radiusMedium = 12.0;
  
  /// Large radius: 16dp
  static const double radiusLarge = 16.0;
  
  /// Extra large radius: 20dp
  static const double radiusXLarge = 20.0;
  
  /// Circular radius: 100dp
  static const double radiusCircular = 100.0;
  
  /// Button radius: 8dp
  static const double radiusButton = 8.0;
  
  /// Card radius: 12dp
  static const double radiusCard = 12.0;
  
  /// Dialog radius: 16dp
  static const double radiusDialog = 16.0;
  
  /// Bottom sheet radius: 16dp
  static const double radiusBottomSheet = 16.0;

  // ============================================================================
  // ELEVATION SYSTEM
  // ============================================================================
  
  /// No elevation: 0dp
  static const double elevationNone = 0.0;
  
  /// Small elevation: 2dp
  static const double elevationSmall = 2.0;
  
  /// Medium elevation: 4dp
  static const double elevationMedium = 4.0;
  
  /// Large elevation: 8dp
  static const double elevationLarge = 8.0;
  
  /// Extra large elevation: 16dp
  static const double elevationXLarge = 16.0;
  
  /// Button elevation: 2dp
  static const double elevationButton = 2.0;
  
  /// Card elevation: 2dp
  static const double elevationCard = 2.0;
  
  /// Dialog elevation: 24dp
  static const double elevationDialog = 24.0;
  
  /// Bottom sheet elevation: 16dp
  static const double elevationBottomSheet = 16.0;

  // ============================================================================
  // ICON SIZES
  // ============================================================================
  
  /// Extra small icon: 16dp
  static const double iconXSmall = 16.0;
  
  /// Small icon: 20dp
  static const double iconSmall = 20.0;
  
  /// Medium icon: 24dp (default)
  static const double iconMedium = 24.0;
  
  /// Large icon: 32dp
  static const double iconLarge = 32.0;
  
  /// Extra large icon: 48dp
  static const double iconXLarge = 48.0;

  // ============================================================================
  // BUTTON SIZES
  // ============================================================================
  
  /// Small button height: 32dp
  static const double buttonHeightSmall = 32.0;
  
  /// Medium button height: 48dp (default)
  static const double buttonHeightMedium = 48.0;
  
  /// Large button height: 56dp
  static const double buttonHeightLarge = 56.0;
  
  /// Button min width: 64dp
  static const double buttonMinWidth = 64.0;
  
  /// Icon button size: 48dp
  static const double iconButtonSize = 48.0;
  
  /// FAB size: 56dp
  static const double fabSize = 56.0;
  
  /// Mini FAB size: 40dp
  static const double fabSizeMini = 40.0;

  // ============================================================================
  // AVATAR SIZES
  // ============================================================================
  
  /// Extra small avatar: 24dp
  static const double avatarXSmall = 24.0;
  
  /// Small avatar: 32dp
  static const double avatarSmall = 32.0;
  
  /// Medium avatar: 40dp (default)
  static const double avatarMedium = 40.0;
  
  /// Large avatar: 56dp
  static const double avatarLarge = 56.0;
  
  /// Extra large avatar: 80dp
  static const double avatarXLarge = 80.0;
  
  /// Huge avatar: 120dp
  static const double avatarHuge = 120.0;

  // ============================================================================
  // INPUT SIZES
  // ============================================================================
  
  /// Input height: 48dp
  static const double inputHeight = 48.0;
  
  /// Input min height: 48dp
  static const double inputMinHeight = 48.0;
  
  /// Text area min height: 96dp
  static const double textAreaMinHeight = 96.0;

  // ============================================================================
  // TOUCH TARGETS
  // ============================================================================
  
  /// Minimum touch target: 48dp (Material Design guideline)
  static const double touchTargetMin = 48.0;
  
  /// Recommended touch target: 48dp
  static const double touchTarget = 48.0;

  // ============================================================================
  // DIVIDER SIZES
  // ============================================================================
  
  /// Thin divider: 1dp
  static const double dividerThin = 1.0;
  
  /// Medium divider: 2dp
  static const double dividerMedium = 2.0;
  
  /// Thick divider: 4dp
  static const double dividerThick = 4.0;

  // ============================================================================
  // APP BAR SIZES
  // ============================================================================
  
  /// App bar height: 56dp
  static const double appBarHeight = 56.0;
  
  /// Bottom navigation bar height: 56dp
  static const double bottomNavBarHeight = 56.0;
  
  /// Tab bar height: 48dp
  static const double tabBarHeight = 48.0;

  // ============================================================================
  // DIALOG & BOTTOM SHEET SIZES
  // ============================================================================
  
  /// Dialog max width: 560dp
  static const double dialogMaxWidth = 560.0;
  
  /// Dialog min width: 280dp
  static const double dialogMinWidth = 280.0;
  
  /// Bottom sheet max height ratio: 0.9 (90% of screen)
  static const double bottomSheetMaxHeightRatio = 0.9;
  
  /// Bottom sheet peek height: 56dp
  static const double bottomSheetPeekHeight = 56.0;

  // ============================================================================
  // LIST ITEM SIZES
  // ============================================================================
  
  /// List tile height: 56dp
  static const double listTileHeight = 56.0;
  
  /// List tile dense height: 48dp
  static const double listTileDenseHeight = 48.0;
  
  /// List tile three line height: 88dp
  static const double listTileThreeLineHeight = 88.0;

  // ============================================================================
  // BADGE SIZES
  // ============================================================================
  
  /// Small badge: 16dp
  static const double badgeSmall = 16.0;
  
  /// Medium badge: 20dp
  static const double badgeMedium = 20.0;
  
  /// Large badge: 24dp
  static const double badgeLarge = 24.0;

  // ============================================================================
  // CHIP SIZES
  // ============================================================================
  
  /// Chip height: 32dp
  static const double chipHeight = 32.0;
  
  /// Chip avatar size: 24dp
  static const double chipAvatarSize = 24.0;

  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================
  
  /// Mobile breakpoint: 600dp
  static const double breakpointMobile = 600.0;
  
  /// Tablet breakpoint: 900dp
  static const double breakpointTablet = 900.0;
  
  /// Desktop breakpoint: 1200dp
  static const double breakpointDesktop = 1200.0;
  
  /// Large desktop breakpoint: 1600dp
  static const double breakpointLargeDesktop = 1600.0;

  // ============================================================================
  // ANIMATION DURATIONS (milliseconds)
  // ============================================================================
  
  /// Fast animation: 150ms
  static const int durationFast = 150;
  
  /// Medium animation: 300ms (default)
  static const int durationMedium = 300;
  
  /// Slow animation: 500ms
  static const int durationSlow = 500;
  
  /// Page transition: 350ms
  static const int durationPageTransition = 350;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get responsive padding based on screen width
  static double getResponsivePadding(double screenWidth) {
    if (screenWidth >= breakpointDesktop) {
      return paddingXLarge;
    } else if (screenWidth >= breakpointTablet) {
      return paddingLarge;
    } else {
      return paddingMedium;
    }
  }
  
  /// Get responsive margin based on screen width
  static double getResponsiveMargin(double screenWidth) {
    if (screenWidth >= breakpointDesktop) {
      return marginXLarge;
    } else if (screenWidth >= breakpointTablet) {
      return marginLarge;
    } else {
      return marginMedium;
    }
  }
  
  /// Check if screen is mobile
  static bool isMobile(double screenWidth) => screenWidth < breakpointMobile;
  
  /// Check if screen is tablet
  static bool isTablet(double screenWidth) => 
      screenWidth >= breakpointMobile && screenWidth < breakpointDesktop;
  
  /// Check if screen is desktop
  static bool isDesktop(double screenWidth) => screenWidth >= breakpointDesktop;
}
```

### 2. BaseDialog - Base Class for All Dialogs

**Purpose**: Standardized dialog implementation with consistent styling and behavior.

**File**: `lib/core/base/base_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// **BASE DIALOG**
///
/// Base class for all dialogs in the application.
/// Provides consistent styling, animations, and behavior.
///
/// **Features**:
/// - Consistent padding and radius
/// - Dark mode support
/// - Accessibility support
/// - Customizable barrier
/// - Safe area handling
///
/// **Usage**:
/// ```dart
/// class MyDialog extends BaseDialog {
///   @override
///   Widget buildContent(BuildContext context) {
///     return Column(
///       children: [
///         Text('Dialog Content'),
///       ],
///     );
///   }
/// }
///
/// // Show dialog
/// await BaseDialog.show(
///   context,
///   builder: (context) => MyDialog(),
/// );
/// ```
abstract class BaseDialog extends StatelessWidget {
  const BaseDialog({
    super.key,
    this.title,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    this.actions,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.insetPadding,
    this.clipBehavior = Clip.antiAlias,
    this.scrollable = false,
  });

  /// Dialog title widget
  final Widget? title;

  /// Padding around title
  final EdgeInsetsGeometry? titlePadding;

  /// Padding around content
  final EdgeInsetsGeometry? contentPadding;

  /// Padding around actions
  final EdgeInsetsGeometry? actionsPadding;

  /// Action buttons
  final List<Widget>? actions;

  /// Background color
  final Color? backgroundColor;

  /// Elevation
  final double? elevation;

  /// Shape
  final ShapeBorder? shape;

  /// Inset padding
  final EdgeInsets? insetPadding;

  /// Clip behavior
  final Clip clipBehavior;

  /// Whether content is scrollable
  final bool scrollable;

  /// Build dialog content
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.surfaceDarkMode : AppColors.surface),
      elevation: elevation ?? AppDimens.elevationDialog,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusDialog),
          ),
      insetPadding: insetPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingLarge,
          ),
      clipBehavior: clipBehavior,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimens.dialogMaxWidth,
          minWidth: AppDimens.dialogMinWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: titlePadding ??
                    const EdgeInsets.fromLTRB(
                      AppDimens.paddingDialog,
                      AppDimens.paddingDialog,
                      AppDimens.paddingDialog,
                      AppDimens.paddingSmall,
                    ),
                child: DefaultTextStyle(
                  style: theme.textTheme.titleLarge!,
                  child: title!,
                ),
              ),
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingDialog,
                            vertical: AppDimens.paddingSmall,
                          ),
                      child: buildContent(context),
                    )
                  : Padding(
                      padding: contentPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingDialog,
                            vertical: AppDimens.paddingSmall,
                          ),
                      child: buildContent(context),
                    ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: actionsPadding ??
                    const EdgeInsets.fromLTRB(
                      AppDimens.paddingDialog,
                      AppDimens.paddingSmall,
                      AppDimens.paddingDialog,
                      AppDimens.paddingDialog,
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show dialog with standard configuration
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
    );
  }
}
```

### 3. BaseBottomSheet - Base Class for All Bottom Sheets

**Purpose**: Standardized bottom sheet implementation with consistent styling.

**File**: `lib/core/base/base_bottom_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';

/// **BASE BOTTOM SHEET**
///
/// Base class for all bottom sheets in the application.
/// Provides consistent styling, animations, and behavior.
///
/// **Features**:
/// - Consistent padding and radius
/// - Dark mode support
/// - Drag handle
/// - Safe area handling
/// - Scrollable content
///
/// **Usage**:
/// ```dart
/// class MyBottomSheet extends BaseBottomSheet {
///   @override
///   Widget buildContent(BuildContext context) {
///     return Column(
///       children: [
///         Text('Bottom Sheet Content'),
///       ],
///     );
///   }
/// }
///
/// // Show bottom sheet
/// await BaseBottomSheet.show(
///   context,
///   builder: (context) => MyBottomSheet(),
/// );
/// ```
abstract class BaseBottomSheet extends StatelessWidget {
  const BaseBottomSheet({
    super.key,
    this.title,
    this.showDragHandle = true,
    this.showCloseButton = false,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.padding,
    this.isScrollControlled = true,
    this.enableDrag = true,
  });

  /// Bottom sheet title
  final Widget? title;

  /// Show drag handle at top
  final bool showDragHandle;

  /// Show close button
  final bool showCloseButton;

  /// Background color
  final Color? backgroundColor;

  /// Elevation
  final double? elevation;

  /// Shape
  final ShapeBorder? shape;

  /// Content padding
  final EdgeInsetsGeometry? padding;

  /// Whether bottom sheet is scroll controlled
  final bool isScrollControlled;

  /// Whether bottom sheet can be dragged
  final bool enableDrag;

  /// Build bottom sheet content
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.surfaceDarkMode : AppColors.surface),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            if (showDragHandle)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: AppDimens.paddingSmall,
                  ),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.dividerDarkMode
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // Header with title and close button
            if (title != null || showCloseButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.paddingBottomSheet,
                  AppDimens.paddingSmall,
                  AppDimens.paddingBottomSheet,
                  AppDimens.paddingSmall,
                ),
                child: Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: DefaultTextStyle(
                          style: theme.textTheme.titleLarge!,
                          child: title!,
                        ),
                      ),
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                  ],
                ),
              ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: padding ??
                    const EdgeInsets.fromLTRB(
                      AppDimens.paddingBottomSheet,
                      0,
                      AppDimens.paddingBottomSheet,
                      AppDimens.paddingBottomSheet,
                    ),
                child: buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show modal bottom sheet with standard configuration
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
    );
  }

  /// Show persistent bottom sheet
  static PersistentBottomSheetController<T> showPersistent<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool enableDrag = true,
    AnimationController? transitionAnimationController,
  }) {
    return showBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      enableDrag: enableDrag,
      transitionAnimationController: transitionAnimationController,
    );
  }
}
```

## 🎨 Design Patterns

### 1. Base Class Pattern

**All widgets MUST extend base classes:**

```dart
// Stateless widgets
class AppButton extends BaseStatelessWidget {
  const AppButton({super.key, required this.text});
  
  final String text;
  
  @override
  Widget buildContent(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

// Stateful widgets
class AppTextField extends BaseStatefulWidget {
  const AppTextField({super.key});
  
  @override
  AppTextFieldState createState() => AppTextFieldState();
}

class AppTextFieldState extends BaseState<AppTextField> {
  @override
  void onAppResumed() {
    // Handle app resume
  }
  
  void _updateValue() {
    safeSetState(() {
      // Update state safely
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField();
  }
}
```

### 2. Named Constructor Pattern

**Use named constructors for variants:**

```dart
class AppButton extends BaseStatelessWidget {
  const AppButton._({
    super.key,
    required this.text,
    required this.onPressed,
    required this.variant,
    required this.size,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });
  
  // Named constructors for variants
  const AppButton.primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) : this._(
    key: key,
    text: text,
    onPressed: onPressed,
    variant: ButtonVariant.primary,
    size: size,
    icon: icon,
    isLoading: isLoading,
    isFullWidth: isFullWidth,
  );
  
  const AppButton.secondary({...}) : this._(...);
  const AppButton.text({...}) : this._(...);
  const AppButton.outlined({...}) : this._(...);
  const AppButton.icon({...}) : this._(...);
  
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  
  @override
  Widget buildContent(BuildContext context) {
    // Implementation
  }
}
```

### 3. Enum-Based Configuration

**Use enums for variants and states:**

```dart
enum ButtonVariant {
  primary,
  secondary,
  text,
  outlined,
  icon,
}

enum ButtonSize {
  small,
  medium,
  large,
}

enum InputState {
  normal,
  focused,
  error,
  disabled,
}
```

### 4. Theme-Aware Pattern

**Components adapt to theme automatically:**

```dart
@override
Widget buildContent(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  final backgroundColor = isDark 
      ? AppColors.surfaceDarkMode 
      : AppColors.surface;
  
  final textColor = isDark
      ? AppColors.textPrimaryDarkMode
      : AppColors.textPrimary;
  
  return Container(
    color: backgroundColor,
    child: Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(color: textColor),
    ),
  );
}
```

### 6. Enhanced Theme System

**Purpose**: Comprehensive theme management with extensions and custom properties.

**File**: `lib/core/theme/app_theme_data.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';

/// **ENHANCED THEME DATA**
///
/// Provides comprehensive theme configuration with custom extensions.
class AppThemeData {
  AppThemeData._();

  /// Light theme data
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        backgroundColor: AppColors.background,
        surfaceColor: AppColors.surface,
        textPrimaryColor: AppColors.textPrimary,
        textSecondaryColor: AppColors.textSecondary,
      );

  /// Dark theme data
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        backgroundColor: AppColors.backgroundDarkMode,
        surfaceColor: AppColors.surfaceDarkMode,
        textPrimaryColor: AppColors.textPrimaryDarkMode,
        textSecondaryColor: AppColors.textSecondaryDarkMode,
      );

  /// Build theme with custom configuration
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
      background: backgroundColor,
      onBackground: textPrimaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      
      // Typography
      textTheme: _buildTextTheme(textPrimaryColor, textSecondaryColor),
      primaryTextTheme: _buildTextTheme(textPrimaryColor, textSecondaryColor),
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: AppDimens.elevationNone,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading5(color: textPrimaryColor),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: AppDimens.elevationMedium,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: AppDimens.elevationButton,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          minimumSize: const Size(
            AppDimens.buttonMinWidth,
            AppDimens.buttonHeightMedium,
          ),
          textStyle: AppTextStyles.buttonMedium(),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          minimumSize: const Size(
            AppDimens.buttonMinWidth,
            AppDimens.buttonHeightMedium,
          ),
          textStyle: AppTextStyles.buttonMedium(),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: AppDimens.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
          ),
          minimumSize: const Size(
            AppDimens.buttonMinWidth,
            AppDimens.buttonHeightMedium,
          ),
          textStyle: AppTextStyles.buttonMedium(),
        ),
      ),
      
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimaryColor,
          minimumSize: const Size(
            AppDimens.iconButtonSize,
            AppDimens.iconButtonSize,
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: AppDimens.elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
            ? AppColors.inputBackgroundDarkMode 
            : AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textHintDarkMode : AppColors.textHint,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: AppDimens.elevationCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(AppDimens.marginSmall),
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: AppDimens.elevationDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusDialog),
        ),
        titleTextStyle: AppTextStyles.heading4(color: textPrimaryColor),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textPrimaryColor),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: AppDimens.elevationBottomSheet,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusBottomSheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDarkMode : Colors.grey[800],
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
        elevation: AppDimens.elevationMedium,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDarkMode : AppColors.divider,
        thickness: AppDimens.dividerThin,
        space: AppDimens.dividerThin,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withOpacity(0.2),
        disabledColor: surfaceColor.withOpacity(0.5),
        labelStyle: AppTextStyles.bodySmall.copyWith(color: textPrimaryColor),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSmall,
          vertical: AppDimens.paddingXSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        ),
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
        ),
        minVerticalPadding: AppDimens.paddingSmall,
        iconColor: textPrimaryColor,
        textColor: textPrimaryColor,
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(color: textPrimaryColor),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: textSecondaryColor),
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: backgroundColor,
        linearTrackColor: backgroundColor,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey[400] : Colors.grey[50];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return isDark ? Colors.grey[700] : Colors.grey[300];
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXSmall),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.3),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
      ),
    );
  }

  /// Build text theme
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: AppTextStyles.heading1(color: primaryColor),
      displayMedium: AppTextStyles.heading2(color: primaryColor),
      displaySmall: AppTextStyles.heading3(color: primaryColor),
      headlineLarge: AppTextStyles.heading4(color: primaryColor),
      headlineMedium: AppTextStyles.heading5(color: primaryColor),
      headlineSmall: AppTextStyles.heading5(color: primaryColor),
      titleLarge: AppTextStyles.heading5(color: primaryColor),
      titleMedium: AppTextStyles.bodyLargeCustom(
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: AppTextStyles.bodyMediumCustom(
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primaryColor),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primaryColor),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primaryColor),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondaryColor),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: secondaryColor),
    );
  }
}
```

**File**: `lib/core/theme/app_theme_extensions.dart`

```dart
import 'package:flutter/material.dart';

/// **THEME EXTENSIONS**
///
/// Custom theme extensions for additional properties.
class AppThemeExtensions extends ThemeExtension<AppThemeExtensions> {
  const AppThemeExtensions({
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.onlineColor,
    required this.awayColor,
    required this.offlineColor,
  });

  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final Color onlineColor;
  final Color awayColor;
  final Color offlineColor;

  @override
  ThemeExtension<AppThemeExtensions> copyWith({
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Color? onlineColor,
    Color? awayColor,
    Color? offlineColor,
  }) {
    return AppThemeExtensions(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      onlineColor: onlineColor ?? this.onlineColor,
      awayColor: awayColor ?? this.awayColor,
      offlineColor: offlineColor ?? this.offlineColor,
    );
  }

  @override
  ThemeExtension<AppThemeExtensions> lerp(
    ThemeExtension<AppThemeExtensions>? other,
    double t,
  ) {
    if (other is! AppThemeExtensions) {
      return this;
    }
    return AppThemeExtensions(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      onlineColor: Color.lerp(onlineColor, other.onlineColor, t)!,
      awayColor: Color.lerp(awayColor, other.awayColor, t)!,
      offlineColor: Color.lerp(offlineColor, other.offlineColor, t)!,
    );
  }

  /// Light theme extensions
  static const light = AppThemeExtensions(
    successColor: Color(0xFF4CAF50),
    warningColor: Color(0xFFFFC107),
    infoColor: Color(0xFF2196F3),
    onlineColor: Color(0xFF4CAF50),
    awayColor: Color(0xFFFFC107),
    offlineColor: Color(0xFF9E9E9E),
  );

  /// Dark theme extensions
  static const dark = AppThemeExtensions(
    successColor: Color(0xFF66BB6A),
    warningColor: Color(0xFFFFCA28),
    infoColor: Color(0xFF42A5F5),
    onlineColor: Color(0xFF66BB6A),
    awayColor: Color(0xFFFFCA28),
    offlineColor: Color(0xFFBDBDBD),
  );
}

/// Extension to access custom theme properties
extension ThemeExtensionsGetter on ThemeData {
  AppThemeExtensions get appExtensions =>
      extension<AppThemeExtensions>() ?? AppThemeExtensions.light;
}
```

### 5. Responsive Pattern

**Components adapt to screen size:**

```dart
@override
Widget buildContent(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= 600;
  final isDesktop = screenWidth >= 1200;
  
  final padding = isDesktop
      ? AppConstants.kLargePadding
      : isTablet
          ? AppConstants.kDefaultPadding
          : AppConstants.kSmallPadding;
  
  return Container(
    padding: EdgeInsets.all(padding),
    child: child,
  );
}
```

## 🎯 Component Design Specifications

### AppButton

**API Design:**
```dart
class AppButton extends BaseStatelessWidget {
  // Named constructors
  const AppButton.primary({...});
  const AppButton.secondary({...});
  const AppButton.text({...});
  const AppButton.outlined({...});
  const AppButton.icon({...});
  
  // Properties
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final bool isEnabled;
  
  // Computed properties
  bool get _isDisabled => !isEnabled || onPressed == null;
  
  // Build methods
  @override
  Widget buildContent(BuildContext context);
  
  Widget _buildButton(BuildContext context);
  Widget _buildContent(BuildContext context);
  Widget _buildLoadingIndicator();
  
  // Style methods
  ButtonStyle _getButtonStyle(BuildContext context);
  Color _getBackgroundColor(BuildContext context);
  Color _getForegroundColor(BuildContext context);
  EdgeInsets _getPadding();
  double _getHeight();
}
```

**States:**
- Default: Normal appearance
- Hover: Slightly lighter (web/desktop)
- Pressed: Darker shade
- Disabled: Reduced opacity, no interaction
- Loading: Shows spinner, disabled interaction

**Accessibility:**
```dart
Semantics(
  button: true,
  enabled: !_isDisabled,
  label: text,
  onTap: _isDisabled ? null : onPressed,
  child: button,
)
```

### AppTextField

**API Design:**
```dart
class AppTextField extends BaseStatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.maxLines = 1,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.autovalidateMode,
  });
  
  // Properties
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final int maxLines;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final AutovalidateMode? autovalidateMode;
}

class AppTextFieldState extends BaseState<AppTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }
  
  void _handleFocusChange() {
    safeSetState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }
  
  void _validate() {
    if (widget.validator != null) {
      safeSetState(() {
        _errorText = widget.validator!(_controller.text);
      });
    }
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: _buildDecoration(context),
      // ... other properties
    );
  }
  
  InputDecoration _buildDecoration(BuildContext context) {
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      helperText: widget.helperText,
      errorText: _errorText ?? widget.errorText,
      prefixIcon: widget.prefixIcon != null 
          ? Icon(widget.prefixIcon) 
          : null,
      suffixIcon: widget.suffixIcon,
      // Use theme decoration
    );
  }
}
```

**States:**
- Normal: Default appearance
- Focused: Border color changes, label animates
- Error: Red border, error text shown
- Disabled: Reduced opacity, no interaction

**Validation:**
```dart
// Built-in validators
class EmailValidator {
  String? call(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }
}

class PasswordValidator {
  PasswordValidator({this.minLength = 8});
  
  final int minLength;
  
  String? call(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }
}
```

### AppListView

**API Design:**
```dart
class AppListView<T> extends BaseStatefulWidget {
  const AppListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.onLoadMore,
    this.emptyState,
    this.loadingState,
    this.errorState,
    this.separatorBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });
  
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final Widget? emptyState;
  final Widget? loadingState;
  final Widget? errorState;
  final Widget Function(BuildContext, int)? separatorBuilder;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
}

class AppListViewState<T> extends BaseState<AppListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }
  
  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }
  
  Future<void> _loadMore() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;
    
    safeSetState(() {
      _isLoadingMore = true;
    });
    
    try {
      await widget.onLoadMore!();
    } finally {
      safeSetState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyState ?? _buildDefaultEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: widget.items.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: widget.separatorBuilder ?? 
            (context, index) => const Divider(),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return _buildLoadingIndicator();
          }
          return widget.itemBuilder(context, widget.items[index]);
        },
      ),
    );
  }
  
  Widget _buildDefaultEmptyState() {
    return AppEmptyState(
      message: context.l10n.noData,
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.kDefaultPadding),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

## 🎨 Design Tokens

### Colors
```dart
// Use AppColors for all colors
AppColors.primary
AppColors.secondary
AppColors.error
AppColors.success
AppColors.warning
AppColors.info

// Theme-aware
AppColors.textPrimary (light mode)
AppColors.textPrimaryDarkMode (dark mode)
```

### Typography
```dart
// Use AppTextStyles for all text
AppTextStyles.heading1()
AppTextStyles.heading2()
AppTextStyles.bodyLarge
AppTextStyles.bodyMedium
AppTextStyles.buttonLarge()
```

### Spacing
```dart
// Use AppConstants for all spacing
AppConstants.kSmallPadding // 8.0
AppConstants.kDefaultPadding // 16.0
AppConstants.kLargePadding // 24.0
AppConstants.kExtraLargePadding // 32.0
```

### Border Radius
```dart
AppConstants.kSmallBorderRadius // 8.0
AppConstants.kDefaultBorderRadius // 12.0
AppConstants.kLargeBorderRadius // 16.0
AppConstants.kCircularBorderRadius // 100.0
```

### Durations
```dart
AppConstants.kFastAnimationDuration // 150ms
AppConstants.kDefaultAnimationDuration // 300ms
AppConstants.kSlowAnimationDuration // 500ms
```

## ♿ Accessibility Implementation

### Semantic Labels
```dart
Semantics(
  label: 'Save button',
  button: true,
  enabled: !isDisabled,
  onTap: isDisabled ? null : onPressed,
  child: button,
)
```

### Touch Targets
```dart
// Minimum 48x48
Container(
  constraints: const BoxConstraints(
    minWidth: AppConstants.kTouchTargetSize,
    minHeight: AppConstants.kTouchTargetSize,
  ),
  child: child,
)
```

### Focus Management
```dart
Focus(
  focusNode: _focusNode,
  onFocusChange: _handleFocusChange,
  child: widget,
)
```

### Screen Reader Announcements
```dart
SemanticsService.announce(
  context.l10n.messageSent,
  TextDirection.ltr,
);
```

## 🧪 Testing Strategy

### Unit Tests
```dart
group('AppButton', () {
  test('creates primary button', () {
    final button = AppButton.primary(
      text: 'Save',
      onPressed: () {},
    );
    
    expect(button.variant, ButtonVariant.primary);
    expect(button.text, 'Save');
  });
  
  test('disables button when onPressed is null', () {
    final button = AppButton.primary(
      text: 'Save',
      onPressed: null,
    );
    
    expect(button.onPressed, isNull);
  });
});
```

### Widget Tests
```dart
testWidgets('AppButton renders correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppButton.primary(
          text: 'Save',
          onPressed: () {},
        ),
      ),
    ),
  );
  
  expect(find.text('Save'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});

testWidgets('AppButton handles tap', (tester) async {
  var tapped = false;
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppButton.primary(
          text: 'Save',
          onPressed: () => tapped = true,
        ),
      ),
    ),
  );
  
  await tester.tap(find.byType(AppButton));
  await tester.pump();
  
  expect(tapped, isTrue);
});
```

### Golden Tests
```dart
testWidgets('AppButton golden test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            AppButton.primary(text: 'Primary', onPressed: () {}),
            AppButton.secondary(text: 'Secondary', onPressed: () {}),
            AppButton.text(text: 'Text', onPressed: () {}),
          ],
        ),
      ),
    ),
  );
  
  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile('goldens/app_button.png'),
  );
});
```

## 📦 Package Dependencies

### Required Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  
  # DI
  injectable: ^2.3.2
  get_it: ^7.6.4
  
  # Functional Programming
  dartz: ^0.10.1
  
  # Code Generation
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Utils
  logger: ^2.0.2
  intl: ^0.18.1

dev_dependencies:
  # Testing
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  bloc_test: ^9.1.5
  
  # Code Generation
  build_runner: ^2.4.6
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  injectable_generator: ^2.4.1
  
  # Linting
  flutter_lints: ^3.0.1
```

## 🚀 Performance Optimization

### Const Constructors
```dart
// Always use const when possible
const AppButton.primary(
  text: 'Save',
  onPressed: _handleSave,
)
```

### Keys for Lists
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return AppListTile(
      key: ValueKey(items[index].id), // Important!
      title: items[index].title,
    );
  },
)
```

### Lazy Loading
```dart
// Load images lazily
AppImage.network(
  url: imageUrl,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return AppShimmer.image();
  },
)
```

### Memoization
```dart
// Cache expensive computations
late final _buttonStyle = _computeButtonStyle();

ButtonStyle _computeButtonStyle() {
  // Expensive computation
  return ButtonStyle(...);
}
```

## 📝 Documentation Standards

### Dartdoc Comments
```dart
/// A customizable button widget that follows the app's design system.
///
/// The [AppButton] provides several variants through named constructors:
/// - [AppButton.primary] for primary actions
/// - [AppButton.secondary] for secondary actions
/// - [AppButton.text] for text-only buttons
/// - [AppButton.outlined] for outlined buttons
/// - [AppButton.icon] for icon-only buttons
///
/// Example:
/// ```dart
/// AppButton.primary(
///   text: 'Save',
///   onPressed: () => print('Saved'),
///   isLoading: false,
/// )
/// ```
///
/// See also:
/// - [AppIconButton] for icon-only buttons with different styling
/// - [AppFloatingActionButton] for floating action buttons
class AppButton extends BaseStatelessWidget {
  /// Creates a button with the specified [variant].
  ///
  /// The [text] and [variant] parameters must not be null.
  /// The [onPressed] callback is called when the button is tapped.
  /// If [onPressed] is null, the button will be disabled.
  const AppButton._({
    super.key,
    required this.text,
    required this.onPressed,
    required this.variant,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });
  
  /// The text to display on the button.
  final String text;
  
  /// Called when the button is tapped.
  ///
  /// If this is null, the button will be disabled.
  final VoidCallback? onPressed;
  
  // ... more documentation
}
```

## 🔄 Migration Strategy

### Phase 1: Create New Components
1. Implement new design system components
2. Add comprehensive tests
3. Document usage

### Phase 2: Gradual Migration
1. Identify existing custom widgets
2. Replace with design system components
3. Update tests
4. Verify functionality

### Phase 3: Deprecation
1. Mark old widgets as deprecated
2. Provide migration guide
3. Remove after grace period

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-29

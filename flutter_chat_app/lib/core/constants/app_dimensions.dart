/// **APP DIMENSIONS - CENTRALIZED SPACING & SIZING**
///
/// Professional dimension management following enterprise standards:
/// - No hardcoded dimension values in UI components
/// - Consistent spacing and sizing across the application
/// - Responsive design support
/// - Semantic dimension naming for better maintainability
///
/// **Architecture:** Clean Architecture + Design System

/// **APPLICATION DIMENSIONS**
class AppDimensions {
  // Private constructor to prevent instantiation
  AppDimensions._();

  /// **Spacing Constants**
  static const double SPACING_NONE = 0.0;
  static const double SPACING_MICRO = 2.0;
  static const double SPACING_TINY = 4.0;
  static const double SPACING_SMALL = 8.0;
  static const double SPACING_MEDIUM = 12.0;
  static const double SPACING_DEFAULT = 16.0;
  static const double SPACING_LARGE = 20.0;
  static const double SPACING_EXTRA_LARGE = 24.0;
  static const double SPACING_HUGE = 32.0;
  static const double SPACING_MASSIVE = 48.0;

  /// **Padding Constants**
  static const double PADDING_MICRO = 2.0;
  static const double PADDING_TINY = 4.0;
  static const double PADDING_SMALL = 8.0;
  static const double PADDING_MEDIUM = 12.0;
  static const double PADDING_DEFAULT = 16.0;
  static const double PADDING_LARGE = 20.0;
  static const double PADDING_EXTRA_LARGE = 24.0;
  static const double PADDING_HUGE = 32.0;
  static const double PADDING_MASSIVE = 48.0;

  /// **Margin Constants**
  static const double MARGIN_MICRO = 2.0;
  static const double MARGIN_TINY = 4.0;
  static const double MARGIN_SMALL = 8.0;
  static const double MARGIN_MEDIUM = 12.0;
  static const double MARGIN_DEFAULT = 16.0;
  static const double MARGIN_LARGE = 20.0;
  static const double MARGIN_EXTRA_LARGE = 24.0;
  static const double MARGIN_HUGE = 32.0;
  static const double MARGIN_MASSIVE = 48.0;

  /// **Border Radius Constants**
  static const double RADIUS_NONE = 0.0;
  static const double RADIUS_TINY = 2.0;
  static const double RADIUS_SMALL = 4.0;
  static const double RADIUS_MEDIUM = 8.0;
  static const double RADIUS_DEFAULT = 12.0;
  static const double RADIUS_LARGE = 16.0;
  static const double RADIUS_EXTRA_LARGE = 20.0;
  static const double RADIUS_HUGE = 24.0;
  static const double RADIUS_CIRCULAR = 100.0;

  /// **Icon Sizes**
  static const double ICON_TINY = 12.0;
  static const double ICON_SMALL = 16.0;
  static const double ICON_MEDIUM = 20.0;
  static const double ICON_DEFAULT = 24.0;
  static const double ICON_LARGE = 28.0;
  static const double ICON_EXTRA_LARGE = 32.0;
  static const double ICON_HUGE = 40.0;
  static const double ICON_MASSIVE = 48.0;

  /// **Button Dimensions**
  static const double BUTTON_HEIGHT_SMALL = 32.0;
  static const double BUTTON_HEIGHT_MEDIUM = 40.0;
  static const double BUTTON_HEIGHT_DEFAULT = 48.0;
  static const double BUTTON_HEIGHT_LARGE = 56.0;
  static const double BUTTON_HEIGHT_EXTRA_LARGE = 64.0;

  static const double BUTTON_MIN_WIDTH = 64.0;
  static const double BUTTON_PADDING_HORIZONTAL = 16.0;
  static const double BUTTON_PADDING_VERTICAL = 12.0;

  /// **Input Field Dimensions**
  static const double INPUT_HEIGHT_SMALL = 40.0;
  static const double INPUT_HEIGHT_DEFAULT = 48.0;
  static const double INPUT_HEIGHT_LARGE = 56.0;
  static const double INPUT_PADDING_HORIZONTAL = 16.0;
  static const double INPUT_PADDING_VERTICAL = 12.0;

  /// **Card Dimensions**
  static const double CARD_PADDING = 16.0;
  static const double CARD_MARGIN = 8.0;
  static const double CARD_ELEVATION = 2.0;
  static const double CARD_BORDER_RADIUS = 12.0;

  /// **Avatar Sizes**
  static const double AVATAR_TINY = 20.0;
  static const double AVATAR_SMALL = 24.0;
  static const double AVATAR_MEDIUM = 32.0;
  static const double AVATAR_DEFAULT = 40.0;
  static const double AVATAR_LARGE = 48.0;
  static const double AVATAR_EXTRA_LARGE = 56.0;
  static const double AVATAR_HUGE = 64.0;
  static const double AVATAR_MASSIVE = 80.0;

  /// **Touch Target Sizes**
  static const double TOUCH_TARGET_SMALL = 40.0;
  static const double TOUCH_TARGET_DEFAULT = 48.0;
  static const double TOUCH_TARGET_LARGE = 56.0;

  /// **Elevation Constants**
  static const double ELEVATION_NONE = 0.0;
  static const double ELEVATION_TINY = 1.0;
  static const double ELEVATION_SMALL = 2.0;
  static const double ELEVATION_MEDIUM = 4.0;
  static const double ELEVATION_DEFAULT = 6.0;
  static const double ELEVATION_LARGE = 8.0;
  static const double ELEVATION_EXTRA_LARGE = 12.0;
  static const double ELEVATION_HUGE = 16.0;

  /// **Border Width Constants**
  static const double BORDER_NONE = 0.0;
  static const double BORDER_THIN = 0.5;
  static const double BORDER_DEFAULT = 1.0;
  static const double BORDER_THICK = 2.0;
  static const double BORDER_EXTRA_THICK = 4.0;

  /// **Chat-Specific Dimensions**
  static const double MESSAGE_BUBBLE_PADDING = 12.0;
  static const double MESSAGE_BUBBLE_MARGIN = 8.0;
  static const double MESSAGE_BUBBLE_RADIUS = 16.0;
  static const double MESSAGE_BUBBLE_MAX_WIDTH_RATIO = 0.75;

  static const double CHAT_INPUT_HEIGHT = 48.0;
  static const double CHAT_INPUT_PADDING = 12.0;
  static const double CHAT_INPUT_MARGIN = 8.0;

  static const double CHAT_LIST_ITEM_HEIGHT = 72.0;
  static const double CHAT_LIST_ITEM_PADDING = 16.0;

  /// **App Bar Dimensions**
  static const double APP_BAR_HEIGHT = 56.0;
  static const double APP_BAR_ELEVATION = 4.0;
  static const double APP_BAR_TITLE_SPACING = 16.0;

  /// **Bottom Navigation Dimensions**
  static const double BOTTOM_NAV_HEIGHT = 60.0;
  static const double BOTTOM_NAV_ICON_SIZE = 24.0;
  static const double BOTTOM_NAV_ELEVATION = 8.0;

  /// **Drawer Dimensions**
  static const double DRAWER_WIDTH = 280.0;
  static const double DRAWER_HEADER_HEIGHT = 160.0;
  static const double DRAWER_ITEM_HEIGHT = 48.0;

  /// **Dialog Dimensions**
  static const double DIALOG_PADDING = 24.0;
  static const double DIALOG_MARGIN = 40.0;
  static const double DIALOG_BORDER_RADIUS = 16.0;
  static const double DIALOG_ELEVATION = 24.0;

  /// **Snackbar Dimensions**
  static const double SNACKBAR_HEIGHT = 48.0;
  static const double SNACKBAR_PADDING = 16.0;
  static const double SNACKBAR_MARGIN = 8.0;
  static const double SNACKBAR_BORDER_RADIUS = 8.0;

  /// **Loading Indicator Dimensions**
  static const double LOADING_INDICATOR_SMALL = 16.0;
  static const double LOADING_INDICATOR_MEDIUM = 24.0;
  static const double LOADING_INDICATOR_LARGE = 32.0;
  static const double LOADING_INDICATOR_STROKE_WIDTH = 2.0;

  /// **Responsive Breakpoints**
  static const double BREAKPOINT_MOBILE = 600.0;
  static const double BREAKPOINT_TABLET = 900.0;
  static const double BREAKPOINT_DESKTOP = 1200.0;

  /// **Usage Examples:**
  /// 
  /// ```dart
  /// // ✅ CORRECT - Using dimension constants
  /// Container(
  ///   padding: EdgeInsets.all(AppDimensions.PADDING_DEFAULT),
  ///   margin: EdgeInsets.symmetric(
  ///     horizontal: AppDimensions.MARGIN_LARGE,
  ///     vertical: AppDimensions.MARGIN_SMALL,
  ///   ),
  ///   decoration: BoxDecoration(
  ///     borderRadius: BorderRadius.circular(AppDimensions.RADIUS_DEFAULT),
  ///   ),
  /// )
  /// 
  /// // ❌ INCORRECT - Hardcoded dimensions
  /// Container(
  ///   padding: EdgeInsets.all(16.0),
  ///   margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
  ///   decoration: BoxDecoration(
  ///     borderRadius: BorderRadius.circular(12.0),
  ///   ),
  /// )
  /// ```
}

/// **Responsive Dimension Helper**
class ResponsiveDimensions {
  /// **Get Responsive Padding**
  static double getResponsivePadding(double screenWidth) {
    if (screenWidth < AppDimensions.BREAKPOINT_MOBILE) {
      return AppDimensions.PADDING_DEFAULT;
    } else if (screenWidth < AppDimensions.BREAKPOINT_TABLET) {
      return AppDimensions.PADDING_LARGE;
    } else {
      return AppDimensions.PADDING_EXTRA_LARGE;
    }
  }

  /// **Get Responsive Font Size**
  static double getResponsiveFontSize(double screenWidth, double baseFontSize) {
    if (screenWidth < AppDimensions.BREAKPOINT_MOBILE) {
      return baseFontSize;
    } else if (screenWidth < AppDimensions.BREAKPOINT_TABLET) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }

  /// **Get Responsive Icon Size**
  static double getResponsiveIconSize(double screenWidth) {
    if (screenWidth < AppDimensions.BREAKPOINT_MOBILE) {
      return AppDimensions.ICON_DEFAULT;
    } else if (screenWidth < AppDimensions.BREAKPOINT_TABLET) {
      return AppDimensions.ICON_LARGE;
    } else {
      return AppDimensions.ICON_EXTRA_LARGE;
    }
  }

  /// **Check if Mobile**
  static bool isMobile(double screenWidth) {
    return screenWidth < AppDimensions.BREAKPOINT_MOBILE;
  }

  /// **Check if Tablet**
  static bool isTablet(double screenWidth) {
    return screenWidth >= AppDimensions.BREAKPOINT_MOBILE &&
           screenWidth < AppDimensions.BREAKPOINT_DESKTOP;
  }

  /// **Check if Desktop**
  static bool isDesktop(double screenWidth) {
    return screenWidth >= AppDimensions.BREAKPOINT_DESKTOP;
  }
}

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
  static const double spacingNone = 0.0;
  static const double spacingMicro = 2.0;
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingDefault = 16.0;
  static const double spacingLarge = 20.0;
  static const double spacingExtraLarge = 24.0;
  static const double spacingHuge = 32.0;
  static const double spacingMassive = 48.0;

  /// **Padding Constants**
  static const double paddingMicro = 2.0;
  static const double paddingTiny = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingDefault = 16.0;
  static const double paddingLarge = 20.0;
  static const double paddingExtraLarge = 24.0;
  static const double paddingHuge = 32.0;
  static const double paddingMassive = 48.0;

  /// **Margin Constants**
  static const double marginMicro = 2.0;
  static const double marginTiny = 4.0;
  static const double marginSmall = 8.0;
  static const double marginMedium = 12.0;
  static const double marginDefault = 16.0;
  static const double marginLarge = 20.0;
  static const double marginExtraLarge = 24.0;
  static const double marginHuge = 32.0;
  static const double marginMassive = 48.0;

  /// **Border Radius Constants**
  static const double radiusNone = 0.0;
  static const double radiusTiny = 2.0;
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusDefault = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 20.0;
  static const double radiusHuge = 24.0;
  static const double radiusCircular = 100.0;

  /// **Icon Sizes**
  static const double iconTiny = 12.0;
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconDefault = 24.0;
  static const double iconLarge = 28.0;
  static const double iconExtraLarge = 32.0;
  static const double iconHuge = 40.0;
  static const double iconMassive = 48.0;

  /// **Button Dimensions**
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightDefault = 48.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonHeightExtraLarge = 64.0;

  static const double buttonMinWidth = 64.0;
  static const double buttonPaddingHorizontal = 16.0;
  static const double buttonPaddingVertical = 12.0;

  /// **Input Field Dimensions**
  static const double inputHeightSmall = 40.0;
  static const double inputHeightDefault = 48.0;
  static const double inputHeightLarge = 56.0;
  static const double inputPaddingHorizontal = 16.0;
  static const double inputPaddingVertical = 12.0;

  /// **Card Dimensions**
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;

  /// **Avatar Sizes**
  static const double avatarTiny = 20.0;
  static const double avatarSmall = 24.0;
  static const double avatarMedium = 32.0;
  static const double avatarDefault = 40.0;
  static const double avatarLarge = 48.0;
  static const double avatarExtraLarge = 56.0;
  static const double avatarHuge = 64.0;
  static const double avatarMassive = 80.0;

  /// **Touch Target Sizes**
  static const double touchTargetSmall = 40.0;
  static const double touchTargetDefault = 48.0;
  static const double touchTargetLarge = 56.0;

  /// **Elevation Constants**
  static const double elevationNone = 0.0;
  static const double elevationTiny = 1.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationDefault = 6.0;
  static const double elevationLarge = 8.0;
  static const double elevationExtraLarge = 12.0;
  static const double elevationHuge = 16.0;

  /// **Border Width Constants**
  static const double borderNone = 0.0;
  static const double borderThin = 0.5;
  static const double borderDefault = 1.0;
  static const double borderThick = 2.0;
  static const double borderExtraThick = 4.0;

  /// **Chat-Specific Dimensions**
  static const double messageBubblePadding = 12.0;
  static const double messageBubbleMargin = 8.0;
  static const double messageBubbleRadius = 16.0;
  static const double messageBubbleMaxWidthRatio = 0.75;

  static const double chatInputHeight = 48.0;
  static const double chatInputPadding = 12.0;
  static const double chatInputMargin = 8.0;

  static const double chatListItemHeight = 72.0;
  static const double chatListItemPadding = 16.0;

  /// **App Bar Dimensions**
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 4.0;
  static const double appBarTitleSpacing = 16.0;

  /// **Bottom Navigation Dimensions**
  static const double bottomNavHeight = 60.0;
  static const double bottomNavIconSize = 24.0;
  static const double bottomNavElevation = 8.0;

  /// **Drawer Dimensions**
  static const double drawerWidth = 280.0;
  static const double drawerHeaderHeight = 160.0;
  static const double drawerItemHeight = 48.0;

  /// **Dialog Dimensions**
  static const double dialogPadding = 24.0;
  static const double dialogMargin = 40.0;
  static const double dialogBorderRadius = 16.0;
  static const double dialogElevation = 24.0;

  /// **Snackbar Dimensions**
  static const double snackbarHeight = 48.0;
  static const double snackbarPadding = 16.0;
  static const double snackbarMargin = 8.0;
  static const double snackbarBorderRadius = 8.0;

  /// **Loading Indicator Dimensions**
  static const double loadingIndicatorSmall = 16.0;
  static const double loadingIndicatorMedium = 24.0;
  static const double loadingIndicatorLarge = 32.0;
  static const double loadingIndicatorStrokeWidth = 2.0;

  /// **Responsive Breakpoints**
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;

  /// **Usage Examples:**
  /// 
  /// ```dart
  /// // ✅ CORRECT - Using dimension constants
  /// Container(
  ///   padding: EdgeInsets.all(AppDimensions.paddingDefault),
  ///   margin: EdgeInsets.symmetric(
  ///     horizontal: AppDimensions.marginLarge,
  ///     vertical: AppDimensions.marginSmall,
  ///   ),
  ///   decoration: BoxDecoration(
  ///     borderRadius: BorderRadius.circular(AppDimensions.radiusDefault),
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
    if (screenWidth < AppDimensions.breakpointMobile) {
      return AppDimensions.PADDING_DEFAULT;
    } else if (screenWidth < AppDimensions.breakpointTablet) {
      return AppDimensions.PADDING_LARGE;
    } else {
      return AppDimensions.PADDING_EXTRA_LARGE;
    }
  }

  /// **Get Responsive Font Size**
  static double getResponsiveFontSize(double screenWidth, double baseFontSize) {
    if (screenWidth < AppDimensions.breakpointMobile) {
      return baseFontSize;
    } else if (screenWidth < AppDimensions.breakpointTablet) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }

  /// **Get Responsive Icon Size**
  static double getResponsiveIconSize(double screenWidth) {
    if (screenWidth < AppDimensions.breakpointMobile) {
      return AppDimensions.iconDefault;
    } else if (screenWidth < AppDimensions.breakpointTablet) {
      return AppDimensions.iconLarge;
    } else {
      return AppDimensions.iconExtraLarge;
    }
  }

  /// **Check if Mobile**
  static bool isMobile(double screenWidth) {
    return screenWidth < AppDimensions.breakpointMobile;
  }

  /// **Check if Tablet**
  static bool isTablet(double screenWidth) {
    return screenWidth >= AppDimensions.breakpointMobile &&
           screenWidth < AppDimensions.breakpointDesktop;
  }

  /// **Check if Desktop**
  static bool isDesktop(double screenWidth) {
    return screenWidth >= AppDimensions.breakpointDesktop;
  }
}

/// **ENTERPRISE DIMENSION SYSTEM**
///
/// Comprehensive dimension constants following 8px grid system.
/// All dimensions are in logical pixels (dp/pt).
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Centralized constants (no hardcoded values)
///
/// **Usage**:
/// ```dart
/// Container(
///   padding: EdgeInsets.all(AppDimens.paddingMedium),
///   margin: EdgeInsets.symmetric(horizontal: AppDimens.marginSmall),
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(AppDimens.radiusCard),
///   ),
/// )
/// ```
///
/// **Best Practices**:
/// - Always use AppDimens instead of hardcoded values
/// - Follow 8px grid system for consistency
/// - Use semantic names (paddingCard, radiusButton)
/// - Use helper methods for responsive layouts
class AppDimens {
  /// Private constructor to prevent instantiation
  AppDimens._();

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
  
  /// Extra extra large icon: 64dp
  static const double iconXXLarge = 64.0;

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
  ///
  /// Returns:
  /// - [paddingXLarge] for desktop (>= 1200dp)
  /// - [paddingLarge] for tablet (>= 900dp)
  /// - [paddingMedium] for mobile (< 900dp)
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
  ///
  /// Returns:
  /// - [marginXLarge] for desktop (>= 1200dp)
  /// - [marginLarge] for tablet (>= 900dp)
  /// - [marginMedium] for mobile (< 900dp)
  static double getResponsiveMargin(double screenWidth) {
    if (screenWidth >= breakpointDesktop) {
      return marginXLarge;
    } else if (screenWidth >= breakpointTablet) {
      return marginLarge;
    } else {
      return marginMedium;
    }
  }
  
  /// Check if screen is mobile size
  ///
  /// Returns true if screen width < 600dp
  static bool isMobile(double screenWidth) => screenWidth < breakpointMobile;
  
  /// Check if screen is tablet size
  ///
  /// Returns true if screen width >= 600dp and < 1200dp
  static bool isTablet(double screenWidth) => 
      screenWidth >= breakpointMobile && screenWidth < breakpointDesktop;
  
  /// Check if screen is desktop size
  ///
  /// Returns true if screen width >= 1200dp
  static bool isDesktop(double screenWidth) => screenWidth >= breakpointDesktop;
  
  /// Get device type based on screen width
  ///
  /// Returns 'mobile', 'tablet', or 'desktop'
  static String getDeviceType(double screenWidth) {
    if (isDesktop(screenWidth)) return 'desktop';
    if (isTablet(screenWidth)) return 'tablet';
    return 'mobile';
  }
}

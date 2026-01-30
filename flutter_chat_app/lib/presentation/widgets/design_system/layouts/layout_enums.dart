/// **LAYOUT ENUMS**
///
/// Enums for layout and responsive components.
///
/// **Enums**:
/// - [LayoutType]: Device layout type (mobile, tablet, desktop)
/// - [SplitViewMode]: Split view display mode
/// - [PanelOrientation]: Panel orientation (horizontal, vertical)
/// - [StickyHeaderMode]: Sticky header behavior mode
library;

/// Device layout type based on screen width
enum LayoutType {
  /// Mobile layout (width < 600dp)
  mobile,

  /// Tablet layout (600dp ≤ width < 1200dp)
  tablet,

  /// Desktop layout (width ≥ 1200dp)
  desktop;

  /// Get layout type from screen width
  static LayoutType fromWidth(double width) {
    if (width < 600) return LayoutType.mobile;
    if (width < 1200) return LayoutType.tablet;
    return LayoutType.desktop;
  }

  /// Check if current layout is mobile
  bool get isMobile => this == LayoutType.mobile;

  /// Check if current layout is tablet
  bool get isTablet => this == LayoutType.tablet;

  /// Check if current layout is desktop
  bool get isDesktop => this == LayoutType.desktop;

  /// Check if current layout is mobile or tablet
  bool get isMobileOrTablet => isMobile || isTablet;
}

/// Split view display mode
enum SplitViewMode {
  /// Side-by-side with draggable divider (desktop)
  sideBySide,

  /// Separate screens with navigation (mobile)
  separate,

  /// Adaptive based on orientation (tablet)
  adaptive;

  /// Get split view mode from layout type
  static SplitViewMode fromLayoutType(LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.mobile:
        return SplitViewMode.separate;
      case LayoutType.tablet:
        return SplitViewMode.adaptive;
      case LayoutType.desktop:
        return SplitViewMode.sideBySide;
    }
  }
}

/// Panel orientation
enum PanelOrientation {
  /// Horizontal layout (panels side by side)
  horizontal,

  /// Vertical layout (panels stacked)
  vertical;

  /// Check if orientation is horizontal
  bool get isHorizontal => this == PanelOrientation.horizontal;

  /// Check if orientation is vertical
  bool get isVertical => this == PanelOrientation.vertical;
}

/// Sticky header behavior mode
enum StickyHeaderMode {
  /// Always sticky
  always,

  /// Sticky on scroll
  onScroll,

  /// Never sticky
  never;

  /// Check if header should be sticky
  bool get isSticky => this != StickyHeaderMode.never;

  /// Check if header should stick on scroll
  bool get stickyOnScroll => this == StickyHeaderMode.onScroll;
}

/// Extension methods for layout enums
extension LayoutTypeExtension on LayoutType {
  /// Get breakpoint width for layout type
  double get breakpoint {
    switch (this) {
      case LayoutType.mobile:
        return 600;
      case LayoutType.tablet:
        return 1200;
      case LayoutType.desktop:
        return double.infinity;
    }
  }

  /// Get description for layout type
  String get description {
    switch (this) {
      case LayoutType.mobile:
        return 'Mobile (< 600dp)';
      case LayoutType.tablet:
        return 'Tablet (600-1200dp)';
      case LayoutType.desktop:
        return 'Desktop (≥ 1200dp)';
    }
  }
}

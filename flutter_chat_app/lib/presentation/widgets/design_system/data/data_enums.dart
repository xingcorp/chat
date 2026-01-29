/// **DATA DISPLAY ENUMS**
///
/// Enums for data display components (tables, timelines, carousels, calendars, accordions).
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Centralized enum definitions
///
/// **Usage**:
/// ```dart
/// import 'package:flutter_chat_app/presentation/widgets/design_system/data/data_enums.dart';
///
/// AppDataTable(
///   sortDirection: SortDirection.ascending,
/// )
///
/// AppTimeline(
///   alignment: TimelineAlignment.left,
/// )
/// ```

/// Sort direction for data tables
enum SortDirection {
  /// Ascending order (A-Z, 0-9, oldest-newest)
  ascending,

  /// Descending order (Z-A, 9-0, newest-oldest)
  descending,
}

/// Timeline alignment
enum TimelineAlignment {
  /// All items aligned to the left
  left,

  /// All items aligned to the right
  right,

  /// Items alternate between left and right
  alternating,

  /// Items centered
  center,
}

/// Carousel indicator position
enum CarouselIndicatorPosition {
  /// Indicators at the top
  top,

  /// Indicators at the bottom
  bottom,

  /// Indicators on the left
  left,

  /// Indicators on the right
  right,

  /// No indicators
  none,
}

/// Carousel indicator style
enum CarouselIndicatorStyle {
  /// Dot indicators
  dots,

  /// Line indicators
  lines,

  /// Number indicators (1/5, 2/5, etc.)
  numbers,

  /// Thumbnail indicators
  thumbnails,
}

/// Calendar selection mode
enum CalendarSelectionMode {
  /// Single date selection
  single,

  /// Date range selection
  range,

  /// Multiple individual dates
  multiple,

  /// No selection (display only)
  none,
}

/// Calendar view mode
enum CalendarViewMode {
  /// Month view (default)
  month,

  /// Week view
  week,

  /// Day view
  day,

  /// Year view
  year,
}

/// Accordion expansion mode
enum AccordionMode {
  /// Only one section can be expanded at a time
  single,

  /// Multiple sections can be expanded simultaneously
  multiple,
}

/// Accordion animation curve
enum AccordionAnimationCurve {
  /// Linear animation
  linear,

  /// Ease in animation
  easeIn,

  /// Ease out animation
  easeOut,

  /// Ease in-out animation
  easeInOut,

  /// Bounce animation
  bounce,

  /// Elastic animation
  elastic,
}

/// Data table column type
enum DataTableColumnType {
  /// Text column
  text,

  /// Number column
  number,

  /// Date column
  date,

  /// Boolean column (checkbox)
  boolean,

  /// Custom column
  custom,
}

/// Data table selection mode
enum DataTableSelectionMode {
  /// No selection
  none,

  /// Single row selection
  single,

  /// Multiple row selection
  multiple,
}

/// Timeline marker type
enum TimelineMarkerType {
  /// Dot marker
  dot,

  /// Icon marker
  icon,

  /// Image marker
  image,

  /// Custom marker
  custom,
}

/// Timeline line style
enum TimelineLineStyle {
  /// Solid line
  solid,

  /// Dashed line
  dashed,

  /// Dotted line
  dotted,
}

/// Carousel transition type
enum CarouselTransitionType {
  /// Slide transition
  slide,

  /// Fade transition
  fade,

  /// Scale transition
  scale,

  /// Rotate transition
  rotate,

  /// Custom transition
  custom,
}

/// Calendar first day of week
enum CalendarFirstDayOfWeek {
  /// Sunday
  sunday,

  /// Monday
  monday,

  /// Saturday
  saturday,
}

/// Extension methods for enums
extension SortDirectionExtension on SortDirection {
  /// Returns true if ascending
  bool get isAscending => this == SortDirection.ascending;

  /// Returns true if descending
  bool get isDescending => this == SortDirection.descending;

  /// Toggles sort direction
  SortDirection toggle() {
    return this == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending;
  }
}

extension CalendarSelectionModeExtension on CalendarSelectionMode {
  /// Returns true if single selection
  bool get isSingle => this == CalendarSelectionMode.single;

  /// Returns true if range selection
  bool get isRange => this == CalendarSelectionMode.range;

  /// Returns true if multiple selection
  bool get isMultiple => this == CalendarSelectionMode.multiple;

  /// Returns true if no selection
  bool get isNone => this == CalendarSelectionMode.none;
}

extension AccordionModeExtension on AccordionMode {
  /// Returns true if single mode
  bool get isSingle => this == AccordionMode.single;

  /// Returns true if multiple mode
  bool get isMultiple => this == AccordionMode.multiple;
}

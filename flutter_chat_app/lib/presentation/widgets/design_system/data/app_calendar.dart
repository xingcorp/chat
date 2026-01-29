library;

/// **APP CALENDAR**
///
/// Calendar component with single date, range, and multiple date selection.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Month view with week headers
/// - Single date, range, and multiple selection modes
/// - Min/max date constraints
/// - Disabled dates support
/// - Event markers on dates
/// - Month/year navigation
/// - Locale-aware first day of week
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with controller
///
/// **Usage**:
/// ```dart
/// // Single date selection
/// AppCalendar(
///   selectionMode: CalendarSelectionMode.single,
///   selectedDate: _selectedDate,
///   onDateSelected: (date) => setState(() => _selectedDate = date),
/// )
///
/// // Range selection
/// AppCalendar(
///   selectionMode: CalendarSelectionMode.range,
///   selectedRange: _selectedRange,
///   onRangeSelected: (start, end) {
///     setState(() => _selectedRange = DateTimeRange(start: start, end: end));
///   },
/// )
///
/// // Multiple dates
/// AppCalendar(
///   selectionMode: CalendarSelectionMode.multiple,
///   selectedDates: _selectedDates,
///   onMultipleDatesSelected: (dates) {
///     setState(() => _selectedDates = dates);
///   },
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/data/data_enums.dart';
import 'package:intl/intl.dart';

/// Calendar event marker
class CalendarEvent {
  /// Event date
  final DateTime date;

  /// Event color
  final Color color;

  /// Event title (optional)
  final String? title;

  const CalendarEvent({
    required this.date,
    required this.color,
    this.title,
  });
}

/// App Calendar widget
class AppCalendar extends BaseStatefulWidget {
  const AppCalendar({
    super.key,
    this.selectionMode = CalendarSelectionMode.single,
    this.selectedDate,
    this.selectedRange,
    this.selectedDates = const [],
    this.onDateSelected,
    this.onRangeSelected,
    this.onMultipleDatesSelected,
    this.minDate,
    this.maxDate,
    this.disabledDates = const [],
    this.events = const [],
    this.firstDayOfWeek = CalendarFirstDayOfWeek.monday,
    this.showWeekNumbers = false,
    this.headerColor,
    this.selectedColor,
    this.todayColor,
    this.disabledColor,
    this.eventMarkerSize = 6.0,
  });

  /// Selection mode
  final CalendarSelectionMode selectionMode;

  /// Selected date (single mode)
  final DateTime? selectedDate;

  /// Selected range (range mode)
  final DateTimeRange? selectedRange;

  /// Selected dates (multiple mode)
  final List<DateTime> selectedDates;

  /// Date selected callback (single mode)
  final void Function(DateTime date)? onDateSelected;

  /// Range selected callback (range mode)
  final void Function(DateTime start, DateTime end)? onRangeSelected;

  /// Multiple dates selected callback (multiple mode)
  final void Function(List<DateTime> dates)? onMultipleDatesSelected;

  /// Minimum selectable date
  final DateTime? minDate;

  /// Maximum selectable date
  final DateTime? maxDate;

  /// Disabled dates
  final List<DateTime> disabledDates;

  /// Events to display
  final List<CalendarEvent> events;

  /// First day of week
  final CalendarFirstDayOfWeek firstDayOfWeek;

  /// Whether to show week numbers
  final bool showWeekNumbers;

  /// Header background color
  final Color? headerColor;

  /// Selected date color
  final Color? selectedColor;

  /// Today's date color
  final Color? todayColor;

  /// Disabled date color
  final Color? disabledColor;

  /// Event marker size
  final double eventMarkerSize;

  @override
  AppCalendarState createState() => AppCalendarState();
}

class AppCalendarState extends BaseState<AppCalendar> {
  late DateTime _displayedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _displayedMonth = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, isDark),
            _buildWeekDayHeaders(theme, isDark),
            _buildCalendarGrid(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      color: widget.headerColor ??
          (isDark ? Colors.grey[850] : Colors.grey[100]),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: 'Previous month',
          ),
          InkWell(
            onTap: _showMonthYearPicker,
            child: Text(
              DateFormat.yMMMM().format(_displayedMonth),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayHeaders(ThemeData theme, bool isDark) {
    final weekDays = _getWeekDayNames();

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingSmall),
      child: Row(
        children: [
          if (widget.showWeekNumbers)
            SizedBox(
              width: AppDimens.touchTargetMin,
              child: Center(
                child: Text(
                  'W',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ...weekDays.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, bool isDark) {
    final weeks = _getWeeksInMonth();

    return Column(
      children: weeks.map((week) => _buildWeekRow(week, theme, isDark)).toList(),
    );
  }

  Widget _buildWeekRow(List<DateTime?> week, ThemeData theme, bool isDark) {
    return Row(
      children: [
        if (widget.showWeekNumbers)
          SizedBox(
            width: AppDimens.touchTargetMin,
            child: Center(
              child: Text(
                _getWeekNumber(week.firstWhere((d) => d != null)!).toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ...week.map((date) => Expanded(
              child: date != null
                  ? _buildDateCell(date, theme, isDark)
                  : const SizedBox(height: AppDimens.touchTargetMin),
            )),
      ],
    );
  }

  Widget _buildDateCell(DateTime date, ThemeData theme, bool isDark) {
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isDateSelected(date);
    final isInRange = _isDateInRange(date);
    final isDisabled = _isDateDisabled(date);
    final hasEvents = _hasEvents(date);

    return InkWell(
      onTap: isDisabled ? null : () => _handleDateTap(date),
      child: Container(
        height: AppDimens.touchTargetMin,
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: _getDateCellColor(
            isSelected,
            isInRange,
            isToday,
            isDisabled,
            theme,
            isDark,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          border: isToday && !isSelected
              ? Border.all(
                  color: widget.todayColor ?? theme.colorScheme.primary,
                  width: 2.0,
                )
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                date.day.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getDateTextColor(
                    isSelected,
                    isDisabled,
                    theme,
                    isDark,
                  ),
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (hasEvents)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: _buildEventMarkers(date),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventMarkers(DateTime date) {
    final dateEvents = widget.events
        .where((event) => _isSameDay(event.date, date))
        .take(3)
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dateEvents.map((event) {
        return Container(
          width: widget.eventMarkerSize,
          height: widget.eventMarkerSize,
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          decoration: BoxDecoration(
            color: event.color,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  Color _getDateCellColor(
    bool isSelected,
    bool isInRange,
    bool isToday,
    bool isDisabled,
    ThemeData theme,
    bool isDark,
  ) {
    if (isDisabled) {
      return widget.disabledColor ??
          (isDark ? Colors.grey[800]! : Colors.grey[200]!);
    }
    if (isSelected) {
      return widget.selectedColor ?? theme.colorScheme.primary;
    }
    if (isInRange) {
      return (widget.selectedColor ?? theme.colorScheme.primary)
          .withValues(alpha: 0.2);
    }
    return Colors.transparent;
  }

  Color _getDateTextColor(
    bool isSelected,
    bool isDisabled,
    ThemeData theme,
    bool isDark,
  ) {
    if (isDisabled) {
      return isDark ? Colors.white38 : Colors.black38;
    }
    if (isSelected) {
      return theme.colorScheme.onPrimary;
    }
    return theme.textTheme.bodyMedium!.color!;
  }

  bool _isDateSelected(DateTime date) {
    switch (widget.selectionMode) {
      case CalendarSelectionMode.single:
        return widget.selectedDate != null &&
            _isSameDay(date, widget.selectedDate!);
      case CalendarSelectionMode.range:
        if (widget.selectedRange == null) return false;
        return _isSameDay(date, widget.selectedRange!.start) ||
            _isSameDay(date, widget.selectedRange!.end);
      case CalendarSelectionMode.multiple:
        return widget.selectedDates.any((d) => _isSameDay(d, date));
      case CalendarSelectionMode.none:
        return false;
    }
  }

  bool _isDateInRange(DateTime date) {
    if (widget.selectionMode != CalendarSelectionMode.range) return false;
    if (widget.selectedRange == null) return false;

    return date.isAfter(widget.selectedRange!.start) &&
        date.isBefore(widget.selectedRange!.end);
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) {
      return true;
    }
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) {
      return true;
    }
    return widget.disabledDates.any((d) => _isSameDay(d, date));
  }

  bool _hasEvents(DateTime date) {
    return widget.events.any((event) => _isSameDay(event.date, date));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _handleDateTap(DateTime date) {
    switch (widget.selectionMode) {
      case CalendarSelectionMode.single:
        widget.onDateSelected?.call(date);
        break;
      case CalendarSelectionMode.range:
        _handleRangeSelection(date);
        break;
      case CalendarSelectionMode.multiple:
        _handleMultipleSelection(date);
        break;
      case CalendarSelectionMode.none:
        break;
    }
  }

  void _handleRangeSelection(DateTime date) {
    if (_rangeStart == null || _rangeEnd != null) {
      // Start new range
      safeSetState(() {
        _rangeStart = date;
        _rangeEnd = null;
      });
    } else {
      // Complete range
      final start = date.isBefore(_rangeStart!) ? date : _rangeStart!;
      final end = date.isAfter(_rangeStart!) ? date : _rangeStart!;
      
      safeSetState(() {
        _rangeStart = null;
        _rangeEnd = null;
      });
      
      widget.onRangeSelected?.call(start, end);
    }
  }

  void _handleMultipleSelection(DateTime date) {
    final newDates = List<DateTime>.from(widget.selectedDates);
    final existingIndex = newDates.indexWhere((d) => _isSameDay(d, date));
    
    if (existingIndex >= 0) {
      newDates.removeAt(existingIndex);
    } else {
      newDates.add(date);
    }
    
    widget.onMultipleDatesSelected?.call(newDates);
  }

  void _previousMonth() {
    safeSetState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    safeSetState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  Future<void> _showMonthYearPicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _displayedMonth,
      firstDate: widget.minDate ?? DateTime(1900),
      lastDate: widget.maxDate ?? DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (selectedDate != null) {
      safeSetState(() {
        _displayedMonth = selectedDate;
      });
    }
  }

  List<String> _getWeekDayNames() {
    final firstDay = _getFirstDayOfWeek();
    final weekDays = <String>[];
    
    for (int i = 0; i < 7; i++) {
      final day = DateTime(2024, 1, firstDay + i);
      weekDays.add(DateFormat.E().format(day).substring(0, 2));
    }
    
    return weekDays;
  }

  int _getFirstDayOfWeek() {
    switch (widget.firstDayOfWeek) {
      case CalendarFirstDayOfWeek.sunday:
        return 7; // Sunday in DateTime is 7
      case CalendarFirstDayOfWeek.monday:
        return 1;
      case CalendarFirstDayOfWeek.saturday:
        return 6;
    }
  }

  List<List<DateTime?>> _getWeeksInMonth() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    
    final firstWeekday = firstDayOfMonth.weekday;
    final firstDayOfWeek = _getFirstDayOfWeek();
    
    // Calculate offset
    int offset = (firstWeekday - firstDayOfWeek) % 7;
    if (offset < 0) offset += 7;
    
    final weeks = <List<DateTime?>>[];
    var currentWeek = <DateTime?>[...List.filled(offset, null)];
    
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      currentWeek.add(date);
      
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }
    
    // Fill last week
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }
    
    return weeks;
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }
}

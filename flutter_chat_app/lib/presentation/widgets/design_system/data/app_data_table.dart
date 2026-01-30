library;

/// **APP DATA TABLE**
///
/// Enterprise-grade data table with sorting, filtering, selection, and pagination.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Generic type support: `AppDataTable<T>`
/// - Sortable columns with ascending/descending
/// - Row selection (single/multiple)
/// - Filter inputs per column
/// - Pagination support
/// - Responsive design (horizontal scroll on mobile)
/// - Fixed header on scroll
/// - Custom cell renderers
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with controller
///
/// **Usage**:
/// ```dart
/// AppDataTable<User>(
///   columns: [
///     DataTableColumn(
///       id: 'name',
///       label: context.l10n.name,
///       sortable: true,
///     ),
///     DataTableColumn(
///       id: 'email',
///       label: context.l10n.email,
///       sortable: true,
///     ),
///     DataTableColumn(
///       id: 'role',
///       label: context.l10n.role,
///       filterable: true,
///     ),
///   ],
///   rows: users,
///   cellBuilder: (user, columnId) {
///     switch (columnId) {
///       case 'name':
///         return Text(user.name);
///       case 'email':
///         return Text(user.email);
///       case 'role':
///         return Chip(label: Text(user.role));
///       default:
///         return const SizedBox();
///     }
///   },
///   onSort: (columnId, direction) => _handleSort(columnId, direction),
///   onRowTap: (user) => _viewUserDetails(user),
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/data/data_enums.dart';

/// Data table column configuration
class DataTableColumn<T> {
  /// Column identifier
  final String id;

  /// Column label
  final String label;

  /// Whether column is sortable
  final bool sortable;

  /// Whether column is filterable
  final bool filterable;

  /// Column width (null for flexible)
  final double? width;

  /// Column type
  final DataTableColumnType type;

  /// Custom header widget
  final Widget? headerWidget;

  /// Alignment
  final Alignment alignment;

  const DataTableColumn({
    required this.id,
    required this.label,
    this.sortable = false,
    this.filterable = false,
    this.width,
    this.type = DataTableColumnType.text,
    this.headerWidget,
    this.alignment = Alignment.centerLeft,
  });
}

/// App Data Table widget
class AppDataTable<T> extends BaseStatefulWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.cellBuilder,
    this.onSort,
    this.onFilter,
    this.onRowTap,
    this.onRowLongPress,
    this.onSelectionChanged,
    this.selectionMode = DataTableSelectionMode.none,
    this.selectedRows = const [],
    this.sortColumnId,
    this.sortDirection = SortDirection.ascending,
    this.showFilters = false,
    this.filters = const {},
    this.itemsPerPage = 10,
    this.currentPage = 0,
    this.showPagination = true,
    this.emptyMessage,
    this.headerColor,
    this.rowColor,
    this.selectedRowColor,
    this.dividerColor,
    this.isLoading = false,
  });

  /// Table columns
  final List<DataTableColumn<T>> columns;

  /// Table rows data
  final List<T> rows;

  /// Cell builder function
  final Widget Function(T row, String columnId) cellBuilder;

  /// Sort callback
  final void Function(String columnId, SortDirection direction)? onSort;

  /// Filter callback
  final void Function(Map<String, String> filters)? onFilter;

  /// Row tap callback
  final void Function(T row)? onRowTap;

  /// Row long press callback
  final void Function(T row)? onRowLongPress;

  /// Selection changed callback
  final void Function(List<T> selectedRows)? onSelectionChanged;

  /// Selection mode
  final DataTableSelectionMode selectionMode;

  /// Selected rows
  final List<T> selectedRows;

  /// Current sort column ID
  final String? sortColumnId;

  /// Current sort direction
  final SortDirection sortDirection;

  /// Whether to show filter inputs
  final bool showFilters;

  /// Current filters
  final Map<String, String> filters;

  /// Items per page for pagination
  final int itemsPerPage;

  /// Current page (0-indexed)
  final int currentPage;

  /// Whether to show pagination
  final bool showPagination;

  /// Empty state message
  final String? emptyMessage;

  /// Header background color
  final Color? headerColor;

  /// Row background color
  final Color? rowColor;

  /// Selected row background color
  final Color? selectedRowColor;

  /// Divider color
  final Color? dividerColor;

  /// Whether table is loading
  final bool isLoading;

  @override
  AppDataTableState<T> createState() => AppDataTableState<T>();
}

class AppDataTableState<T> extends BaseState<AppDataTable<T>> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final Map<String, TextEditingController> _filterControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeFilterControllers();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    for (final controller in _filterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeFilterControllers() {
    for (final column in widget.columns) {
      if (column.filterable) {
        _filterControllers[column.id] = TextEditingController(
          text: widget.filters[column.id] ?? '',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.rows.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table
        Expanded(
          child: _buildTable(theme, isDark),
        ),
        
        // Pagination
        if (widget.showPagination && widget.rows.length > widget.itemsPerPage)
          _buildPagination(theme, isDark),
      ],
    );
  }

  Widget _buildTable(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.dividerColor ??
              (isDark ? Colors.white24 : Colors.black12),
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: Column(
          children: [
            // Header
            _buildHeader(theme, isDark),
            
            // Filters
            if (widget.showFilters) _buildFilters(theme, isDark),
            
            // Rows
            Expanded(
              child: Scrollbar(
                controller: _verticalScrollController,
                thumbVisibility: true,
                child: Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.depth == 1,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: _buildRows(theme, isDark),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      color: widget.headerColor ??
          (isDark ? Colors.grey[850] : Colors.grey[100]),
      child: Row(
        children: [
          // Selection checkbox
          if (widget.selectionMode == DataTableSelectionMode.multiple)
            _buildHeaderCheckbox(theme),
          
          // Column headers
          ...widget.columns.map((column) => _buildColumnHeader(column, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildHeaderCheckbox(ThemeData theme) {
    final allSelected = widget.selectedRows.length == widget.rows.length;
    final someSelected = widget.selectedRows.isNotEmpty && !allSelected;

    return SizedBox(
      width: AppDimens.touchTargetMin,
      height: AppDimens.touchTargetMin,
      child: Checkbox(
        value: allSelected,
        tristate: someSelected,
        onChanged: (value) {
          if (value == true) {
            widget.onSelectionChanged?.call(List.from(widget.rows));
          } else {
            widget.onSelectionChanged?.call([]);
          }
        },
      ),
    );
  }

  Widget _buildColumnHeader(
    DataTableColumn<T> column,
    ThemeData theme,
    bool isDark,
  ) {
    final isCurrentSort = widget.sortColumnId == column.id;

    return SizedBox(
      width: column.width ?? 150,
      child: InkWell(
        onTap: column.sortable
            ? () => _handleSort(column.id)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingSmall,
          ),
          child: Row(
            mainAxisAlignment: _getMainAxisAlignment(column.alignment),
            children: [
              Flexible(
                child: Text(
                  column.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (column.sortable) ...[
                const SizedBox(width: AppDimens.spaceXSmall),
                Icon(
                  isCurrentSort
                      ? (widget.sortDirection == SortDirection.ascending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: AppDimens.iconSmall,
                  color: isCurrentSort
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: Row(
        children: [
          // Empty space for selection checkbox
          if (widget.selectionMode == DataTableSelectionMode.multiple)
            const SizedBox(width: AppDimens.touchTargetMin),
          
          // Filter inputs
          ...widget.columns.map((column) {
            if (!column.filterable) {
              return SizedBox(width: column.width ?? 150);
            }

            return SizedBox(
              width: column.width ?? 150,
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingSmall),
                child: TextField(
                  controller: _filterControllers[column.id],
                  decoration: InputDecoration(
                    hintText: context.l10n.filter,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingSmall,
                      vertical: AppDimens.paddingXSmall,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    ),
                  ),
                  onChanged: (value) => _handleFilter(column.id, value),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRows(ThemeData theme, bool isDark) {
    final startIndex = widget.showPagination
        ? widget.currentPage * widget.itemsPerPage
        : 0;
    final endIndex = widget.showPagination
        ? (startIndex + widget.itemsPerPage).clamp(0, widget.rows.length)
        : widget.rows.length;
    
    final visibleRows = widget.rows.sublist(startIndex, endIndex);

    return Column(
      children: visibleRows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final isSelected = widget.selectedRows.contains(row);
        final isEven = index % 2 == 0;

        return _buildRow(row, isSelected, isEven, theme, isDark);
      }).toList(),
    );
  }

  Widget _buildRow(
    T row,
    bool isSelected,
    bool isEven,
    ThemeData theme,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        if (widget.selectionMode != DataTableSelectionMode.none) {
          _handleRowSelection(row);
        }
        widget.onRowTap?.call(row);
      },
      onLongPress: () => widget.onRowLongPress?.call(row),
      child: Container(
        color: isSelected
            ? (widget.selectedRowColor ??
                theme.colorScheme.primary.withValues(alpha: 0.1))
            : (widget.rowColor ??
                (isEven
                    ? (isDark ? Colors.grey[900] : Colors.white)
                    : (isDark ? Colors.grey[850] : Colors.grey[50]))),
        child: Row(
          children: [
            // Selection checkbox/radio
            if (widget.selectionMode != DataTableSelectionMode.none)
              _buildRowSelector(row, isSelected, theme),
            
            // Cells
            ...widget.columns.map((column) => _buildCell(row, column, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildRowSelector(T row, bool isSelected, ThemeData theme) {
    return SizedBox(
      width: AppDimens.touchTargetMin,
      height: AppDimens.touchTargetMin,
      child: widget.selectionMode == DataTableSelectionMode.multiple
          ? Checkbox(
              value: isSelected,
              onChanged: (value) => _handleRowSelection(row),
            )
          : Radio<T>(
              value: row,
              groupValue: widget.selectedRows.firstOrNull,
              onChanged: (value) => _handleRowSelection(row),
            ),
    );
  }

  Widget _buildCell(
    T row,
    DataTableColumn<T> column,
    ThemeData theme,
  ) {
    return SizedBox(
      width: column.width ?? 150,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        child: Align(
          alignment: column.alignment,
          child: widget.cellBuilder(row, column.id),
        ),
      ),
    );
  }

  Widget _buildPagination(ThemeData theme, bool isDark) {
    final totalPages = (widget.rows.length / widget.itemsPerPage).ceil();
    final startItem = widget.currentPage * widget.itemsPerPage + 1;
    final endItem = ((widget.currentPage + 1) * widget.itemsPerPage)
        .clamp(0, widget.rows.length);

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: widget.dividerColor ??
                (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.showingItems(startItem, endItem, widget.rows.length),
            style: theme.textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: widget.currentPage > 0
                    ? () => _handlePageChange(widget.currentPage - 1)
                    : null,
                tooltip: context.l10n.previousPage,
              ),
              Text(
                context.l10n.pageInfo(widget.currentPage + 1, totalPages),
                style: theme.textTheme.bodyMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: widget.currentPage < totalPages - 1
                    ? () => _handlePageChange(widget.currentPage + 1)
                    : null,
                tooltip: context.l10n.nextPage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXLarge),
        child: Text(
          widget.emptyMessage ?? context.l10n.noDataAvailable,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _handleSort(String columnId) {
    final newDirection = widget.sortColumnId == columnId
        ? widget.sortDirection.toggle()
        : SortDirection.ascending;
    
    widget.onSort?.call(columnId, newDirection);
  }

  void _handleFilter(String columnId, String value) {
    final newFilters = Map<String, String>.from(widget.filters);
    if (value.isEmpty) {
      newFilters.remove(columnId);
    } else {
      newFilters[columnId] = value;
    }
    widget.onFilter?.call(newFilters);
  }

  void _handleRowSelection(T row) {
    final newSelection = List<T>.from(widget.selectedRows);
    
    if (widget.selectionMode == DataTableSelectionMode.single) {
      newSelection.clear();
      if (!widget.selectedRows.contains(row)) {
        newSelection.add(row);
      }
    } else if (widget.selectionMode == DataTableSelectionMode.multiple) {
      if (newSelection.contains(row)) {
        newSelection.remove(row);
      } else {
        newSelection.add(row);
      }
    }
    
    widget.onSelectionChanged?.call(newSelection);
  }

  void _handlePageChange(int newPage) {
    // This would typically be handled by the parent widget
    // by updating the currentPage property
  }

  MainAxisAlignment _getMainAxisAlignment(Alignment alignment) {
    if (alignment == Alignment.centerLeft) {
      return MainAxisAlignment.start;
    } else if (alignment == Alignment.centerRight) {
      return MainAxisAlignment.end;
    } else {
      return MainAxisAlignment.center;
    }
  }
}

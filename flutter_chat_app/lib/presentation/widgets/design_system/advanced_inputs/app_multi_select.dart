import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// **Multi-Select Item**
///
/// Represents an item in the multi-select dropdown
class MultiSelectItem<T> {
  const MultiSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

/// **APP MULTI SELECT**
///
/// Dropdown with multiple selection support.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Checkbox list in dropdown
/// - Selected items as chips
/// - Search/filter options
/// - Select all/none buttons
/// - Chip removal
/// - Max selection limit
/// - Custom item rendering
/// - Dark mode support
///
/// **Usage**:
/// ```dart
/// AppMultiSelect<String>(
///   items: [
///     MultiSelectItem(value: '1', label: 'Option 1'),
///     MultiSelectItem(value: '2', label: 'Option 2'),
///   ],
///   selectedValues: _selectedValues,
///   onChanged: (values) => setState(() => _selectedValues = values),
///   label: context.l10n.selectOptions,
/// )
/// ```
class AppMultiSelect<T> extends BaseStatefulWidget {
  const AppMultiSelect({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.searchable = true,
    this.showSelectAll = true,
    this.maxSelections,
    this.itemBuilder,
    this.chipBuilder,
    this.isDisabled = false,
  });

  /// List of items to select from
  final List<MultiSelectItem<T>> items;

  /// Currently selected values
  final List<T> selectedValues;

  /// Callback when selection changes
  final ValueChanged<List<T>> onChanged;

  /// Label text
  final String? label;

  /// Placeholder text
  final String? placeholder;

  /// Whether to show search field
  final bool searchable;

  /// Whether to show select all/none buttons
  final bool showSelectAll;

  /// Maximum number of selections allowed
  final int? maxSelections;

  /// Custom item builder
  final Widget Function(MultiSelectItem<T> item, bool isSelected)? itemBuilder;

  /// Custom chip builder
  final Widget Function(MultiSelectItem<T> item)? chipBuilder;

  /// Whether dropdown is disabled
  final bool isDisabled;

  @override
  AppMultiSelectState<T> createState() => AppMultiSelectState<T>();
}

class AppMultiSelectState<T> extends BaseState<AppMultiSelect<T>> {
  final TextEditingController _searchController = TextEditingController();
  bool _isOpen = false;
  List<MultiSelectItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    safeSetState(() {
      _filteredItems = widget.items
          .where((item) => item.label.toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleDropdown() {
    if (widget.isDisabled) return;
    safeSetState(() {
      _isOpen = !_isOpen;
      if (!_isOpen) {
        _searchController.clear();
        _filteredItems = widget.items;
      }
    });
  }

  void _toggleItem(T value) {
    final newValues = List<T>.from(widget.selectedValues);

    if (newValues.contains(value)) {
      newValues.remove(value);
    } else {
      if (widget.maxSelections != null &&
          newValues.length >= widget.maxSelections!) {
        return;
      }
      newValues.add(value);
    }

    widget.onChanged(newValues);
  }

  void _selectAll() {
    if (widget.maxSelections != null &&
        widget.items.length > widget.maxSelections!) {
      widget.onChanged(
        widget.items.take(widget.maxSelections!).map((e) => e.value).toList(),
      );
    } else {
      widget.onChanged(widget.items.map((e) => e.value).toList());
    }
  }

  void _selectNone() {
    widget.onChanged([]);
  }

  void _removeChip(T value) {
    final newValues = List<T>.from(widget.selectedValues);
    newValues.remove(value);
    widget.onChanged(newValues);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDarkMode
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimens.spaceSmall),
        ],
        InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingMedium),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
              border: Border.all(
                color: isDark ? AppColors.borderDarkMode : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.selectedValues.isEmpty
                      ? Text(
                          widget.placeholder ?? l10n.selectAll,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDarkMode
                                : AppColors.textSecondary,
                          ),
                        )
                      : Text(
                          '${widget.selectedValues.length} ${l10n.selected}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDarkMode
                                : AppColors.textPrimary,
                          ),
                        ),
                ),
                Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: isDark ? AppColors.iconDarkMode : AppColors.icon,
                ),
              ],
            ),
          ),
        ),
        if (widget.selectedValues.isNotEmpty) ...[
          const SizedBox(height: AppDimens.spaceSmall),
          Wrap(
            spacing: AppDimens.spaceSmall,
            runSpacing: AppDimens.spaceSmall,
            children: widget.selectedValues.map((value) {
              final item = widget.items.firstWhere((i) => i.value == value);
              return widget.chipBuilder?.call(item) ??
                  _buildDefaultChip(item, isDark);
            }).toList(),
          ),
        ],
        if (_isOpen) ...[
          const SizedBox(height: AppDimens.spaceSmall),
          _buildDropdown(isDark),
        ],
      ],
    );
  }

  Widget _buildDefaultChip(MultiSelectItem<T> item, bool isDark) {
    return Chip(
      label: Text(item.label),
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: isDark ? AppColors.iconDarkMode : AppColors.icon,
      ),
      onDeleted: () => _removeChip(item.value),
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDropdown(bool isDark) {
    final l10n = context.l10n;
    
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 300,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        border: Border.all(
          color: isDark ? AppColors.borderDarkMode : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.searchable) ...[
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingSmall),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.loading,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDarkMode
                        : AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? AppColors.iconDarkMode : AppColors.icon,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDarkMode : AppColors.border,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingSmall,
                    vertical: AppDimens.paddingSmall,
                  ),
                ),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDarkMode
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
          if (widget.showSelectAll) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingSmall,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _selectAll,
                      child: Text(l10n.selectAll),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _selectNone,
                      child: Text(l10n.selectNone),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? AppColors.borderDarkMode : AppColors.border,
              height: 1,
            ),
          ],
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = widget.selectedValues.contains(item.value);

                return widget.itemBuilder?.call(item, isSelected) ??
                    CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggleItem(item.value),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDarkMode
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: item.subtitle != null
                          ? Text(
                              item.subtitle!,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDarkMode
                                    : AppColors.textSecondary,
                              ),
                            )
                          : null,
                      activeColor: AppColors.primary,
                      dense: true,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

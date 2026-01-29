import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/badges/badge_enums.dart';

/// A customizable chip component.
///
/// Features:
/// - Filter chips (can be selected)
/// - Choice chips (single selection)
/// - Action chips (trigger action)
/// - Input chips (can be deleted)
/// - Avatar support
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// // Filter chip
/// AppChip.filter(
///   label: 'Active',
///   selected: true,
///   onSelected: (selected) {},
/// )
///
/// // Action chip
/// AppChip.action(
///   label: 'Add',
///   icon: Icons.add,
///   onPressed: () {},
/// )
///
/// // Input chip
/// AppChip.input(
///   label: 'Tag',
///   onDeleted: () {},
/// )
/// ```
class AppChip extends BaseStatelessWidget {
  /// Creates an [AppChip].
  const AppChip({
    required this.label,
    this.type = ChipType.action,
    this.icon,
    this.avatar,
    this.selected = false,
    this.onSelected,
    this.onPressed,
    this.onDeleted,
    this.backgroundColor,
    this.selectedColor,
    this.labelStyle,
    super.key,
  });

  /// Creates a filter chip.
  const AppChip.filter({
    required String label,
    bool selected = false,
    ValueChanged<bool>? onSelected,
    IconData? icon,
    Widget? avatar,
    Color? backgroundColor,
    Color? selectedColor,
    TextStyle? labelStyle,
    Key? key,
  }) : this(
          label: label,
          type: ChipType.filter,
          selected: selected,
          onSelected: onSelected,
          icon: icon,
          avatar: avatar,
          backgroundColor: backgroundColor,
          selectedColor: selectedColor,
          labelStyle: labelStyle,
          key: key,
        );

  /// Creates a choice chip.
  const AppChip.choice({
    required String label,
    bool selected = false,
    ValueChanged<bool>? onSelected,
    Widget? avatar,
    Color? backgroundColor,
    Color? selectedColor,
    TextStyle? labelStyle,
    Key? key,
  }) : this(
          label: label,
          type: ChipType.choice,
          selected: selected,
          onSelected: onSelected,
          avatar: avatar,
          backgroundColor: backgroundColor,
          selectedColor: selectedColor,
          labelStyle: labelStyle,
          key: key,
        );

  /// Creates an action chip.
  const AppChip.action({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    Widget? avatar,
    Color? backgroundColor,
    TextStyle? labelStyle,
    Key? key,
  }) : this(
          label: label,
          type: ChipType.action,
          onPressed: onPressed,
          icon: icon,
          avatar: avatar,
          backgroundColor: backgroundColor,
          labelStyle: labelStyle,
          key: key,
        );

  /// Creates an input chip.
  const AppChip.input({
    required String label,
    VoidCallback? onDeleted,
    VoidCallback? onPressed,
    Widget? avatar,
    Color? backgroundColor,
    TextStyle? labelStyle,
    Key? key,
  }) : this(
          label: label,
          type: ChipType.input,
          onDeleted: onDeleted,
          onPressed: onPressed,
          avatar: avatar,
          backgroundColor: backgroundColor,
          labelStyle: labelStyle,
          key: key,
        );

  /// The label text.
  final String label;

  /// The type of chip.
  final ChipType type;

  /// Optional icon.
  final IconData? icon;

  /// Optional avatar widget.
  final Widget? avatar;

  /// Whether the chip is selected.
  final bool selected;

  /// Called when selection changes (filter/choice chips).
  final ValueChanged<bool>? onSelected;

  /// Called when chip is pressed (action/input chips).
  final VoidCallback? onPressed;

  /// Called when delete icon is pressed (input chips).
  final VoidCallback? onDeleted;

  /// Background color.
  final Color? backgroundColor;

  /// Selected color.
  final Color? selectedColor;

  /// Label text style.
  final TextStyle? labelStyle;

  @override
  Widget buildContent(BuildContext context) {
    switch (type) {
      case ChipType.filter:
        return FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: onSelected,
          avatar: avatar ?? (icon != null ? Icon(icon, size: AppDimens.iconSmall) : null),
          backgroundColor: backgroundColor,
          selectedColor: selectedColor,
          labelStyle: labelStyle,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingSmall,
            vertical: AppDimens.paddingXSmall,
          ),
        );

      case ChipType.choice:
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: onSelected,
          avatar: avatar,
          backgroundColor: backgroundColor,
          selectedColor: selectedColor,
          labelStyle: labelStyle,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingSmall,
            vertical: AppDimens.paddingXSmall,
          ),
        );

      case ChipType.action:
        return ActionChip(
          label: Text(label),
          onPressed: onPressed,
          avatar: avatar ?? (icon != null ? Icon(icon, size: AppDimens.iconSmall) : null),
          backgroundColor: backgroundColor,
          labelStyle: labelStyle,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingSmall,
            vertical: AppDimens.paddingXSmall,
          ),
        );

      case ChipType.input:
        return InputChip(
          label: Text(label),
          onPressed: onPressed,
          onDeleted: onDeleted,
          avatar: avatar,
          backgroundColor: backgroundColor,
          labelStyle: labelStyle,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingSmall,
            vertical: AppDimens.paddingXSmall,
          ),
        );
    }
  }
}

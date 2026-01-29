import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/data/data_enums.dart';

/// **APP ACCORDION**
///
/// Collapsible accordion component with smooth expand/collapse animation.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Single or multiple expansion modes
/// - Smooth height animation
/// - Custom header and content
/// - Expand/collapse icons
/// - Initial expanded state support
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with animation controller
///
/// **Usage**:
/// ```dart
/// // Single expansion mode
/// AppAccordion(
///   mode: AccordionMode.single,
///   sections: [
///     AccordionSection(
///       header: Text(context.l10n.section1),
///       content: Text(context.l10n.content1),
///     ),
///     AccordionSection(
///       header: Text(context.l10n.section2),
///       content: Text(context.l10n.content2),
///     ),
///   ],
/// )
///
/// // Multiple expansion mode with initial expanded
/// AppAccordion(
///   mode: AccordionMode.multiple,
///   initialExpandedIndexes: [0, 2],
///   sections: sections,
/// )
/// ```
class AppAccordion extends BaseStatefulWidget {
  /// Creates an accordion.
  const AppAccordion({
    super.key,
    required this.sections,
    this.mode = AccordionMode.single,
    this.initialExpandedIndexes = const [],
    this.expandIcon,
    this.collapseIcon,
    this.headerPadding,
    this.contentPadding,
    this.dividerColor,
    this.animationDuration,
    this.animationCurve = AccordionAnimationCurve.easeInOut,
    this.onExpansionChanged,
  });

  /// List of accordion sections
  final List<AccordionSection> sections;

  /// Expansion mode (single or multiple)
  final AccordionMode mode;

  /// Initially expanded section indexes
  final List<int> initialExpandedIndexes;

  /// Custom expand icon
  final Widget? expandIcon;

  /// Custom collapse icon
  final Widget? collapseIcon;

  /// Header padding
  final EdgeInsetsGeometry? headerPadding;

  /// Content padding
  final EdgeInsetsGeometry? contentPadding;

  /// Divider color
  final Color? dividerColor;

  /// Animation duration
  final Duration? animationDuration;

  /// Animation curve
  final AccordionAnimationCurve animationCurve;

  /// Callback when expansion state changes
  final ValueChanged<List<int>>? onExpansionChanged;

  @override
  State<AppAccordion> createState() => _AppAccordionState();
}

class _AppAccordionState extends BaseState<AppAccordion> {
  late Set<int> _expandedIndexes;

  @override
  void initState() {
    super.initState();
    _expandedIndexes = Set.from(widget.initialExpandedIndexes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.sections.length,
        (index) => _buildSection(context, index, isDark),
      ),
    );
  }

  Widget _buildSection(BuildContext context, int index, bool isDark) {
    final section = widget.sections[index];
    final isExpanded = _expandedIndexes.contains(index);
    final isLast = index == widget.sections.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, section, index, isExpanded, isDark),
        AnimatedSize(
          duration: widget.animationDuration ?? AppConstants.kDefaultAnimationDuration,
          curve: _getCurve(),
          child: isExpanded
              ? _buildContent(context, section, isDark)
              : const SizedBox.shrink(),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: widget.dividerColor ??
                (isDark ? AppColors.borderDarkMode : AppColors.border),
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AccordionSection section,
    int index,
    bool isExpanded,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: section.isDisabled ? null : () => _toggleSection(index),
        child: Padding(
          padding: widget.headerPadding ??
              const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingMedium,
                vertical: AppDimens.paddingMedium,
              ),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: section.isDisabled
                        ? (isDark
                            ? AppColors.textSecondaryDarkMode.withValues(alpha: 0.38)
                            : AppColors.textSecondary.withValues(alpha: 0.38))
                        : null,
                  ),
                  child: section.header,
                ),
              ),
              const SizedBox(width: AppDimens.spaceSmall),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: widget.animationDuration ?? AppConstants.kDefaultAnimationDuration,
                curve: _getCurve(),
                child: widget.expandIcon ??
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: section.isDisabled
                          ? (isDark
                              ? AppColors.iconDarkMode.withValues(alpha: 0.38)
                              : AppColors.icon.withValues(alpha: 0.38))
                          : (isDark ? AppColors.iconDarkMode : AppColors.icon),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AccordionSection section,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: widget.contentPadding ??
          const EdgeInsets.only(
            left: AppDimens.paddingMedium,
            right: AppDimens.paddingMedium,
            bottom: AppDimens.paddingMedium,
          ),
      child: section.content,
    );
  }

  void _toggleSection(int index) {
    safeSetState(() {
      if (widget.mode == AccordionMode.single) {
        // Single mode: close all others
        if (_expandedIndexes.contains(index)) {
          _expandedIndexes.clear();
        } else {
          _expandedIndexes.clear();
          _expandedIndexes.add(index);
        }
      } else {
        // Multiple mode: toggle individual section
        if (_expandedIndexes.contains(index)) {
          _expandedIndexes.remove(index);
        } else {
          _expandedIndexes.add(index);
        }
      }

      widget.onExpansionChanged?.call(_expandedIndexes.toList());
    });
  }

  Curve _getCurve() {
    switch (widget.animationCurve) {
      case AccordionAnimationCurve.linear:
        return Curves.linear;
      case AccordionAnimationCurve.easeIn:
        return Curves.easeIn;
      case AccordionAnimationCurve.easeOut:
        return Curves.easeOut;
      case AccordionAnimationCurve.easeInOut:
        return Curves.easeInOut;
      case AccordionAnimationCurve.bounce:
        return Curves.bounceOut;
      case AccordionAnimationCurve.elastic:
        return Curves.elasticOut;
    }
  }
}

/// Accordion section data model
class AccordionSection {
  /// Creates an accordion section.
  const AccordionSection({
    required this.header,
    required this.content,
    this.isDisabled = false,
  });

  /// Header widget
  final Widget header;

  /// Content widget
  final Widget content;

  /// Whether section is disabled
  final bool isDisabled;
}

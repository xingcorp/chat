import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/conversation_type_filter.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Tab bar for filtering conversations by type (All / Direct / Group).
///
/// Sliding pill-style tab bar with animated background indicator.
class ConversationTypeTabBar extends BaseStatelessWidget {
  const ConversationTypeTabBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final ConversationTypeFilter activeFilter;
  final ValueChanged<ConversationTypeFilter> onFilterChanged;

  @override
  Widget buildContent(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      (ConversationTypeFilter.all, l10n.allConversations),
      (ConversationTypeFilter.direct, l10n.directConversations),
      (ConversationTypeFilter.group, l10n.groupConversations),
    ];

    return _PillTabBarContent(
      filters: filters,
      activeFilter: activeFilter,
      onFilterChanged: onFilterChanged,
      isDark: isDark,
    );
  }
}

class _PillTabBarContent extends BaseStatefulWidget {
  const _PillTabBarContent({
    required this.filters,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.isDark,
  });

  final List<(ConversationTypeFilter, String)> filters;
  final ConversationTypeFilter activeFilter;
  final ValueChanged<ConversationTypeFilter> onFilterChanged;
  final bool isDark;

  @override
  State<_PillTabBarContent> createState() => _PillTabBarContentState();
}

class _PillTabBarContentState extends BaseState<_PillTabBarContent> {
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    final index = widget.filters.indexWhere(
      (f) => f.$1 == widget.activeFilter,
    );
    _activeIndex = index >= 0 ? index : 0;
  }

  @override
  void didUpdateWidget(covariant _PillTabBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync internal index with external activeFilter changes
    final targetIndex = widget.filters.indexWhere(
      (f) => f.$1 == widget.activeFilter,
    );
    if (targetIndex >= 0 && _activeIndex != targetIndex) {
      safeSetState(() {
        _activeIndex = targetIndex;
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == _activeIndex) return;
    safeSetState(() {
      _activeIndex = index;
    });
    widget.onFilterChanged(widget.filters[index].$1);
  }

  @override
  Widget build(BuildContext context) {
    final tabCount = widget.filters.length;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.surfaceDarkMode
            : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: widget.isDark
                ? AppColors.dividerDarkMode
                : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingSmall,
        vertical: AppDimens.paddingSmall,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabCount;

          return SizedBox(
            height: AppDimens.tabPillHeight,
            child: Stack(
              children: [
                // Animated pill background
                AnimatedPositioned(
                  duration: const Duration(
                    milliseconds: AppDimens.durationMedium,
                  ),
                  curve: Curves.easeInOut,
                  left: tabWidth * _activeIndex,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? AppColors.tabPillBgDark
                          : AppColors.tabPillBg,
                      borderRadius: BorderRadius.circular(
                        AppDimens.tabPillRadius,
                      ),
                    ),
                  ),
                ),
                // Tab labels row
                Row(
                  children: List.generate(tabCount, (index) {
                    final isActive = index == _activeIndex;
                    final label = widget.filters[index].$2;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onTabTapped(index),
                        child: SizedBox(
                          height: AppDimens.tabPillHeight,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(
                                milliseconds: AppDimens.durationMedium,
                              ),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isActive
                                    ? AppColors.primary
                                    : widget.isDark
                                        ? AppColors.textSecondaryDarkMode
                                        : AppColors.textSecondary,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

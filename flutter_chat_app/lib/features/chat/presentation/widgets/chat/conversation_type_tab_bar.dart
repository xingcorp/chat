import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/domain/entities/conversation_type_filter.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Tab bar for filtering conversations by type (All / Direct / Group).
///
/// Zalo-style TabBar with underline indicator, replaces previous chip buttons.
class ConversationTypeTabBar extends StatelessWidget {
  const ConversationTypeTabBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final ConversationTypeFilter activeFilter;
  final ValueChanged<ConversationTypeFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      (ConversationTypeFilter.all, l10n.allConversations),
      (ConversationTypeFilter.direct, l10n.directConversations),
      (ConversationTypeFilter.group, l10n.groupConversations),
    ];

    final activeIndex = filters.indexWhere((f) => f.$1 == activeFilter);

    return DefaultTabController(
      length: filters.length,
      initialIndex: activeIndex >= 0 ? activeIndex : 0,
      child: _TabBarContent(
        filters: filters,
        activeFilter: activeFilter,
        onFilterChanged: onFilterChanged,
        isDark: isDark,
      ),
    );
  }
}

class _TabBarContent extends StatefulWidget {
  const _TabBarContent({
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
  State<_TabBarContent> createState() => _TabBarContentState();
}

class _TabBarContentState extends State<_TabBarContent> {
  late TabController _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController = DefaultTabController.of(context);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant _TabBarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync tab controller with external activeFilter changes
    final targetIndex = widget.filters.indexWhere((f) => f.$1 == widget.activeFilter);
    if (targetIndex >= 0 && _tabController.index != targetIndex) {
      _tabController.animateTo(targetIndex);
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final selected = widget.filters[_tabController.index].$1;
      if (selected != widget.activeFilter) {
        widget.onFilterChanged(selected);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: widget.isDark ? AppColors.dividerDarkMode : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: widget.isDark
            ? AppColors.textSecondaryDarkMode
            : AppColors.textSecondary,
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelPadding: EdgeInsets.zero,
        tabs: widget.filters.map((f) {
          return Tab(
            text: f.$2,
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/domain/entities/conversation_type_filter.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/badges/app_chip.dart';

/// Tab bar for filtering conversations by type (All / Direct / Group).
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
    final filters = [
      (ConversationTypeFilter.all, l10n.allConversations),
      (ConversationTypeFilter.direct, l10n.directConversations),
      (ConversationTypeFilter.group, l10n.groupConversations),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMedium,
        vertical: AppDimens.paddingSmall,
      ),
      child: Row(
        children: [
          for (int i = 0; i < filters.length; i++) ...[
            if (i > 0)
              const SizedBox(width: AppDimens.spaceSmall),
            AppChip.choice(
              label: filters[i].$2,
              selected: activeFilter == filters[i].$1,
              selectedColor: AppColors.primary,
              onSelected: (selected) {
                if (selected) onFilterChanged(filters[i].$1);
              },
            ),
          ],
        ],
      ),
    );
  }
}

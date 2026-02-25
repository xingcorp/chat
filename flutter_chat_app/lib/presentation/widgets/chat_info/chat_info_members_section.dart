import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Members section row for group chat info panel
/// Clickable row that navigates to full members list page
class ChatInfoMembersSection extends BaseStatelessWidget {
  final Chat chat;
  final VoidCallback? onTap;

  const ChatInfoMembersSection({
    super.key,
    required this.chat,
    this.onTap,
  });

  @override
  Widget buildContent(BuildContext context) {
    // Only show for group chats
    if (chat.type != ChatType.group) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingMedium,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryDarkMode : AppColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Icon(
                Icons.people_outline,
                color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
                size: 20,
              ),
            ),

            const SizedBox(width: AppDimens.spaceSmall),

            // Title and member count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    l10n.members,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDarkMode
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '${chat.members.length} ${l10n.members}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDarkMode
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Settings section widget for chat info panel
class ChatInfoSettingsSection extends BaseStatelessWidget {
  final bool isMuted;
  final bool isBlocked;
  final bool isGroup;
  final bool isActionInProgress;
  final VoidCallback onMuteToggle;
  final VoidCallback onBlockToggle;
  final VoidCallback onReport;
  final VoidCallback onLeaveGroup;
  final VoidCallback onDeleteChat;

  const ChatInfoSettingsSection({
    super.key,
    required this.isMuted,
    required this.isBlocked,
    required this.isGroup,
    this.isActionInProgress = false,
    required this.onMuteToggle,
    required this.onBlockToggle,
    required this.onReport,
    required this.onLeaveGroup,
    required this.onDeleteChat,
  });

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Settings title
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
          child: AppText(
            context.l10n.settings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        const SizedBox(height: AppDimens.spaceSmall),

        // Unsupported chat settings are temporarily hidden until backend
        // support for notification, block and report flows is implemented.

        const SizedBox(height: AppDimens.spaceSmall),

        // Danger zone card
        AppCard.elevated(
          margin:
              const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
          padding: const EdgeInsets.all(AppDimens.paddingMedium),
          child: Column(
            children: [
              if (isGroup) ...[
                // Leave group
                _buildSettingRow(
                  context: context,
                  icon: Icons.exit_to_app,
                  title: context.l10n.leaveGroup,
                  subtitle: context.l10n.leaveThisGroup,
                  onTap: isActionInProgress ? null : onLeaveGroup,
                  isDestructive: true,
                ),
                const Divider(height: 1),
              ],

              // Delete chat
              _buildSettingRow(
                context: context,
                icon: Icons.delete,
                title: context.l10n.deleteChat,
                subtitle: context.l10n.deleteThisConversation,
                onTap: isActionInProgress ? null : onDeleteChat,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary);
    final titleColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.paddingSmall,
          horizontal: AppDimens.paddingSmall,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(width: AppDimens.spaceSmall),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    AppText(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDarkMode
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],
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

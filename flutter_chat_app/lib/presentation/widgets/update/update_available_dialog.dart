import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/domain/entities/app_update_info.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_event.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Full-screen dialog showing release details when an update is available.
///
/// Shows: version, file size, release notes (scrollable), and action buttons.
/// - [Download Now] → starts download
/// - [Skip This Version] → skips this version
/// - [Remind Me Later] → snoozes for 24h
class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({
    required this.updateInfo,
    super.key,
  });

  final AppUpdateInfo updateInfo;

  /// Show the dialog and return the user's choice.
  static Future<void> show(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (_) => BlocProvider.value(
        value: context.read<UpdateBloc>(),
        child: UpdateAvailableDialog(updateInfo: updateInfo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      ),
      contentPadding: const EdgeInsets.all(AppDimens.spaceLarge),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.spaceSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: Icon(
                    Icons.system_update_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppDimens.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        context.l10n.newVersionAvailable,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        'v${updateInfo.version} (${updateInfo.fileSizeFormatted})',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.spaceMedium),
            const Divider(height: 1),
            const SizedBox(height: AppDimens.spaceMedium),

            // What's New section
            AppText(
              context.l10n.whatsNew,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimens.spaceSmall),

            // Release notes (scrollable)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: AppText(
                  updateInfo.releaseNotes.isNotEmpty
                      ? updateInfo.releaseNotes
                      : context.l10n.noReleaseNotes,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDarkMode
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimens.spaceLarge),

            // Force update warning
            if (updateInfo.isForceUpdate) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.spaceSmall),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: AppDimens.spaceSmall),
                    Expanded(
                      child: AppText(
                        context.l10n.mandatoryUpdate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spaceMedium),
            ],

            // Action buttons
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppDimens.spaceSmall,
              runSpacing: AppDimens.spaceSmall,
              children: [
                if (!updateInfo.isForceUpdate) ...[
                  TextButton(
                    onPressed: () {
                      context.read<UpdateBloc>().add(
                        SkipVersionRequested(version: updateInfo.version),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(context.l10n.skipThisVersion),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<UpdateBloc>().add(
                        const RemindLaterRequested(),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(context.l10n.remindMeLater),
                  ),
                ],
                AppButton.primary(
                  text: context.l10n.downloadUpdate,
                  onPressed: () {
                    context.read<UpdateBloc>().add(
                      DownloadUpdateRequested(updateInfo: updateInfo),
                    );
                    Navigator.of(context).pop();
                  },
                  size: ButtonSize.small,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

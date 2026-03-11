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

/// Dialog shown when the update download is complete and ready to install.
///
/// Prompts the user to restart the app to apply the update.
/// - [Restart Now] → launches installer and exits
/// - [Later] → dismisses, will show banner instead
class UpdateReadyDialog extends StatelessWidget {
  const UpdateReadyDialog({
    required this.updateInfo,
    required this.installerPath,
    super.key,
  });

  final AppUpdateInfo updateInfo;
  final String installerPath;

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    required String installerPath,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<UpdateBloc>(),
        child: UpdateReadyDialog(
          updateInfo: updateInfo,
          installerPath: installerPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      ),
      contentPadding: const EdgeInsets.all(AppDimens.spaceLarge),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(AppDimens.spaceMedium),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: AppDimens.spaceMedium),

            AppText(
              context.l10n.updateReady,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimens.spaceSmall),

            AppText(
              context.l10n.restartToApplyUpdate(updateInfo.version),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimens.spaceLarge),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    text: context.l10n.later,
                    onPressed: () => Navigator.of(context).pop(),
                    size: ButtonSize.medium,
                  ),
                ),
                const SizedBox(width: AppDimens.spaceMedium),
                Expanded(
                  child: AppButton.primary(
                    text: context.l10n.restartNow,
                    icon: Icons.refresh,
                    onPressed: () {
                      context.read<UpdateBloc>().add(
                        InstallUpdateRequested(installerPath: installerPath),
                      );
                    },
                    size: ButtonSize.medium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

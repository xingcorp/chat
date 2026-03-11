import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_event.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_state.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Dialog showing download progress with cancel button.
///
/// Auto-dismisses when download completes or is cancelled.
class UpdateProgressDialog extends StatelessWidget {
  const UpdateProgressDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<UpdateBloc>(),
        child: const UpdateProgressDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateBloc, UpdateState>(
      listener: (context, state) {
        // Auto-dismiss when download finishes, fails, or is cancelled
        if (state is! UpdateDownloading) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state is! UpdateDownloading) {
          return const SizedBox.shrink();
        }

        final percent = (state.progress * 100).toInt();
        final receivedMB = (state.receivedBytes / (1024 * 1024)).toStringAsFixed(1);
        final totalMB = (state.totalBytes / (1024 * 1024)).toStringAsFixed(1);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          ),
          contentPadding: const EdgeInsets.all(AppDimens.spaceLarge),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_download_outlined,
                  color: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(height: AppDimens.spaceMedium),
                AppText(
                  context.l10n.downloadingUpdate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimens.spaceLarge),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.progress > 0 ? state.progress : null,
                    minHeight: 6,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppDimens.spaceSmall),

                // Progress text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    AppText(
                      '$receivedMB / $totalMB MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.spaceLarge),

                // Cancel button
                AppButton.text(
                  text: context.l10n.cancel,
                  onPressed: () {
                    context.read<UpdateBloc>().add(
                      const CancelDownloadRequested(),
                    );
                  },
                  size: ButtonSize.small,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

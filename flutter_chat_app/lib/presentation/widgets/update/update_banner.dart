import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_event.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_state.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// A non-intrusive top banner that appears when an update is available,
/// downloading, or ready to install.
///
/// Listens to [UpdateBloc] and auto-shows/hides based on state.
/// Does NOT show during idle/checking/error states.
class UpdateBanner extends BaseStatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget buildContent(BuildContext context) {
    return BlocBuilder<UpdateBloc, UpdateState>(
      builder: (context, state) {
        if (state is UpdateAvailable) {
          return _buildAvailableBanner(context, state);
        }
        if (state is UpdateDownloading) {
          return _buildDownloadingBanner(context, state);
        }
        if (state is UpdateReadyToInstall) {
          return _buildReadyBanner(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAvailableBanner(BuildContext context, UpdateAvailable state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMedium,
        vertical: AppDimens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.system_update_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Expanded(
            child: AppText(
              context.l10n.updateAvailableVersion(state.updateInfo.version),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          _BannerButton(
            label: context.l10n.updateNow,
            onPressed: () {
              context.read<UpdateBloc>().add(
                DownloadUpdateRequested(updateInfo: state.updateInfo),
              );
            },
          ),
          const SizedBox(width: AppDimens.spaceXSmall),
          _CloseButton(
            onPressed: () {
              context.read<UpdateBloc>().add(const UpdateDismissed());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingBanner(BuildContext context, UpdateDownloading state) {
    final percent = (state.progress * 100).toInt();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMedium,
        vertical: AppDimens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: state.progress > 0 ? state.progress : null,
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  '${context.l10n.downloading} $percent%',
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: state.progress > 0 ? state.progress : null,
                    minHeight: 3,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          _CloseButton(
            onPressed: () {
              context.read<UpdateBloc>().add(const CancelDownloadRequested());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadyBanner(BuildContext context, UpdateReadyToInstall state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMedium,
        vertical: AppDimens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          Expanded(
            child: AppText(
              context.l10n.restartToUpdate,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spaceSmall),
          _BannerButton(
            label: context.l10n.restartNow,
            color: Colors.green,
            onPressed: () {
              context.read<UpdateBloc>().add(
                InstallUpdateRequested(installerPath: state.installerPath),
              );
            },
          ),
          const SizedBox(width: AppDimens.spaceXSmall),
          _CloseButton(
            onPressed: () {
              context.read<UpdateBloc>().add(const RemindLaterRequested());
            },
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spaceSmall,
          vertical: AppDimens.spaceXSmall,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: buttonColor,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.close,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

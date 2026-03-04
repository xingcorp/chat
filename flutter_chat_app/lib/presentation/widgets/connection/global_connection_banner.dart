import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/theme/app_theme_extensions.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/realtime_connection/realtime_connection_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/app_card.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';

/// Wraps content and renders a global top connection banner above all routes.
///
/// Uses a column layout (not overlay) so the banner does not cover app bars
/// and main content.
class GlobalConnectionBannerScope extends StatelessWidget {
  const GlobalConnectionBannerScope({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GlobalConnectionBanner(),
        Expanded(child: child),
      ],
    );
  }
}

/// Global top banner for internet/server connection status.
///
/// Source of truth is [RealtimeConnectionBloc].
/// Auth state automatically drives connect/disconnect lifecycle.
class GlobalConnectionBanner extends StatefulWidget {
  const GlobalConnectionBanner({super.key});

  @override
  State<GlobalConnectionBanner> createState() => _GlobalConnectionBannerState();
}

class _GlobalConnectionBannerState extends State<GlobalConnectionBanner> {
  bool _didInitialAuthSync = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialAuthSync) return;
    _didInitialAuthSync = true;
    _syncRealtimeConnectionWithAuth(context.read<AuthBloc>().state);
  }

  void _syncRealtimeConnectionWithAuth(AuthState authState) {
    final connectionBloc = _tryGetConnectionBloc(context);
    if (connectionBloc == null) {
      return;
    }

    if (authState.isAuthenticated) {
      connectionBloc.add(const ConnectToRealtime());
      return;
    }

    connectionBloc.add(
      const DisconnectFromRealtime(
        reason: 'User unauthenticated',
        issueType: RealtimeConnectionIssueType.auth,
      ),
    );
  }

  RealtimeConnectionBloc? _tryGetConnectionBloc(BuildContext context) {
    try {
      return context.read<RealtimeConnectionBloc>();
    } catch (_) {
      return null;
    }
  }

  _BannerModel? _buildBannerModel(
    BuildContext context,
    RealtimeConnectionState state,
    bool isAuthenticated,
  ) {
    if (!isAuthenticated) return null;

    if (state is RealtimeConnectionConnecting ||
        state is RealtimeConnectionReconnecting) {
      return _BannerModel(
        message: context.l10n.reconnecting,
        kind: _BannerKind.reconnecting,
      );
    }

    if (state is RealtimeConnectionDisconnected) {
      final kind = switch (state.issueType) {
        RealtimeConnectionIssueType.network => _BannerKind.offline,
        RealtimeConnectionIssueType.server => _BannerKind.server,
        RealtimeConnectionIssueType.auth => _BannerKind.server,
        RealtimeConnectionIssueType.unknown => _BannerKind.server,
      };

      final message = switch (state.issueType) {
        RealtimeConnectionIssueType.network =>
          context.l10n.noInternetConnection,
        RealtimeConnectionIssueType.server => context.l10n.connectionLost,
        RealtimeConnectionIssueType.auth => context.l10n.connectionLost,
        RealtimeConnectionIssueType.unknown => context.l10n.connectionLost,
      };

      return _BannerModel(
        message: message,
        kind: kind,
        action: state.canRetry
            ? AppButton.text(
                text: context.l10n.retryOperation,
                onPressed: () => context
                    .read<RealtimeConnectionBloc>()
                    .add(const ReconnectToRealtime()),
                size: ButtonSize.small,
              )
            : null,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final connectionBloc = _tryGetConnectionBloc(context);
    if (connectionBloc == null) {
      return const SizedBox.shrink();
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.isAuthenticated != current.isAuthenticated,
          listener: (context, authState) =>
              _syncRealtimeConnectionWithAuth(authState),
        ),
      ],
      child: BlocBuilder<RealtimeConnectionBloc, RealtimeConnectionState>(
        bloc: connectionBloc,
        builder: (context, state) {
          final isAuthenticated = context.select<AuthBloc, bool>(
            (bloc) => bloc.state.isAuthenticated,
          );
          final banner = _buildBannerModel(context, state, isAuthenticated);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              );
            },
            child: banner == null
                ? const SizedBox.shrink()
                : SafeArea(
                    key: ValueKey<String>(banner.message),
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingMedium,
                        vertical: AppDimens.paddingXSmall,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppDimens.breakpointTablet,
                          ),
                          child: _ConnectionStatusBar(data: banner),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

enum _BannerKind {
  reconnecting,
  offline,
  server,
}

class _BannerModel {
  const _BannerModel({
    required this.message,
    required this.kind,
    this.action,
  });

  final String message;
  final _BannerKind kind;
  final Widget? action;
}

class _ConnectionStatusBar extends StatelessWidget {
  const _ConnectionStatusBar({
    required this.data,
  });

  final _BannerModel data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = _baseColor(context, data.kind);
    final textColor =
        isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;
    final borderColor = baseColor.withValues(alpha: isDark ? 0.55 : 0.35);
    final backgroundColor = baseColor.withValues(alpha: isDark ? 0.24 : 0.14);

    return AppCard.filled(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      borderRadius: AppDimens.radiusMedium,
      color: backgroundColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingSmall,
          ),
          child: Row(
            children: [
              Icon(
                _icon(data.kind),
                size: AppDimens.iconSizeSmall,
                color: baseColor,
              ),
              const SizedBox(width: AppDimens.spaceSmall),
              Expanded(
                child: AppText(
                  data.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmallCustom(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (data.action != null) ...[
                const SizedBox(width: AppDimens.spaceSmall),
                data.action!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _baseColor(BuildContext context, _BannerKind kind) {
    final extensions = Theme.of(context).appExtensions;
    return switch (kind) {
      _BannerKind.reconnecting => extensions.infoColor,
      _BannerKind.offline => extensions.warningColor,
      _BannerKind.server => Theme.of(context).colorScheme.error,
    };
  }

  IconData _icon(_BannerKind kind) {
    return switch (kind) {
      _BannerKind.reconnecting => Icons.sync_rounded,
      _BannerKind.offline => Icons.wifi_off_rounded,
      _BannerKind.server => Icons.cloud_off_rounded,
    };
  }
}

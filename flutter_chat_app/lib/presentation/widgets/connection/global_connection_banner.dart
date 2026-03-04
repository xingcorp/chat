import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/theme/app_theme_extensions.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/realtime_connection/realtime_connection_bloc.dart';
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

    if (authState is AuthAuthenticated) {
      connectionBloc.add(const ConnectToRealtime(source: 'auth_sync'));
      return;
    }

    if (authState is AuthUnauthenticated) {
      connectionBloc.add(
        const DisconnectFromRealtime(
          reason: 'User unauthenticated',
          issueType: RealtimeConnectionIssueType.auth,
          source: 'auth_sync',
        ),
      );
    }
  }

  RealtimeConnectionBloc? _tryGetConnectionBloc(BuildContext context) {
    try {
      return context.read<RealtimeConnectionBloc>();
    } catch (_) {
      return null;
    }
  }

  bool _isAuthResolved(AuthState state) {
    return state is AuthAuthenticated || state is AuthUnauthenticated;
  }

  _BannerModel? _buildBannerModel(
    BuildContext context,
    RealtimeConnectionState state,
    bool isAuthenticated,
  ) {
    if (!isAuthenticated) return null;

    // WhatsApp/Telegram pattern: only show connection banner after the user
    // has had at least one successful session. On cold start (initial connect),
    // the banner is suppressed — the user sees their cached chat list instead
    // of a jarring "Reconnecting..." bar.
    final connectionBloc = _tryGetConnectionBloc(context);
    if (connectionBloc != null && !connectionBloc.hasEverConnected) {
      return null;
    }

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
        canRetry: state.canRetry,
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
          listenWhen: (previous, current) {
            final currentResolved = _isAuthResolved(current);
            if (!currentResolved) return false;

            final previousResolved = _isAuthResolved(previous);
            if (!previousResolved) return true;

            return previous.isAuthenticated != current.isAuthenticated;
          },
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
                    child: _ConnectionStatusBar(data: banner),
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
    this.canRetry = false,
  });

  final String message;
  final _BannerKind kind;
  final bool canRetry;
}

class _BannerVisual {
  const _BannerVisual({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
}

class _ConnectionStatusBar extends StatelessWidget {
  const _ConnectionStatusBar({
    required this.data,
  });

  final _BannerModel data;

  @override
  Widget build(BuildContext context) {
    final visual = _visual(context, data.kind);
    final dividerColor = visual.accentColor.withValues(alpha: 0.34);

    return Material(
      color: visual.backgroundColor,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: dividerColor,
            ),
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
                color: visual.accentColor,
              ),
              const SizedBox(width: AppDimens.spaceSmall),
              Expanded(
                child: AppText(
                  data.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmallCustom(
                    color: visual.textColor,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              if (data.canRetry) ...[
                const SizedBox(width: AppDimens.spaceSmall),
                _RetryActionButton(
                  label: context.l10n.retryOperation,
                  foregroundColor: visual.accentColor,
                  onPressed: () => context
                      .read<RealtimeConnectionBloc>()
                      .add(const ReconnectToRealtime(source: 'user_retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _BannerVisual _visual(BuildContext context, _BannerKind kind) {
    final theme = Theme.of(context);
    final extensions = theme.appExtensions;
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final textColor =
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.96 : 0.92);

    final (baseColor, tintAlpha) = switch (kind) {
      _BannerKind.reconnecting => (
          extensions.infoColor,
          isDark ? 0.26 : 0.15,
        ),
      _BannerKind.offline => (
          extensions.warningColor,
          isDark ? 0.24 : 0.14,
        ),
      _BannerKind.server => (
          theme.colorScheme.error,
          isDark ? 0.22 : 0.12,
        ),
    };

    final backgroundColor = Color.alphaBlend(
      baseColor.withValues(alpha: tintAlpha),
      surface,
    );
    final accentColor = baseColor.withValues(alpha: isDark ? 0.95 : 0.90);

    return switch (kind) {
      _BannerKind.reconnecting => _BannerVisual(
          backgroundColor: backgroundColor,
          textColor: textColor,
          accentColor: accentColor,
        ),
      _BannerKind.offline => _BannerVisual(
          backgroundColor: backgroundColor,
          textColor: textColor,
          accentColor: accentColor,
        ),
      _BannerKind.server => _BannerVisual(
          backgroundColor: backgroundColor,
          textColor: textColor,
          accentColor: accentColor,
        ),
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

class _RetryActionButton extends StatelessWidget {
  const _RetryActionButton({
    required this.label,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimens.buttonHeightSmall,
            minWidth: AppDimens.buttonMinWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingSmall,
              vertical: AppDimens.paddingXSmall,
            ),
            child: Center(
              child: AppText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmallCustom(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

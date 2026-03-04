import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/realtime_connection/realtime_connection_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/app_button.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/button_enums.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_banner.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';

/// Wraps content and renders a global top connection banner above all routes.
class GlobalConnectionBannerScope extends StatelessWidget {
  const GlobalConnectionBannerScope({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlobalConnectionBanner(),
        ),
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
  static const _connectedToastDuration = Duration(seconds: 2);

  Timer? _connectedToastTimer;
  bool _showConnectedToast = false;
  bool _hadConnectionIssue = false;
  bool _didInitialAuthSync = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialAuthSync) return;
    _didInitialAuthSync = true;
    _syncRealtimeConnectionWithAuth(context.read<AuthBloc>().state);
  }

  @override
  void dispose() {
    _connectedToastTimer?.cancel();
    super.dispose();
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

    _hadConnectionIssue = false;
    _hideConnectedToast();
    connectionBloc.add(
      const DisconnectFromRealtime(
        reason: 'User unauthenticated',
        issueType: RealtimeConnectionIssueType.auth,
      ),
    );
  }

  void _handleConnectionStateChanged(
    RealtimeConnectionState state,
    bool isAuthenticated,
  ) {
    if (!isAuthenticated) {
      _hadConnectionIssue = false;
      _hideConnectedToast();
      return;
    }

    if (state is RealtimeConnectionDisconnected ||
        state is RealtimeConnectionReconnecting) {
      _hadConnectionIssue = true;
      _hideConnectedToast();
      return;
    }

    if (state is RealtimeConnectionConnected && _hadConnectionIssue) {
      _hadConnectionIssue = false;
      _showConnectedBannerTemporarily();
      return;
    }

    if (state is RealtimeConnectionConnecting) {
      _hideConnectedToast();
    }
  }

  void _showConnectedBannerTemporarily() {
    _connectedToastTimer?.cancel();
    if (!_showConnectedToast) {
      setState(() => _showConnectedToast = true);
    }
    _connectedToastTimer = Timer(_connectedToastDuration, () {
      if (!mounted) return;
      setState(() => _showConnectedToast = false);
    });
  }

  void _hideConnectedToast() {
    _connectedToastTimer?.cancel();
    if (!_showConnectedToast || !mounted) return;
    setState(() => _showConnectedToast = false);
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

    if (_showConnectedToast) {
      return _BannerModel(
        message: context.l10n.backOnline,
        type: FeedbackType.success,
      );
    }

    if (state is RealtimeConnectionConnecting ||
        state is RealtimeConnectionReconnecting) {
      return _BannerModel(
        message: context.l10n.reconnecting,
        type: FeedbackType.info,
      );
    }

    if (state is RealtimeConnectionDisconnected) {
      final message = switch (state.issueType) {
        RealtimeConnectionIssueType.network =>
          context.l10n.noInternetConnection,
        RealtimeConnectionIssueType.server => context.l10n.connectionLost,
        RealtimeConnectionIssueType.auth => context.l10n.connectionLost,
        RealtimeConnectionIssueType.unknown => context.l10n.connectionLost,
      };

      return _BannerModel(
        message: message,
        type: FeedbackType.warning,
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
        BlocListener<RealtimeConnectionBloc, RealtimeConnectionState>(
          bloc: connectionBloc,
          listener: (context, state) {
            final isAuthenticated =
                context.read<AuthBloc>().state.isAuthenticated;
            _handleConnectionStateChanged(state, isAuthenticated);
          },
        ),
      ],
      child: BlocBuilder<RealtimeConnectionBloc, RealtimeConnectionState>(
        bloc: connectionBloc,
        builder: (context, state) {
          final isAuthenticated = context.select<AuthBloc, bool>(
            (bloc) => bloc.state.isAuthenticated,
          );
          final banner = _buildBannerModel(context, state, isAuthenticated);

          return SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingSmall,
                  vertical: AppDimens.paddingXSmall,
                ),
                child: AnimatedSwitcher(
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
                      : ConstrainedBox(
                          key: ValueKey<String>(banner.message),
                          constraints: const BoxConstraints(
                            maxWidth: AppDimens.breakpointTablet,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusMedium,
                            ),
                            child: AppBanner(
                              message: banner.message,
                              type: banner.type,
                              action: banner.action,
                            ),
                          ),
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

class _BannerModel {
  const _BannerModel({
    required this.message,
    required this.type,
    this.action,
  });

  final String message;
  final FeedbackType type;
  final Widget? action;
}

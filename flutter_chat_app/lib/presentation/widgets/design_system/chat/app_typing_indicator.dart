import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/chat/chat_enums.dart';

/// **APP TYPING INDICATOR**
///
/// Animated indicator showing who is typing in the chat.
/// Extends [BaseStatefulWidget] for animation management.
///
/// **Features**:
/// - Bouncing dots animation
/// - Multiple users support ("John and 2 others are typing...")
/// - Auto-hide after timeout
/// - Configurable size
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with animation
///
/// **Usage**:
/// ```dart
/// // Single user
/// AppTypingIndicator(
///   users: ['John Doe'],
/// )
///
/// // Multiple users
/// AppTypingIndicator(
///   users: ['John Doe', 'Jane Smith', 'Bob Johnson'],
/// )
///
/// // With auto-hide
/// AppTypingIndicator(
///   users: ['John Doe'],
///   autoHideDuration: Duration(seconds: 5),
/// )
/// ```
class AppTypingIndicator extends BaseStatefulWidget {
  /// Creates a typing indicator.
  const AppTypingIndicator({
    super.key,
    required this.users,
    this.size = TypingIndicatorSize.medium,
    this.autoHideDuration,
    this.onTimeout,
  });

  /// List of users who are typing
  final List<String> users;

  /// Size of the typing indicator dots
  final TypingIndicatorSize size;

  /// Duration after which to auto-hide (null = no auto-hide)
  final Duration? autoHideDuration;

  /// Callback when auto-hide timeout occurs
  final VoidCallback? onTimeout;

  @override
  AppTypingIndicatorState createState() => AppTypingIndicatorState();
}

class AppTypingIndicatorState extends BaseState<AppTypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _dot1Controller;
  late final AnimationController _dot2Controller;
  late final AnimationController _dot3Controller;

  late final Animation<double> _dot1Animation;
  late final Animation<double> _dot2Animation;
  late final Animation<double> _dot3Animation;

  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers for each dot
    _dot1Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _dot2Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _dot3Controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create bounce animations
    _dot1Animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _dot1Controller,
        curve: Curves.easeInOut,
      ),
    );

    _dot2Animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _dot2Controller,
        curve: Curves.easeInOut,
      ),
    );

    _dot3Animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _dot3Controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations with staggered delays
    _startAnimations();

    // Setup auto-hide timer if duration is provided
    if (widget.autoHideDuration != null) {
      _autoHideTimer = Timer(widget.autoHideDuration!, () {
        if (mounted) {
          widget.onTimeout?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _dot1Controller.dispose();
    _dot2Controller.dispose();
    _dot3Controller.dispose();
    super.dispose();
  }

  void _startAnimations() {
    // Dot 1: Start immediately
    _dot1Controller.repeat(reverse: true);

    // Dot 2: Start after 200ms delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _dot2Controller.repeat(reverse: true);
      }
    });

    // Dot 3: Start after 400ms delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _dot3Controller.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.users.isEmpty) {
      return const SizedBox.shrink();
    }

    final typingText = _getTypingText(l10n);
    final dotSize = _getDotSize();

    return Semantics(
      label: typingText,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMedium,
          vertical: AppDimens.paddingSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Typing text
            Flexible(
              child: Text(
                typingText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.7 : 0.54),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDimens.spaceSmall),

            // Animated dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(_dot1Animation, dotSize, theme),
                SizedBox(width: dotSize / 2),
                _buildDot(_dot2Animation, dotSize, theme),
                SizedBox(width: dotSize / 2),
                _buildDot(_dot3Animation, dotSize, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Animation<double> animation, double size, ThemeData theme) {
    final dotColor = theme.colorScheme.onSurface.withOpacity(
      theme.brightness == Brightness.dark ? 0.7 : 0.54,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  String _getTypingText(AppLocalizations l10n) {
    if (widget.users.isEmpty) {
      return '';
    }

    if (widget.users.length == 1) {
      return l10n.isTyping(widget.users[0]);
    }

    if (widget.users.length == 2) {
      return l10n.areTyping(widget.users[0], widget.users[1]);
    }

    // More than 2 users
    return l10n.multipleTyping(widget.users[0], widget.users.length - 1);
  }

  double _getDotSize() {
    switch (widget.size) {
      case TypingIndicatorSize.small:
        return 6.0;
      case TypingIndicatorSize.medium:
        return 8.0;
      case TypingIndicatorSize.large:
        return 10.0;
    }
  }
}

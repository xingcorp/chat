import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';

/// Route-local keyboard shortcuts for fullscreen media viewers.
///
/// Keeps desktop/web behavior aligned with common chat apps without leaking
/// shortcuts outside the active viewer route.
class MediaViewerShortcutHost extends BaseStatelessWidget {
  const MediaViewerShortcutHost({
    super.key,
    required this.child,
    this.onDismiss,
    this.onPrevious,
    this.onNext,
  });

  final Widget child;
  final VoidCallback? onDismiss;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget buildContent(BuildContext context) {
    if (!_supportsDesktopKeyboardShortcuts) {
      return child;
    }

    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.escape):
          const _DismissMediaViewerShortcutIntent(),
    };

    if (onPrevious != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.arrowLeft)] =
          const _PreviousMediaViewerShortcutIntent();
    }

    if (onNext != null) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.arrowRight)] =
          const _NextMediaViewerShortcutIntent();
    }

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _DismissMediaViewerShortcutIntent:
              CallbackAction<_DismissMediaViewerShortcutIntent>(
            onInvoke: (_) {
              final dismiss = onDismiss;
              if (dismiss != null) {
                dismiss();
              } else {
                Navigator.of(context).maybePop();
              }
              return null;
            },
          ),
          _PreviousMediaViewerShortcutIntent:
              CallbackAction<_PreviousMediaViewerShortcutIntent>(
            onInvoke: (_) {
              onPrevious?.call();
              return null;
            },
          ),
          _NextMediaViewerShortcutIntent:
              CallbackAction<_NextMediaViewerShortcutIntent>(
            onInvoke: (_) {
              onNext?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: child,
        ),
      ),
    );
  }

  bool get _supportsDesktopKeyboardShortcuts {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }
}

class _DismissMediaViewerShortcutIntent extends Intent {
  const _DismissMediaViewerShortcutIntent();
}

class _PreviousMediaViewerShortcutIntent extends Intent {
  const _PreviousMediaViewerShortcutIntent();
}

class _NextMediaViewerShortcutIntent extends Intent {
  const _NextMediaViewerShortcutIntent();
}

import 'package:flutter/material.dart';

/// Dismisses the soft keyboard when the region itself is tapped.
///
/// Useful for header or empty-state areas where tapping should clear focus
/// without coupling keyboard dismissal to list scrolling.
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({
    required this.child,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return GestureDetector(
      behavior: behavior,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}

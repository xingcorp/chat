import 'package:flutter/material.dart';

/// Base mixin for state classes that need simplified setState functionality
mixin BaseStateMixin<T extends StatefulWidget> on State<T> {
  /// Safely call setState if the widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
  
  /// Implementation of buildContent that classes using this mixin should override
  Widget buildContent(BuildContext context);
  
  /// Default implementation of build that calls buildContent
  @override
  Widget build(BuildContext context) {
    return buildContent(context);
  }
} 
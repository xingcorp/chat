import 'package:flutter/material.dart';

/// Base class for all state classes
abstract class BaseState<T extends StatefulWidget> extends State<T> {
  /// The build method to be implemented by subclasses
  @override
  Widget build(BuildContext context);
  
  /// Safely call setState if the widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
  
  /// Implementation of buildContent that subclasses should override
  Widget buildContent(BuildContext context);
} 
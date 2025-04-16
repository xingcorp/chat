import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

/// Base class cho tất cả các widget có trạng thái trong ứng dụng
/// Tích hợp tối ưu hiệu suất và debugging
abstract class BaseStatefulWidget extends StatefulWidget {
  const BaseStatefulWidget({Key? key}) : super(key: key);
  
  /// Allow widgets to control when they should rebuild for optimization
  bool shouldRebuild(covariant BaseStatefulWidget oldWidget) => true;
}

/// Base class cho tất cả các StatefulWidget State
/// Cung cấp các phương thức tiện ích và tối ưu vòng đời
abstract class BaseState<T extends BaseStatefulWidget> extends State<T> with WidgetsBindingObserver {
  final String _tag = 'BaseState<${T.toString()}>';
  bool _mounted = false;
  
  /// Trạng thái mounted của widget
  @override
  bool get mounted => super.mounted && _mounted;
  
  @override
  void initState() {
    _mounted = true;
    LogUtils.d(_tag, 'initState()');
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    LogUtils.d(_tag, 'didChangeDependencies()');
    super.didChangeDependencies();
  }
  
  @override
  void didUpdateWidget(T oldWidget) {
    LogUtils.d(_tag, 'didUpdateWidget()');
    super.didUpdateWidget(oldWidget);
  }
  
  @override
  void deactivate() {
    LogUtils.d(_tag, 'deactivate()');
    super.deactivate();
  }
  
  @override
  void dispose() {
    _mounted = false;
    LogUtils.d(_tag, 'dispose()');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    LogUtils.d(_tag, 'didChangeAppLifecycleState: $state');
    
    // Handle app lifecycle state changes
    if (state == AppLifecycleState.resumed) {
      onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      onAppPaused();
    } else if (state == AppLifecycleState.inactive) {
      onAppInactive();
    } else if (state == AppLifecycleState.detached) {
      onAppDetached();
    }
    
    super.didChangeAppLifecycleState(state);
  }
  
  /// Called when the app is resumed
  void onAppResumed() {}
  
  /// Called when the app is paused
  void onAppPaused() {}
  
  /// Called when the app is inactive
  void onAppInactive() {}
  
  /// Called when the app is detached
  void onAppDetached() {}
  
  /// Phương thức kiểm tra trạng thái widget trước khi setState
  /// Giúp tránh gọi setState trên widget đã dispose
  @protected
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    } else {
      LogUtils.w(_tag, 'Tried to setState but widget is not mounted');
      fn();
    }
  }
}

/// Base class for all stateless widgets
abstract class BaseStatelessWidget extends StatelessWidget {
  /// Constructor
  const BaseStatelessWidget({Key? key}) : super(key: key);

  /// Build method to override in descendants
  @override
  Widget build(BuildContext context) {
    return buildContent(context);
  }

  /// Build content method to be implemented by subclasses
  Widget buildContent(BuildContext context);
} 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/app/app_bloc.dart';

/// Observer để theo dõi vòng đời ứng dụng và gửi event tới AppBloc
class AppLifecycleObserver extends WidgetsBindingObserver {
  final BuildContext context;
  
  /// Constructor
  AppLifecycleObserver(this.context);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Ứng dụng trở lại foreground
        context.read<AppBloc>().add(const AppEnteredForeground());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        // Ứng dụng vào background
        context.read<AppBloc>().add(const AppEnteredBackground());
        break;
      default:
        break;
    }
  }
  
  /// Đăng ký observer khi khởi tạo
  void register() {
    WidgetsBinding.instance.addObserver(this);
  }
  
  /// Hủy đăng ký observer khi không cần thiết
  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }
} 
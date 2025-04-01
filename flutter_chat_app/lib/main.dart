import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/config/route/app_router.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/core/services/realtime_connection_service.dart';
import 'package:flutter_chat_app/core/services/chat_message_service.dart';
import 'package:flutter_chat_app/core/services/message_queue_service.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// Import các model
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/entities/chat_message.dart';
import 'package:flutter_chat_app/domain/entities/user.dart';

// Import platform-specific 
import 'package:flutter_chat_app/presentation/pages/chat/chat_list_page.dart';

// Định nghĩa tạm các màn hình cho đa nền tảng
class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ChatListPage();
  }
}

class WebHomeScreen extends StatelessWidget {
  const WebHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ChatListPage();
  }
}

class DesktopHomeScreen extends StatelessWidget {
  const DesktopHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ChatListPage();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Khởi tạo Hive cho GraphQL cache
  await initHiveForFlutter();
  
  // Khởi tạo SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Tùy thuộc vào nền tảng, chúng ta sẽ khởi động các dịch vụ phù hợp
  if (kIsWeb) {
    await _initializeWebServices();
  } else if (Platform.isAndroid || Platform.isIOS) {
    await _initializeMobileServices();
  } else {
    await _initializeDesktopServices();
  }
  
  runApp(MyApp(sharedPreferences: sharedPreferences));
}

Future<void> _initializeWebServices() async {
  // Khởi tạo các service dành riêng cho web
  try {
    if (GetIt.I.isRegistered<DatabaseService>()) {
      final databaseService = GetIt.I<DatabaseService>();
      await databaseService.initialize();
    }
    
    if (GetIt.I.isRegistered<RealtimeConnectionService>()) {
      final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
      await realtimeConnectionService.initialize();
    }
    
    if (GetIt.I.isRegistered<ChatMessageService>()) {
      final chatMessageService = GetIt.I<ChatMessageService>();
      await chatMessageService.initialize();
    }
  } catch (e) {
    debugPrint('Lỗi khởi tạo services (web): $e');
  }
}

Future<void> _initializeMobileServices() async {
  // Khởi tạo các service dành riêng cho mobile
  try {
    if (GetIt.I.isRegistered<DatabaseService>()) {
      final databaseService = GetIt.I<DatabaseService>();
      await databaseService.initialize();
    }
    
    if (GetIt.I.isRegistered<RealtimeConnectionService>()) {
      final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
      await realtimeConnectionService.initialize();
    }
    
    if (GetIt.I.isRegistered<MessageQueueService>()) {
      final messageQueueService = GetIt.I<MessageQueueService>();
      await messageQueueService.initialize();
    }
    
    if (GetIt.I.isRegistered<ChatMessageService>()) {
      final chatMessageService = GetIt.I<ChatMessageService>();
      await chatMessageService.initialize();
    }
  } catch (e) {
    debugPrint('Lỗi khởi tạo services (mobile): $e');
  }
}

Future<void> _initializeDesktopServices() async {
  // Khởi tạo các service dành riêng cho desktop
  try {
    if (GetIt.I.isRegistered<DatabaseService>()) {
      final databaseService = GetIt.I<DatabaseService>();
      await databaseService.initialize();
    }
    
    if (GetIt.I.isRegistered<RealtimeConnectionService>()) {
      final realtimeConnectionService = GetIt.I<RealtimeConnectionService>();
      await realtimeConnectionService.initialize();
    }
    
    if (GetIt.I.isRegistered<MessageQueueService>()) {
      final messageQueueService = GetIt.I<MessageQueueService>();
      await messageQueueService.initialize();
    }
    
    if (GetIt.I.isRegistered<ChatMessageService>()) {
      final chatMessageService = GetIt.I<ChatMessageService>();
      await chatMessageService.initialize();
    }
  } catch (e) {
    debugPrint('Lỗi khởi tạo services (desktop): $e');
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  
  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authBloc = AuthBloc(sharedPreferences);
        // Trigger an auth check on app startup
        authBloc.add(const AuthCheckRequested());
        return authBloc;
      },
      child: Builder(
        builder: (context) {
          final router = AppRouter.router(context);
          
          return MaterialApp.router(
            title: 'Flutter Chat App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

// This widget will determine which platform-specific implementation to use
class PlatformEntryPoint extends StatelessWidget {
  const PlatformEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    // Return the appropriate screen based on platform
    if (kIsWeb) {
      return const WebHomeScreen();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return const MobileHomeScreen();
    } else {
      return const DesktopHomeScreen();
    }
  }
} 
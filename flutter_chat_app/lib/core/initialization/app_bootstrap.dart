import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/config/environment_manager.dart';
import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/initialization/download_plugin_initializer.dart';
import 'package:flutter_chat_app/core/initialization/env_validator.dart';
import 'package:flutter_chat_app/core/initialization/media_kit_initializer.dart';
import 'package:flutter_chat_app/core/initialization/service_initializer.dart';
import 'package:flutter_chat_app/app.dart';

/// Bootstraps the application: binding, env, DI, system chrome, then [runApp].
///
/// All work runs inside [runZonedGuarded] so the binding and [runApp] share
/// the same zone (avoids the "Zone mismatch" assertion).
Future<void> runMainApp() async {
  await runZonedGuarded(() async {
    final startupWatch = Stopwatch()..start();

    WidgetsFlutterBinding.ensureInitialized();
    _logStartupCheckpoint(startupWatch, 'WidgetsBinding');

    if (!FlavorConfig.isInitialized) {
      FlavorConfig.initializeFromEnvironment();
    }
    _logStartupCheckpoint(startupWatch, 'FlavorConfig');

    await initializeDownloadPlugin();
    _logStartupCheckpoint(startupWatch, 'DownloadPlugin');

    await ensureMediaKitInitialized();
    _logStartupCheckpoint(startupWatch, 'MediaKit');

    final envFileName = await EnvValidator.loadDotenvForFlavor();
    EnvValidator.validateDotenvConfiguration(envFileName);
    _logStartupCheckpoint(startupWatch, 'EnvValidator');

    await configureDependencies();
    _logStartupCheckpoint(startupWatch, 'DI (configureDependencies)');

    // Initialize environment manager
    final environmentManager = GetIt.I<EnvironmentManager>();
    await environmentManager.initialize();
    _logStartupCheckpoint(startupWatch, 'EnvironmentManager');

    // Screen orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _logStartupCheckpoint(startupWatch, 'SystemChrome');

    // Flavor-specific system UI
    final flavorColors = FlavorUtils.getFlavorColors();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor:
            Color(flavorColors['primary'] as int).withValues(alpha: 0.8),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(flavorColors['background'] as int),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(
      LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= AppDimens.breakpointDesktop;

          return ScreenUtilInit(
            designSize: isDesktop
                ? Size(constraints.maxWidth, constraints.maxHeight)
                : const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => const MyApp(),
          );
        },
      ),
    );

    _logStartupCheckpoint(startupWatch, 'runApp');

    // Initialize non-critical services in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logStartupCheckpoint(startupWatch, 'First frame rendered');
      ServiceInitializer.initializeNonCriticalServices();
    });
  }, (error, stackTrace) {
    if (GetIt.I.isRegistered<Logger>()) {
      GetIt.I<Logger>()
          .e('Unhandled error', error: error, stackTrace: stackTrace);
    } else {
      debugPrint('Unhandled error: $error\n$stackTrace');
    }
  });
}

void _logStartupCheckpoint(Stopwatch watch, String label) {
  if (kDebugMode) {
    debugPrint(
        '⏱️ [Startup] $label: ${watch.elapsedMilliseconds}ms (total)');
  }
}

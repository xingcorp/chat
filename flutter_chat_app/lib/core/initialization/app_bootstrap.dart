import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'package:flutter_chat_app/core/config/environment_manager.dart';
import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/initialization/env_validator.dart';
import 'package:flutter_chat_app/core/initialization/service_initializer.dart';
import 'package:flutter_chat_app/app.dart';

/// Bootstraps the application: binding, env, DI, system chrome, then [runApp].
Future<void> runMainApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initializeFromEnvironment();
  }

  final envFileName = await EnvValidator.loadDotenvForFlavor();
  EnvValidator.validateDotenvConfiguration(envFileName);

  await configureDependencies();

  // Initialize environment manager
  final environmentManager = GetIt.I<EnvironmentManager>();
  await environmentManager.initialize();
  environmentManager.printEnvironmentInfo();

  // Screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

  // Start app immediately for fast startup
  runZonedGuarded(() {
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
  }, (error, stackTrace) {
    GetIt.I<Logger>().e('Unhandled error', error: error, stackTrace: stackTrace);
  });

  // Initialize non-critical services in background
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ServiceInitializer.initializeNonCriticalServices();
  });
}

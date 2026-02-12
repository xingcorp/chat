import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_chat_app/core/config/flavor_config.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/di/injection.dart';
import 'package:flutter_chat_app/core/initialization/env_validator.dart';
import 'package:flutter_chat_app/core/services/database_service.dart';
import 'package:flutter_chat_app/main.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!FlavorConfig.isInitialized) {
    FlavorConfig.initializeFromEnvironment();
  }

  final envFileName = await EnvValidator.loadDotenvForFlavor();
  EnvValidator.validateDotenvConfiguration(envFileName);

  await configureDependencies();

  await _initializeWebServices();

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
}

Future<void> _initializeWebServices() async {
  final databaseService = GetIt.I<DatabaseService>();
  await databaseService.initialize();
}

/// **SIMPLE WEB MAIN**
///
/// Simplified web entry point without Isar database
/// Focuses on theme and i18n enterprise features for web platform
library;

///
/// **Features:**
/// - Enterprise theme system
/// - Advanced internationalization
/// - Web-optimized performance
/// - No database dependencies

// Flutter imports
import 'package:flutter/material.dart';

// Third-party package imports
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/config/app_identity.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/core/theme/app_theme.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter_chat_app/presentation/pages/home/web_home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize simple web services
  await _initializeWebServices();

  runApp(const SimpleWebApp());
}

/// Initialize minimal web services
Future<void> _initializeWebServices() async {
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Register LocalStorage
  GetIt.I.registerSingleton<LocalStorage>(LocalStorageImpl(prefs));

  // Register Cubits
  GetIt.I
      .registerFactory<ThemeCubit>(() => ThemeCubit(GetIt.I<LocalStorage>()));
  GetIt.I
      .registerFactory<LocaleCubit>(() => LocaleCubit(GetIt.I<LocalStorage>()));
}

/// **SIMPLE WEB APP**
class SimpleWebApp extends StatelessWidget {
  const SimpleWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => GetIt.I<ThemeCubit>(),
        ),
        BlocProvider<LocaleCubit>(
          create: (context) => GetIt.I<LocaleCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return MaterialApp(
                title: '${AppIdentity.appName} - Web',
                debugShowCheckedModeBanner: false,

                // **ENTERPRISE THEME INTEGRATION**
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeState.themeMode,

                // **ENTERPRISE I18N INTEGRATION**
                locale: localeState.locale,
                supportedLocales: L10n.all,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // **RTL SUPPORT**
                builder: (context, child) {
                  return Directionality(
                    textDirection: localeState.isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child!,
                  );
                },

                home: const WebHomeScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

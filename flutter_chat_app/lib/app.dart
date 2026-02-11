import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/localization/l10n_helper.dart' as l10n_helper;
import 'package:flutter_chat_app/core/theme/app_theme.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/config/route/app_router.dart';
import 'package:flutter_chat_app/presentation/blocs/app/app_bloc.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/permissions/permissions_bloc.dart';

/// Root widget that wires up BLoC providers for the entire application.
class MyApp extends BaseStatelessWidget {
  const MyApp({super.key});

  @override
  Widget buildContent(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
          create: (context) => GetIt.I<AppBloc>(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => GetIt.I<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<LocaleCubit>(
          create: (context) => GetIt.I<LocaleCubit>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => GetIt.I<ThemeCubit>(),
        ),
        BlocProvider<PermissionsBloc>(
          create: (context) => GetIt.I<PermissionsBloc>(),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;
  bool _routerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routerInitialized) {
      _router = AppRouter.router(context);
      _routerInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            l10n_helper.L10nHelper.initialize(localeState.locale ?? const Locale('en'));

            return MaterialApp.router(
              title: 'Flutter Chat App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,
              locale: localeState.locale,
              supportedLocales: L10n.all,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return Directionality(
                  textDirection:
                      localeState.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                );
              },
              routerConfig: _router,
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/config/route/app_router.dart';
import 'package:flutter_chat_app/core/app/chat_app_shell.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/localization/l10n_helper.dart'
    as l10n_helper;
import 'package:flutter_chat_app/core/theme/app_theme.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter_chat_app/presentation/widgets/connection/global_connection_banner.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:go_router/go_router.dart';

/// Root widget that wires up BLoC providers for the entire application.
///
/// Uses [ChatAppShell.standalone] to provide all required blocs and services.
/// This ensures consistency between standalone and package modes.
class MyApp extends BaseStatelessWidget {
  const MyApp({super.key});

  @override
  Widget buildContent(BuildContext context) {
    // ChatAppShell.standalone provides: AppBloc, AuthBloc, LocaleCubit,
    // ThemeCubit, PermissionsBloc, ChatBloc
    return const ChatAppShell.standalone(
      child: _AppView(),
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
      // Always start at /splash for branded experience.
      // Splash shows a short animation (~1.5s) while AuthBloc validates
      // the token in background. Once auth resolves, router redirects to
      // /chats (if authenticated) or /login.
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
            l10n_helper.L10nHelper.initialize(
                localeState.locale ?? const Locale('en'));

            return Portal(
              child: MaterialApp.router(
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
                  final appContent = Directionality(
                    textDirection: localeState.isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child ?? const SizedBox.shrink(),
                  );

                  return GlobalConnectionBannerScope(
                    child: appContent,
                  );
                },
                routerConfig: _router,
              ),
            );
          },
        );
      },
    );
  }
}

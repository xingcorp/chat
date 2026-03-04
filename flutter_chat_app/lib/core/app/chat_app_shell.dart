import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/chat_module.dart';
import 'package:flutter_chat_app/core/app/package_mode_auth_repository.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/blocs/app/app_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/permissions/permissions_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/realtime_connection/realtime_connection_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defines the operation mode of the chat module.
enum ChatShellMode {
  /// Standalone app mode - full app with MaterialApp.
  /// Uses blocs from GetIt configured via `configureDependencies()`.
  standalone,

  /// Package mode - embedded in host app.
  /// Uses package-mode auth flow with user info from ChatConfig.
  package,
}

/// Provides all required dependencies for chat module pages.
///
/// This is the **single source of truth** for chat module dependencies.
/// Both standalone and package modes use this widget to get their providers.
///
/// ## Standalone Mode
/// Used by `app.dart` when running as a standalone app:
/// ```dart
/// ChatAppShell.standalone(
///   child: MaterialApp.router(...),
/// )
/// ```
///
/// ## Package Mode
/// Used by `ChatModule` when embedded in a host app:
/// ```dart
/// ChatModule.chatListPage() → ChatAppShell.package(child: ChatListPage())
/// ```
///
/// ## Key Benefits
/// - Single source of truth for provider configuration
/// - Both modes share the same logic
/// - Easy to add new dependencies
/// - Testable - one path to test
class ChatAppShell extends StatelessWidget {
  /// The child widget to wrap with providers.
  final Widget child;

  /// The operation mode.
  final ChatShellMode mode;

  /// Optional locale override. If null, uses context locale.
  final Locale? locale;

  /// Creates a ChatAppShell for standalone mode.
  ///
  /// In standalone mode:
  /// - Blocs are fetched from GetIt (registered via `configureDependencies()`)
  /// - [AuthBloc] emits [AuthCheckRequested] on creation
  /// - Full bloc set is provided (AppBloc, ThemeCubit, etc.)
  const ChatAppShell.standalone({
    super.key,
    required this.child,
    this.locale,
  }) : mode = ChatShellMode.standalone;

  /// Creates a ChatAppShell for package mode.
  ///
  /// In package mode:
  /// - AuthBloc is replaced with package-mode authenticated AuthBloc
  /// - User info comes from ChatModule.config
  /// - Only essential blocs are provided (AuthBloc, ChatBloc)
  /// - Host app provides ThemeCubit, LocaleCubit, etc.
  const ChatAppShell.package({
    super.key,
    required this.child,
    this.locale,
  }) : mode = ChatShellMode.package;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: _buildProviders(),
      child: _LocalizationWrapper(
        locale: locale,
        mode: mode,
        child: child,
      ),
    );
  }

  /// Builds the list of BlocProviders based on mode.
  List<BlocProvider> _buildProviders() {
    final getIt = GetIt.I;

    if (mode == ChatShellMode.standalone) {
      // Standalone mode: Full bloc set from GetIt
      return [
        BlocProvider<AppBloc>(
          create: (_) => getIt<AppBloc>(),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => getIt<LocaleCubit>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => getIt<ThemeCubit>(),
        ),
        BlocProvider<PermissionsBloc>(
          create: (_) => getIt<PermissionsBloc>(),
        ),
        if (getIt.isRegistered<RealtimeConnectionBloc>())
          BlocProvider<RealtimeConnectionBloc>(
            create: (_) => getIt<RealtimeConnectionBloc>(),
          ),
        if (getIt.isRegistered<ChatBloc>())
          BlocProvider<ChatBloc>(
            create: (_) => getIt<ChatBloc>(),
          ),
      ];
    } else {
      // Package mode: Minimal blocs with PackageModeAuthRepository
      final config = ChatModule.config;
      if (config == null) {
        throw StateError(
          'ChatModule.config is null. '
          'Call ChatModule.initialize(ChatConfig(...)) first.',
        );
      }

      // Create pre-authenticated User from ChatConfig
      final currentUser = User(
        id: config.currentUserId,
        username: config.currentUserName ?? 'user_${config.currentUserId}',
        email: config.currentUserEmail ?? '',
        fullName: config.currentUserFullName,
        avatar: config.currentUserAvatar,
        isOnline: true,
      );

      // Create AuthBloc with PackageModeAuthRepository
      final authRepository = PackageModeAuthRepository(
        currentUser: currentUser,
        accessToken: config.accessToken,
      );

      return [
        // AuthBloc with pre-authenticated state - NO async check needed
        // Using AuthBloc.authenticated ensures state is AuthAuthenticated
        // immediately when child widgets read it in didChangeDependencies
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc.authenticated(
            authRepository: authRepository,
            preferences: getIt<SharedPreferences>(),
            user: currentUser,
            isOnboarded: true,
          ),
        ),
        // LocaleCubit from GetIt (registered in ChatModuleInjection via init())
        if (getIt.isRegistered<LocaleCubit>())
          BlocProvider<LocaleCubit>(
            create: (_) => getIt<LocaleCubit>(),
          ),
        // ThemeCubit from GetIt (registered in ChatModuleInjection via init())
        if (getIt.isRegistered<ThemeCubit>())
          BlocProvider<ThemeCubit>(
            create: (_) => getIt<ThemeCubit>(),
          ),
        // ChatBloc from GetIt (registered in ChatModuleInjection)
        if (getIt.isRegistered<ChatBloc>())
          BlocProvider<ChatBloc>(
            create: (_) => getIt<ChatBloc>(),
          ),
        // RealtimeConnectionBloc from GetIt (registered in ChatModuleInjection)
        if (getIt.isRegistered<RealtimeConnectionBloc>())
          BlocProvider<RealtimeConnectionBloc>(
            create: (_) => getIt<RealtimeConnectionBloc>(),
          ),
      ];
    }
  }
}

/// Wraps child with localization delegates.
///
/// In standalone mode, this wraps the MaterialApp which handles its own localization.
/// In package mode, this uses [Localizations.override] to inject chat module's delegates.
class _LocalizationWrapper extends StatelessWidget {
  final Widget child;
  final Locale? locale;
  final ChatShellMode mode;

  const _LocalizationWrapper({
    required this.child,
    required this.mode,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == ChatShellMode.standalone) {
      // Standalone mode: MaterialApp handles localization
      // Just pass through the child
      return child;
    }

    // Package mode: Override localization to inject chat module's delegates
    final effectiveLocale = locale ?? Localizations.localeOf(context);

    return Localizations.override(
      context: context,
      locale: effectiveLocale,
      delegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: child,
    );
  }
}

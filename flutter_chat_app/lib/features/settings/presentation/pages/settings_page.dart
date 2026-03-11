import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/config/app_identity.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/core/utils/platform_utils.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';
import 'package:flutter_chat_app/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_event.dart';
import 'package:flutter_chat_app/presentation/blocs/update/update_state.dart';
import 'package:flutter_chat_app/presentation/widgets/common/hero_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_progress_indicator.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_brand_logo.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/presentation/widgets/settings/language_selector.dart';
import 'package:flutter_chat_app/presentation/widgets/update/update_available_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/update/update_progress_dialog.dart';
import 'package:flutter_chat_app/presentation/widgets/update/update_ready_dialog.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings page - app settings and user profile
class SettingsPage extends BaseStatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends BaseState<SettingsPage> {
  final UserRepository _userRepository = GetIt.instance<UserRepository>();

  User? _currentUser;
  bool _isLoading = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAppVersion();
  }

  Future<void> _loadUserProfile() async {
    safeSetState(() {
      _isLoading = true;
    });

    final result = await _userRepository.getCurrentUser();

    result.fold(
      (failure) {
        safeSetState(() {
          _isLoading = false;
        });
      },
      (user) {
        safeSetState(() {
          _isLoading = false;
          _currentUser = user;
        });
      },
    );
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      safeSetState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      safeSetState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logout),
        content: Text(context.l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const AuthLoggedOut());
            },
            child: Text(
              context.l10n.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: AppText(context.l10n.settingsTitle),
      ),
      body: _isLoading
          ? Center(
              child: AppProgressIndicator.circular(
                label: context.l10n.loading,
              ),
            )
          : ListView(
              children: [
                // User Profile Section
                _buildUserProfileSection(context, isDark),

                const Divider(height: 1),

                // Theme Settings
                _buildThemeSection(context, isDark),

                const Divider(height: 1),

                // Notifications
                _buildSettingsItem(
                  context: context,
                  icon: Icons.notifications_outlined,
                  title: context.l10n.notificationSettings,
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),

                const Divider(height: 1),

                // Language
                BlocBuilder<LocaleCubit, LocaleState>(
                  builder: (context, localeState) {
                    final currentLocale = localeState.locale;
                    final subtitle = currentLocale != null
                        ? L10n.getLanguageDisplayName(currentLocale)
                        : '🌐 ${context.l10n.systemDefault}';

                    return _buildSettingsItem(
                      context: context,
                      icon: Icons.language,
                      title: context.l10n.languageSettings,
                      subtitle: subtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BlocProvider.value(
                              value: context.read<LocaleCubit>(),
                              child: const LanguageSelectorScreen(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const Divider(height: 1),

                // Check for Updates (desktop only)
                if (PlatformUtils.isDesktopDevice)
                  _buildUpdateSectionWithListener(context, isDark),

                if (PlatformUtils.isDesktopDevice)
                  const Divider(height: 1),

                // About
                _buildSettingsItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: context.l10n.aboutSettings,
                  subtitle: '${context.l10n.version}: $_appVersion',
                  onTap: () {
                    // TODO: Show about dialog
                    _showAboutDialog(context);
                  },
                ),

                const Divider(height: 1),

                // Logout
                _buildSettingsItem(
                  context: context,
                  icon: Icons.logout,
                  title: context.l10n.logout,
                  textColor: AppColors.error,
                  onTap: _logout,
                ),
              ],
            ),
    );
  }

  Widget _buildUserProfileSection(BuildContext context, bool isDark) {
    final primaryTextColor = isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        // TODO: Navigate to profile edit page
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Row(
          children: [
            AppHeroAvatar(
              id: _currentUser?.id ?? '',
              imageUrl: _currentUser?.avatar,
              displayName: _currentUser?.fullName,
              size: AvatarSize.large,
              hasBorder: false,
            ),
            const SizedBox(width: AppDimens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    _currentUser?.fullName ?? _currentUser?.username ?? context.l10n.profile,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spaceXSmall),
                  AppText(
                    _currentUser?.email ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, bool isDark) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        String themeLabel;
        switch (state.themeMode) {
          case ThemeMode.light:
            themeLabel = context.l10n.lightTheme;
            break;
          case ThemeMode.dark:
            themeLabel = context.l10n.darkTheme;
            break;
          case ThemeMode.system:
            themeLabel = 'System';
            break;
        }

        return _buildSettingsItem(
          context: context,
          icon: isDark ? Icons.dark_mode : Icons.light_mode,
          title: context.l10n.themeSettings,
          subtitle: themeLabel,
          onTap: () => _showThemeDialog(context),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.themeSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(context.l10n.lightTheme),
              value: ThemeMode.light,
              groupValue: themeCubit.state.themeMode,
              onChanged: (value) {
                themeCubit.useLightTheme();
                Navigator.of(dialogContext).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(context.l10n.darkTheme),
              value: ThemeMode.dark,
              groupValue: themeCubit.state.themeMode,
              onChanged: (value) {
                themeCubit.useDarkTheme();
                Navigator.of(dialogContext).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: themeCubit.state.themeMode,
              onChanged: (value) {
                themeCubit.useSystemTheme();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: AppIdentity.appName,
        applicationVersion: _appVersion,
        applicationIcon: const AppBrandLogo.icon(size: 48),
        children: [
          const SizedBox(height: AppDimens.spaceMedium),
          Text(AppIdentity.description),
        ],
      ),
    );
  }

  /// Update section wrapped with [BlocListener] to show dialogs
  /// when state transitions occur (available → dialog, downloading → progress,
  /// ready → install dialog, not available → snackbar).
  Widget _buildUpdateSectionWithListener(BuildContext context, bool isDark) {
    return BlocListener<UpdateBloc, UpdateState>(
      listener: (context, state) {
        if (state is UpdateAvailable) {
          // Auto-show dialog when update is detected via manual check
          UpdateAvailableDialog.show(context, state.updateInfo);
        } else if (state is UpdateDownloading && state.progress == 0) {
          // Show progress dialog when download starts
          UpdateProgressDialog.show(context);
        } else if (state is UpdateReadyToInstall) {
          // Show install dialog when download completes
          UpdateReadyDialog.show(
            context,
            updateInfo: state.updateInfo,
            installerPath: state.installerPath,
          );
        } else if (state is UpdateNotAvailable) {
          // Show snackbar for manual "already up to date"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                context.l10n.upToDate,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is UpdateError) {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: AppText(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: _buildUpdateTile(context, isDark),
    );
  }

  Widget _buildUpdateTile(BuildContext context, bool isDark) {
    return BlocBuilder<UpdateBloc, UpdateState>(
      builder: (context, state) {
        String subtitle;
        Widget? trailing;
        VoidCallback onTap;

        if (state is UpdateChecking) {
          subtitle = context.l10n.checkingForUpdates;
          trailing = const SizedBox(
            width: AppDimens.iconSmall,
            height: AppDimens.iconSmall,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
          onTap = () {};
        } else if (state is UpdateAvailable) {
          subtitle = '${context.l10n.newVersionAvailable}: ${state.updateInfo.version}';
          trailing = Container(
            width: AppDimens.iconSmall,
            height: AppDimens.iconSmall,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          );
          // FIX: Show update dialog instead of re-checking
          onTap = () => UpdateAvailableDialog.show(context, state.updateInfo);
        } else if (state is UpdateDownloading) {
          final pct = (state.progress * 100).toInt();
          subtitle = '${context.l10n.downloading}... $pct%';
          trailing = SizedBox(
            width: AppDimens.iconSmall,
            height: AppDimens.iconSmall,
            child: CircularProgressIndicator(
              value: state.progress,
              strokeWidth: 2,
            ),
          );
          // Show progress dialog when tapping during download
          onTap = () => UpdateProgressDialog.show(context);
        } else if (state is UpdateReadyToInstall) {
          subtitle = context.l10n.restartToUpdate;
          trailing = Icon(
            Icons.restart_alt,
            color: AppColors.success,
            size: AppDimens.iconMedium,
          );
          onTap = () => UpdateReadyDialog.show(
                context,
                updateInfo: state.updateInfo,
                installerPath: state.installerPath,
              );
        } else if (state is UpdateError) {
          subtitle = context.l10n.updateCheckFailed;
          // FIX: Pass isManual: true for retry
          onTap = () => context.read<UpdateBloc>().add(
                const CheckForUpdateRequested(isManual: true),
              );
        } else {
          subtitle = context.l10n.upToDate;
          // FIX: Pass isManual: true so user gets feedback
          onTap = () => context.read<UpdateBloc>().add(
                const CheckForUpdateRequested(isManual: true),
              );
        }

        final secondaryTextColor =
            isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

        return ListTile(
          leading: Icon(
            Icons.system_update_outlined,
            color: isDark ? AppColors.primaryDarkMode : AppColors.primary,
          ),
          title: AppText(
            context.l10n.checkForUpdates,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDarkMode
                  : AppColors.textPrimary,
            ),
          ),
          subtitle: AppText(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: secondaryTextColor,
            ),
          ),
          trailing: trailing ??
              Icon(Icons.chevron_right, color: secondaryTextColor),
          onTap: onTap,
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = textColor ?? (isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary);
    final secondaryTextColor = isDark ? AppColors.textSecondaryDarkMode : AppColors.textSecondary;

    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? (isDark ? AppColors.primaryDarkMode : AppColors.primary),
      ),
      title: AppText(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: primaryTextColor,
        ),
      ),
      subtitle: subtitle != null
          ? AppText(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: secondaryTextColor,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: secondaryTextColor,
      ),
      onTap: onTap,
    );
  }
}

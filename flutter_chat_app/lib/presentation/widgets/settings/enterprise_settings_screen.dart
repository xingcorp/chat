/// **ENTERPRISE SETTINGS SCREEN**
///
/// Comprehensive settings screen showcasing all enterprise theme and i18n features
/// Demonstrates real-time performance monitoring and advanced configuration
///
/// **Features:**
/// - Theme management with dynamic colors
/// - Language selection with RTL support
/// - Performance metrics display
/// - Error handling and diagnostics
/// - Cache management

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';

import 'language_selector.dart';
import 'theme_toggle_button.dart';

/// **ENTERPRISE SETTINGS SCREEN**
class EnterpriseSettingsScreen extends StatelessWidget {
  const EnterpriseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'System Diagnostics',
            onPressed: () => _showSystemDiagnostics(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader(context, 'Theme Settings', Icons.palette),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ThemeToggleButton(isIconButton: false),
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, state) {
                    return SwitchListTile(
                      title: const Text('Dynamic Colors'),
                      subtitle: const Text('Use system wallpaper colors (Android 12+)'),
                      value: state.isDynamicColorsEnabled,
                      onChanged: (value) {
                        context.read<ThemeCubit>().setDynamicColors(value);
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Theme Performance'),
                  subtitle: BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, state) {
                      if (state.lastSwitchDuration != null) {
                        return Text(
                          'Last switch: ${state.lastSwitchDuration!.inMilliseconds}ms '
                          '(${state.isPerformanceOptimal ? 'Optimal' : 'Slow'})',
                          style: TextStyle(
                            color: state.isPerformanceOptimal 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        );
                      }
                      return const Text('No performance data yet');
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeMetrics(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Language Section
          _buildSectionHeader(context, 'Language Settings', Icons.language),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(context.l10n.selectLanguage),
                  subtitle: BlocBuilder<LocaleCubit, LocaleState>(
                    builder: (context, state) {
                      final locale = state.effectiveLocale;
                      return Row(
                        children: [
                          Text('Current: ${locale.languageCode.toUpperCase()}'),
                          if (state.isRtl) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.format_textdirection_r_to_l,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const Text(' RTL'),
                          ],
                        ],
                      );
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguageSelectorScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Translation Performance'),
                  subtitle: BlocBuilder<LocaleCubit, LocaleState>(
                    builder: (context, state) {
                      if (state.lastSwitchDuration != null) {
                        return Text(
                          'Last switch: ${state.lastSwitchDuration!.inMilliseconds}ms '
                          '(${state.isPerformanceOptimal ? 'Optimal' : 'Slow'})',
                          style: TextStyle(
                            color: state.isPerformanceOptimal 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        );
                      }
                      return const Text('No performance data yet');
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showI18nMetrics(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // System Section
          _buildSectionHeader(context, 'System', Icons.settings),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.memory),
                  title: const Text('Cache Management'),
                  subtitle: const Text('Clear theme and translation caches'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCacheManagement(context),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Error Diagnostics'),
                  subtitle: BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, themeState) {
                      return BlocBuilder<LocaleCubit, LocaleState>(
                        builder: (context, localeState) {
                          final hasErrors = themeState.hasError || localeState.hasError;
                          return Text(
                            hasErrors ? 'Issues detected' : 'All systems operational',
                            style: TextStyle(
                              color: hasErrors ? Colors.red : Colors.green,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showErrorDiagnostics(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _showSystemDiagnostics(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final localeCubit = context.read<LocaleCubit>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Diagnostics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme System:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...themeCubit.getPerformanceMetrics().entries.map(
                (e) => Text('${e.key}: ${e.value}'),
              ),
              const SizedBox(height: 16),
              const Text('I18N System:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...localeCubit.getPerformanceMetrics().entries.map(
                (e) => Text('${e.key}: ${e.value}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showThemeMetrics(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final metrics = themeCubit.getPerformanceMetrics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Performance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: metrics.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${e.key}: ${e.value}'),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              themeCubit.clearCache();
              Navigator.pop(context);
            },
            child: const Text('Clear Cache'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showI18nMetrics(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    final metrics = localeCubit.getPerformanceMetrics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translation Performance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: metrics.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${e.key}: ${e.value}'),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              localeCubit.clearCache();
              Navigator.pop(context);
            },
            child: const Text('Clear Cache'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCacheManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Management'),
        content: const Text('Clear all cached themes and translations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ThemeCubit>().clearCache();
              context.read<LocaleCubit>().clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caches cleared successfully')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showErrorDiagnostics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return AlertDialog(
                title: const Text('Error Diagnostics'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme Errors:', style: Theme.of(context).textTheme.titleSmall),
                    Text(themeState.hasError ? themeState.error! : 'No errors'),
                    const SizedBox(height: 16),
                    Text('I18N Errors:', style: Theme.of(context).textTheme.titleSmall),
                    Text(localeState.hasError ? localeState.error! : 'No errors'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

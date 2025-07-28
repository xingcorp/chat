import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/theme/theme_cubit.dart';

/// **THEME TOGGLE BUTTON**
///
/// Widget for switching between light/dark themes with smooth animations.
/// Provides WhatsApp/Telegram-level user experience.

/// **THEME TOGGLE BUTTON**
/// 
/// Animated button for theme switching
class ThemeToggleButton extends StatelessWidget {
  final bool isIconButton;
  final VoidCallback? onChanged;
  final IconData? lightIcon;
  final IconData? darkIcon;
  final IconData? systemIcon;
  
  const ThemeToggleButton({
    super.key,
    this.isIconButton = false,
    this.onChanged,
    this.lightIcon = Icons.light_mode,
    this.darkIcon = Icons.dark_mode,
    this.systemIcon = Icons.brightness_auto,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final themeCubit = context.read<ThemeCubit>();
        
        if (isIconButton) {
          return IconButton(
            tooltip: _getTooltip(context, state.themeMode),
            onPressed: () => _toggleTheme(context, themeCubit),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _getIcon(state.themeMode),
                key: ValueKey(state.themeMode),
              ),
            ),
          );
        }
        
        return ListTile(
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _getIcon(state.themeMode),
              key: ValueKey(state.themeMode),
            ),
          ),
          title: Text(context.l10n.themeSettings),
          subtitle: Text(_getSubtitle(context, state.themeMode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeSelector(context),
        );
      },
    );
  }
  
  /// Toggle theme
  void _toggleTheme(BuildContext context, ThemeCubit themeCubit) {
    themeCubit.toggleTheme();
    onChanged?.call();
  }
  
  /// Show theme selector dialog
  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemeSelectorDialog(),
    );
  }
  
  /// Get icon for theme mode
  IconData _getIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return lightIcon!;
      case ThemeMode.dark:
        return darkIcon!;
      case ThemeMode.system:
        return systemIcon!;
    }
  }
  
  /// Get tooltip text
  String _getTooltip(BuildContext context, ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Chuyển sang chế độ tối';
      case ThemeMode.dark:
        return 'Chuyển sang chế độ sáng';
      case ThemeMode.system:
        return 'Chuyển chế độ';
    }
  }
  
  /// Get subtitle text
  String _getSubtitle(BuildContext context, ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
      case ThemeMode.system:
        return 'Hệ thống';
    }
  }
}

/// **THEME SELECTOR DIALOG**
/// 
/// Dialog for selecting theme mode
class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final themeCubit = context.read<ThemeCubit>();
        
        return AlertDialog(
          title: Text(context.l10n.themeSettings),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                title: 'Sáng',
                subtitle: 'Luôn sử dụng chế độ sáng',
                icon: Icons.light_mode,
                themeMode: ThemeMode.light,
                isSelected: state.themeMode == ThemeMode.light,
                onTap: () => _selectTheme(context, themeCubit, ThemeMode.light),
              ),
              _ThemeOption(
                title: 'Tối',
                subtitle: 'Luôn sử dụng chế độ tối',
                icon: Icons.dark_mode,
                themeMode: ThemeMode.dark,
                isSelected: state.themeMode == ThemeMode.dark,
                onTap: () => _selectTheme(context, themeCubit, ThemeMode.dark),
              ),
              _ThemeOption(
                title: 'Hệ thống',
                subtitle: 'Theo cài đặt hệ thống',
                icon: Icons.brightness_auto,
                themeMode: ThemeMode.system,
                isSelected: state.themeMode == ThemeMode.system,
                onTap: () => _selectTheme(context, themeCubit, ThemeMode.system),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
          ],
        );
      },
    );
  }
  
  void _selectTheme(BuildContext context, ThemeCubit themeCubit, ThemeMode themeMode) {
    themeCubit.changeTheme(themeMode);
    Navigator.pop(context);
  }
}

/// **THEME OPTION**
/// 
/// Individual theme option in selector
class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode themeMode;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected 
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/services/localization_service.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:get_it/get_it.dart';

/// A button that allows quick toggling between languages
class LanguageToggleButton extends StatelessWidget {
  /// Whether to use an icon button (true) or a regular button (false)
  final bool isIconButton;
  
  /// Optional icon to use for the button
  final IconData? icon;
  
  /// Optional callback after language is changed
  final VoidCallback? onChanged;
  
  /// Creates a LanguageToggleButton widget
  const LanguageToggleButton({
    super.key,
    this.isIconButton = true,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        final localeService = GetIt.I<LocalizationService>();
        final currentLocale = state.locale ?? Localizations.localeOf(context);
        final localeFlag = L10n.getLocaleFlag(currentLocale);
        
        if (isIconButton) {
          return IconButton(
            tooltip: context.l10n.languageSettings,
            onPressed: () => _toggleLanguage(context),
            icon: icon != null 
                ? Icon(icon)
                : Text(
                    localeFlag,
                    style: const TextStyle(fontSize: 18),
                  ),
          );
        } else {
          return ElevatedButton.icon(
            onPressed: () => _toggleLanguage(context),
            icon: Text(
              localeFlag,
              style: const TextStyle(fontSize: 18),
            ), 
            label: Text(L10n.getLanguageName(currentLocale)),
          );
        }
      },
    );
  }
  
  /// Toggles the language and shows a confirmation message
  void _toggleLanguage(BuildContext context) {
    // Toggle language
    context.read<LocaleCubit>().toggleLocale();
    
    // Run callback if provided
    onChanged?.call();
    
    // Show a snackbar to confirm the change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.languageChanged),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 
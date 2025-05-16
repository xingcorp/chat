import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';

/// A widget that shows the current language with animation effects
class LanguageIndicator extends StatelessWidget {
  /// Whether to show the language name (true) or just the flag (false)
  final bool showLanguageName;
  
  /// Size of the flag emoji
  final double flagSize;
  
  /// Text style for the language name
  final TextStyle? textStyle;
  
  /// Creates a LanguageIndicator widget
  const LanguageIndicator({
    super.key,
    this.showLanguageName = true,
    this.flagSize = 24,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        final currentLocale = state.locale ?? Localizations.localeOf(context);
        final flag = L10n.getLocaleFlag(currentLocale);
        
        return _AnimatedLanguageDisplay(
          flag: flag,
          languageName: showLanguageName ? L10n.getLanguageName(currentLocale) : null,
          flagSize: flagSize,
          textStyle: textStyle,
        );
      },
    );
  }
}

/// A widget that displays a language with animation effects
class _AnimatedLanguageDisplay extends StatelessWidget {
  /// The flag emoji to display
  final String flag;
  
  /// The language name to display, or null to hide it
  final String? languageName;
  
  /// Size of the flag emoji
  final double flagSize;
  
  /// Text style for the language name
  final TextStyle? textStyle;

  /// Creates an _AnimatedLanguageDisplay widget
  const _AnimatedLanguageDisplay({
    required this.flag,
    this.languageName,
    required this.flagSize,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated flag
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: Text(
                  flag,
                  style: TextStyle(fontSize: flagSize),
                ),
              ),
            );
          },
        ),
        
        // Optional language name
        if (languageName != null) ...[
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  languageName!,
                  style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
} 
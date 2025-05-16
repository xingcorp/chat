import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/services/localization_service.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/blocs/locale/locale_cubit.dart';
import 'package:get_it/get_it.dart';

/// A widget that displays language options for the user to select
class LanguageSelectorScreen extends StatelessWidget {
  /// Creates a LanguageSelectorScreen widget
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = GetIt.I<LocalizationService>();
    final supportedLocales = localizationService.getSupportedLocales();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.selectLanguage),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // System default option
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.language),
            ),
            title: Text(context.l10n.systemDefault),
            onTap: () {
              context.read<LocaleCubit>().changeLocale(null);
              Navigator.pop(context);
            },
            trailing: BlocBuilder<LocaleCubit, LocaleState>(
              builder: (context, state) {
                return state.locale == null
                    ? const Icon(Icons.check, color: Colors.green)
                    : const SizedBox.shrink();
              },
            ),
          ),
          
          const Divider(),
          
          // List of supported languages
          Expanded(
            child: ListView.builder(
              itemCount: supportedLocales.length,
              itemBuilder: (context, index) {
                final localeInfo = supportedLocales[index];
                return _LanguageListTile(localeInfo: localeInfo);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A list tile that represents a language option
class _LanguageListTile extends StatelessWidget {
  /// The locale information to display
  final LocaleInfo localeInfo;
  
  /// Creates a _LanguageListTile widget
  const _LanguageListTile({required this.localeInfo});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        final isSelected = state.locale?.languageCode == localeInfo.locale.languageCode;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(localeInfo.flag, style: const TextStyle(fontSize: 22)),
            ),
            title: Text(localeInfo.name),
            trailing: isSelected 
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              context.read<LocaleCubit>().changeLocale(localeInfo.locale);
              
              // Show confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.languageChanged),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: context.l10n.close,
                    onPressed: () {},
                  ),
                ),
              );
              
              // Close the language selector
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
} 
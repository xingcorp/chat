# Localization Guide

This document explains how to use, maintain, and extend the localization system in the Flutter Chat App.

## Overview

The app uses Flutter's built-in localization system with .arb (Application Resource Bundle) files through the `flutter_localizations` and code generation. This approach provides:

- Type-safe access to translations
- IDE auto-completion support
- Support for plurals and formatted messages (parameters)
- Better performance compared to JSON-based solutions

Currently, the app supports the following languages:
- English (en)
- Vietnamese (vi)

## How to Use Localized Strings

### Accessing Translations

You can access translations using the context extension:

```dart
// In any widget with access to BuildContext
Text(context.l10n.appTitle);
Text(context.l10n.login);
```

### Formatted Messages

Some messages contain placeholders:

```dart
// Message with one parameter
Text(context.l10n.lastSeen('5 minutes ago'));

// Pluralized message
Text(context.l10n.messageCount(5));
```

### Changing Language

The app supports changing languages in two ways:

1. Using the `LocaleCubit`:

```dart
// Change to specific language
context.read<LocaleCubit>().changeLocale(const Locale('en'));

// Reset to system default
context.read<LocaleCubit>().changeLocale(null);

// Toggle between available languages
context.read<LocaleCubit>().toggleLocale();
```

2. Using the provided widgets:

```dart
// Show language selector screen
Navigator.push(
  context, 
  MaterialPageRoute(builder: (_) => const LanguageSelectorScreen()),
);

// Use language toggle button
LanguageToggleButton(
  isIconButton: true,
  onChanged: () {
    // Optional callback when language changes
  },
);

// Use language indicator
LanguageIndicator(
  showLanguageName: true,
  flagSize: 24,
);
```

## Adding New Translations

### 1. Update the ARB Files

To add new strings:

1. First add the string to `lib/l10n/app_en.arb`:

```json
{
  "newFeatureTitle": "My New Feature",
  "@newFeatureTitle": {
    "description": "Title for the new feature screen"
  }
}
```

2. Then add the translation to `lib/l10n/app_vi.arb`:

```json
{
  "newFeatureTitle": "Tính năng mới của tôi"
}
```

### 2. Adding a New Language

To add support for a new language:

1. Add the locale to `lib/l10n/l10n.dart`:

```dart
static const all = [
  Locale('en'),
  Locale('vi'),
  Locale('fr'), // New language
];
```

2. Add its display name and flag:

```dart
static String getLanguageName(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return 'English';
    case 'vi': return 'Tiếng Việt';
    case 'fr': return 'Français'; // New language
    default: return locale.languageCode;
  }
}

static String getLocaleFlag(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return '🇺🇸';
    case 'vi': return '🇻🇳';
    case 'fr': return '🇫🇷'; // New language
    default: return '🏳️';
  }
}
```

3. Create a new ARB file named `lib/l10n/app_fr.arb` (for French):

```json
{
  "@@locale": "fr",
  "appTitle": "Application de Chat Flutter",
  // Add all other translations
}
```

## Best Practices

1. **Use descriptive keys**: Make keys that describe what the string represents, not its content.

2. **Keep translations organized**: Group related strings with prefixes like `auth.`, `chat.`, etc.

3. **Add descriptions**: Always add descriptions for translators in the `app_en.arb` file.

4. **Use placeholders for dynamic content**: Never concatenate strings, use formatted messages instead.

   ```dart
   // BAD
   Text('Hello, ' + userName);
   
   // GOOD (in ARB file)
   "greeting": "Hello, {name}",
   "@greeting": {
     "description": "Greeting message",
     "placeholders": {
       "name": {
         "type": "String"
       }
     }
   }
   
   // GOOD (in code)
   Text(context.l10n.greeting(userName));
   ```

5. **Use plurals**: For strings that need to handle different quantities.

   ```dart
   // In ARB file
   "itemCount": "{count, plural, =0{No items} =1{One item} other{{count} items}}",
   
   // In code
   Text(context.l10n.itemCount(items.length));
   ```

## Architecture

The localization system consists of:

- **ARB Files** (`lib/l10n/*.arb`): Store all translations.
- **L10n Helper** (`lib/l10n/l10n.dart`): Defines supported locales and provides utilities.
- **LocalizationService** (`lib/core/services/localization_service.dart`): Manages locale persistence.
- **LocaleCubit** (`lib/presentation/blocs/locale/locale_cubit.dart`): Handles locale state management.
- **UI Components** in `lib/presentation/widgets/settings/*`: Language selection UI.

The app stores the user's language preference in `SharedPreferences` and defaults to the system language if no preference is set. 
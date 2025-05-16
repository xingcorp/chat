# Internationalization Best Practices

## Overview

This document describes best practices and standards for implementing and managing internationalization (i18n) in the Flutter Chat App. These guidelines ensure consistent, maintainable, and efficient localization across the application.

## Architecture

Our internationalization system uses Flutter's built-in localization tools:

- **ARB Files**: Source of truth for all translations
- **Flutter Intl Package**: Code generation from ARB files
- **LocaleCubit + Bloc**: State management for language selection
- **LocalizationService**: Persistence of language preferences
- **Extension Methods**: For convenient access to translations

## Folder Structure

```
lib/
├── l10n/                      # Localization directory
│   ├── app_en.arb             # English translations
│   ├── app_vi.arb             # Vietnamese translations
│   ├── app_*.arb              # Other language translations
│   └── l10n.dart              # Helper class and extensions
├── core/
│   └── services/
│       └── localization_service.dart  # Service to manage locale preferences
└── presentation/
    ├── blocs/
    │   └── locale/            # State management for locale
    │       ├── locale_cubit.dart
    │       └── locale_state.dart
    └── widgets/
        └── settings/          # UI components for language selection
            ├── language_selector.dart
            └── language_toggle_button.dart
```

## Implementation Guidelines

### 1. Adding New Translations

Always add new strings to `app_en.arb` first, then to other language files:

```json
// In app_en.arb
{
  "settingsTitle": "Settings",
  "@settingsTitle": {
    "description": "Title for the settings screen"
  }
}

// In app_vi.arb
{
  "settingsTitle": "Cài đặt"
}
```

### 2. String Key Naming Convention

Use descriptive, hierarchical keys:

- ✅ `auth.loginButton`, `chat.messageBubble`, `settings.languageSection`
- ❌ `button1`, `text2`, `label3`

### 3. Parameter and Plural Handling

Use ICU message syntax for dynamic content:

```json
// Simple parameter
"greeting": "Hello, {name}",
"@greeting": {
  "description": "Greeting message with user's name",
  "placeholders": {
    "name": {
      "type": "String",
      "example": "John"
    }
  }
}

// Pluralization
"messageCount": "{count, plural, =0{No messages} =1{1 message} other{{count} messages}}",
"@messageCount": {
  "description": "Message count with pluralization",
  "placeholders": {
    "count": {
      "type": "int",
      "format": "compact"
    }
  }
}

// Date/time formatting
"lastSeen": "Last seen {date}",
"@lastSeen": {
  "description": "When user was last active",
  "placeholders": {
    "date": {
      "type": "DateTime",
      "format": "yMd"
    }
  }
}
```

### 4. Using Translations in Code

```dart
// Basic usage with context extension
Text(context.l10n.settingsTitle);

// With parameters
Text(context.l10n.greeting(user.name));

// With pluralization
Text(context.l10n.messageCount(messages.length));

// With date formatting
Text(context.l10n.lastSeen(user.lastActive));
```

### 5. Context-Free Access (Outside Widget Tree)

In places where BuildContext is not available (like services or repositories):

```dart
// Import the generated file
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Use the lookup method
final messages = AppLocalizations.delegate.load(locale);
final translatedText = messages.settingsTitle;
```

## Quality Assurance

### Translation Quality

1. **Completeness**: Ensure all strings have translations in all supported languages
2. **Context**: Provide clear descriptions in ARB files for translators
3. **Validation**: Verify translations fit UI space constraints
4. **Testing**: Test UI in all supported languages, especially for text overflow

### Technical Quality

1. **No Hardcoded Strings**: All user-visible text must use the localization system
2. **String Extraction**: Periodically review code for missed localizations
3. **Keys Maintenance**: Remove unused keys, consolidate similar keys
4. **Performance Monitoring**: Watch for translation bundle size growth

## Advanced Features

### String Variations

For gender-specific or other variations:

```json
"inviteMessage": "{gender, select, male{He invited you} female{She invited you} other{They invited you}}",
"@inviteMessage": {
  "description": "Invitation message with gender variation",
  "placeholders": {
    "gender": {
      "type": "String"
    }
  }
}
```

### Nested Messages

For complex strings with multiple parameters:

```json
"commentNotification": "{username} commented on {gender, select, male{his} female{her} other{their}} {postType, select, photo{photo} video{video} other{post}}",
```

## Localization Workflow

1. **Development**: Add new strings in English
2. **Translation**: Get strings translated to other languages
3. **Integration**: Add translations to respective ARB files
4. **Testing**: Verify translations in context
5. **Maintenance**: Keep translations up-to-date with app changes

## Tools and Resources

- [Flutter Intl VS Code Extension](https://marketplace.visualstudio.com/items?itemName=localizely.flutter-intl)
- [ARB Format Documentation](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [ICU Message Format](http://userguide.icu-project.org/formatparse/messages)
- [Flutter Localization Documentation](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)

## Common Issues and Solutions

### 1. Missing Translations

If a translation is missing, the app will fall back to the base language (English).

### 2. Long Translations

Some languages require more space than others. Use flexible layouts and test with long texts.

### 3. RTL Support

For languages like Arabic or Hebrew that read right-to-left:

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: YourWidget(),
)
```

### 4. Formatting Issues

Use the appropriate format for different data types:

```json
"price": "{price, number, currency}",
"@price": {
  "description": "Product price with currency formatting",
  "placeholders": {
    "price": {
      "type": "double",
      "format": "currency"
    }
  }
}
```

## Conclusion

Following these best practices ensures our app provides a high-quality, consistent experience to users across different languages and regions. The standardized approach also makes maintenance easier as the app grows over time. 
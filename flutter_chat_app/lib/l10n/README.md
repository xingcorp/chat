# Localization Guidelines

This directory contains files related to the Flutter Chat App internationalization system.

## Directory Structure

```
l10n/
├── app_en.arb       # English translations (source of truth)
├── app_vi.arb       # Vietnamese translations 
├── l10n.dart        # Helper class with extension methods
└── README.md        # This file
```

## How Localization Works

1. The app uses Flutter's built-in intl-based localization with ARB files
2. The `generate: true` flag in pubspec.yaml enables code generation
3. ARB files contain keys, translations, and metadata
4. The `flutter_localizations` package provides core localization support
5. The `LocaleCubit` manages the app's current locale state
6. A Flutter extension method (`context.l10n`) provides easy access to translations
7. Helper classes provide utilities for date formatting, RTL support, and more

## Components Overview

* **ARB Files**: Source of translations for each supported language
* **L10n Helper Class**: Utility functions for formatting and locale management
* **LocaleCubit**: State management for locale selection
* **LocalizationService**: Advanced locale handling and persistence
* **Extensions**: Context extensions for easy access to localized resources
* **Widgets**: Specialized UI components for language selection

## Usage

### Basic String Translation

```dart
// In a widget:
Text(context.l10n.appTitle);
```

### Parameterized Strings

```dart
// String with a parameter:
Text(context.l10n.greeting('John'));

// Pluralization:
Text(context.l10n.messageCount(5));
```

### Date and Time Formatting

```dart
// Formatted date using the L10n helper:
Text(L10n.formatRelativeDate(context, message.timestamp));

// Using LocalizationService:
final localizationService = GetIt.I<LocalizationService>();
Text(localizationService.formatDate(date, context.locale));
```

### RTL Support

```dart
// Check if current locale is RTL
final isRtl = context.isRtl;

// Use directional properties
padding: EdgeInsets.only(
  start: 16, // Instead of left
  end: 8,    // Instead of right
),

// Using context extensions for RTL-aware padding
padding: context.horizontalPadding(start: 16, end: 8),

// Alignment based on text direction
alignment: context.isRtl ? Alignment.centerRight : Alignment.centerLeft,
// Or using the helper
alignment: context.textDirection == TextDirection.rtl 
    ? Alignment.centerRight
    : Alignment.centerLeft,

// Using specialized helper
alignment: context.isRtl ? Alignment.centerRight : Alignment.centerLeft,
```

### Changing Language

```dart
// Switch to specific language:
context.read<LocaleCubit>().changeLocale(const Locale('vi'));

// Use system default:
context.read<LocaleCubit>().changeLocale(null);

// Cycle through available languages:
context.read<LocaleCubit>().toggleLocale();
```

### Language Selection UI

```dart
// Show language picker screen:
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LanguageSelectorScreen()),
);

// Language toggle button:
LanguageToggleButton(
  isIconButton: true,
  onChanged: () {
    // Optional callback when language changes
  },
);

// Language indicator with flag:
LanguageIndicator(showLanguageName: true);
```

## Supporting RTL Languages

For right-to-left (RTL) languages like Arabic, Hebrew, Farsi, and Urdu:

1. Always use `start` and `end` instead of `left` and `right` for RTL support
2. Use `TextDirection` to determine layout direction
3. Test all screens in both LTR and RTL modes
4. Be careful with icons that imply direction (like arrows)
5. Use Flutter's built-in RTL support:

```dart
Directionality(
  textDirection: context.textDirection,
  child: yourWidget,
);
```

## Adding New Translations

1. First, add the new string to `app_en.arb`:

```json
{
  "newFeatureTitle": "My New Feature",
  "@newFeatureTitle": {
    "description": "Title for the new feature screen"
  }
}
```

2. Then add translations to other language files:

```json
// In app_vi.arb:
{
  "newFeatureTitle": "Tính năng mới của tôi"
}
```

3. Run the generator to update generated code:

```bash
flutter gen-l10n
```

## Adding a New Language

1. Create a new ARB file named `app_<language_code>.arb`
2. Add the locale to the `L10n.all` list in `l10n.dart`
3. Add language name and flag emoji to the helper methods in `l10n.dart`
4. Run `flutter gen-l10n` to generate code for the new language
5. Update the `getLanguageName` and `getLocaleFlag` methods

## Working with Parameters

### Simple Parameters

```json
// In ARB file:
"greeting": "Hello, {name}!",
"@greeting": {
  "description": "Personal greeting with user name",
  "placeholders": {
    "name": {
      "type": "String",
      "example": "Jane"
    }
  }
}

// In code:
Text(context.l10n.greeting(userName));
```

### Plural Parameters

```json
// In ARB file:
"itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
"@itemCount": {
  "description": "Count of items with pluralization",
  "placeholders": {
    "count": {
      "type": "int",
      "format": "compact"
    }
  }
}

// In code:
Text(context.l10n.itemCount(items.length));
```

### Date and Time Parameters

```json
// In ARB file:
"meetingSchedule": "Meeting scheduled for {date} at {time}",
"@meetingSchedule": {
  "description": "Meeting date and time information",
  "placeholders": {
    "date": {
      "type": "DateTime",
      "format": "yMd" 
    },
    "time": {
      "type": "DateTime",
      "format": "Hm"
    }
  }
}

// In code:
Text(context.l10n.meetingSchedule(meeting.date, meeting.time));
```

### Select Parameters (for Gender/Context)

```json
// In ARB file:
"messageSender": "{gender, select, male{He sent a message} female{She sent a message} other{They sent a message}}",
"@messageSender": {
  "description": "Message about who sent a message with gender context",
  "placeholders": {
    "gender": {
      "type": "String"
    }
  }
}

// In code:
Text(context.l10n.messageSender(user.gender));
```

## Advanced Features

### Custom Date Formats

For specialized date formatting beyond what the ARB system provides:

```dart
// Using the L10n helper
final formattedDate = L10n.formatRelativeDate(context, message.timestamp);

// Using the LocalizationService for more control
final localizationService = GetIt.I<LocalizationService>();
final formattedDate = localizationService.formatDate(date, context.locale); 
```

### Numeric Formatting

```dart
// Format numbers with thousand separators
final formattedNumber = L10n.formatNumber(context, 1234567);  // "1,234,567"

// Format currency values
final formattedCurrency = L10n.formatCurrency(context, 1234.56, 'USD');  // "$1,234.56"
```

### File Size Formatting

```dart
// Format file sizes with appropriate units
final formattedSize = L10n.formatFileSize(context, 1536000);  // "1.5 MB"
```

## Error Handling

The app includes robust error handling for translations:

1. Missing translations fall back to English
2. Invalid parameters use sensible defaults
3. Translation errors are logged for tracking
4. Runtime errors don't crash the app

If you encounter issues with translations:

1. Check the ARB files for the correct key
2. Verify parameters match the expected types
3. Run the generator again if needed
4. Check logs for any reported translation errors

## Best Practices

1. **Use descriptive keys**: Make keys that describe what the string represents, not its content
2. **Provide descriptions**: Always add descriptions in the ARB files for translators
3. **Group related strings**: Use a consistent naming structure for related strings
4. **Use placeholders**: Never concatenate strings, use parameters instead
5. **Test with different languages**: Verify UI works with various text lengths
6. **Handle RTL languages**: Use start/end instead of left/right for proper RTL support
7. **Document for translators**: Provide context about where and how strings are used
8. **Keep translations up to date**: Regularly update all language files when adding new strings
9. **Test with edge cases**: Very short/long texts, special characters, etc.
10. **Maintain consistency**: Use similar wording and tone across the app

## Further Reading

See [internationalization_best_practices.md](../../docs/internationalization_best_practices.md) in the docs directory for more detailed information. 
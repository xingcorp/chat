# Localization Guidelines

This directory contains files related to the Flutter Chat App internationalization system.

## Directory Structure

```
l10n/
├── app_en.arb       # English translations
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
// Formatted date:
Text(context.l10n.lastSeen(user.lastActive));

// Helper function in L10n class:
Text(L10n.formatRelativeDate(context, message.timestamp));
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

## Best Practices

1. **Use descriptive keys**: Make keys that describe what the string represents, not its content
2. **Provide descriptions**: Always add descriptions in the ARB files for translators
3. **Group related strings**: Use a consistent naming structure for related strings
4. **Use placeholders**: Never concatenate strings, use parameters instead
5. **Test with different languages**: Verify UI works with various text lengths
6. **Handle RTL languages**: Use start/end instead of left/right for proper RTL support
7. **Document for translators**: Provide context about where and how strings are used

## Further Reading

See [internationalization_best_practices.md](../../docs/internationalization_best_practices.md) in the docs directory for more detailed information. 
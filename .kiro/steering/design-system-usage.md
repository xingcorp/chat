---
inclusion: always
---

# Design System Usage - MANDATORY

> All UI code MUST use design system components. Direct Flutter widgets, hardcoded colors/dimensions/strings are FORBIDDEN.

## Source Files

- AppColors: #[[file:flutter_chat_app/lib/core/theme/app_colors.dart]]
- AppTextStyle: #[[file:flutter_chat_app/lib/core/theme/app_text_styles.dart]]
- AppDimens: #[[file:flutter_chat_app/lib/core/constants/app_dimens.dart]]
- AppConstants: #[[file:flutter_chat_app/lib/core/constants/app_constants.dart]]
- AppTheme: #[[file:flutter_chat_app/lib/core/theme/app_theme.dart]]

## Rules

### 1. Components → App* widgets only

```dart
// ❌ FORBIDDEN          → ✅ REQUIRED
Text('Hello')            → AppText(context.l10n.hello)
ElevatedButton(...)      → AppButton(label: context.l10n.save, onPressed: _save)
TextField(...)           → AppTextField(label: context.l10n.email, controller: _ctrl)
ListView.builder(...)    → AppListView(items: items, itemBuilder: ...)
AlertDialog(...)         → AppAlertDialog.show(context, title: context.l10n.alert)
SnackBar(...)            → AppSnackBar.show(context, message: context.l10n.success)
CircularProgressIndicator → AppProgressIndicator()
```

### 2. Strings → context.l10n only

```dart
// ❌ AppText('Welcome')  AppButton(label: 'Save')
// ✅ AppText(context.l10n.welcome)  AppButton(label: context.l10n.save)
// Exceptions: technical keys ('cache_key'), debug logs (logger.d('...'))
```

### 3. Colors → AppColors only

```dart
// ❌ Colors.white  Color(0xFF000000)  color.withOpacity(0.5)
// ✅ AppColors.textPrimaryDarkMode  AppColors.backgroundDarkMode  color.withValues(alpha: 0.5)
// Dark mode: final c = isDark ? AppColors.textPrimaryDarkMode : AppColors.textPrimary;
```

### 4. Dimensions → AppDimens only

```dart
// ❌ EdgeInsets.all(16.0)  height: 48.0  BorderRadius.circular(8.0)
// ✅ EdgeInsets.all(AppDimens.paddingMedium)  height: AppDimens.touchTargetMin  BorderRadius.circular(AppDimens.radiusMedium)
```

## Component Quick Reference

| Category | Components |
|---|---|
| Typography | `AppText` (with `AppTextStyle.*`) |
| Buttons | `AppButton`, `AppIconButton`, `AppFloatingActionButton` |
| Inputs | `AppTextField`, `AppTextArea`, `AppSearchField`, `AppCheckbox`, `AppSwitch`, `AppRadioGroup`, `AppSlider`, `AppDropdown`, `AppDatePicker`, `AppTimePicker` |
| Lists | `AppListView`, `AppGridView`, `AppListTile`, `AppExpansionTile` |
| Cards | `AppCard`, `AppChip`, `AppTag` |
| Media | `AppAvatar`, `AppImage` |
| Dialogs | `AppAlertDialog`, `AppConfirmDialog`, `AppModalBottomSheet` |
| Feedback | `AppSnackBar`, `AppToast`, `AppBanner`, `AppProgressIndicator`, `AppShimmer` |
| Navigation | `AppBottomNavigationBar` |

## Localization

Add strings to both `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`, then run `flutter gen-l10n`.

Pluralization: `"{count, plural, =0{No items} =1{1 item} other{{count} items}}"`

Parameterized: `"priceFormat": "Price: ${price}"` → `context.l10n.priceFormat('\$100')`

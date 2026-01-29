---
inclusion: always
---

# Design System Usage - MANDATORY

> **CRITICAL**: All UI code MUST use the design system. Direct use of Flutter widgets, hardcoded colors, dimensions, or strings is FORBIDDEN.

## 🚨 Mandatory Rules

### 1. Design System Components - REQUIRED

**ALWAYS use App* components. NEVER use Flutter widgets directly.**

```dart
// ❌ FORBIDDEN - Direct Flutter widgets
Text('Hello')
ListView.builder(...)
GridView.builder(...)
TextField(...)
ElevatedButton(...)
Container(decoration: BoxDecoration(...))
AlertDialog(...)
SnackBar(...)
CircularProgressIndicator()

// ✅ REQUIRED - Design system components
AppText(context.l10n.hello)
AppListView(...)
AppGridView(...)
AppTextField(...)
AppButton(...)
AppCard(...)
AppAlertDialog.show(...)
AppSnackBar.show(...)
AppProgressIndicator(...)
```

### 2. Internationalization - REQUIRED

**ALWAYS use `context.l10n` for ALL user-facing text. NEVER hardcode strings.**

```dart
// ❌ FORBIDDEN - Hardcoded strings
Text('Welcome')
AppText('Hello World')
AppButton(label: 'Save')
AppAlertDialog.show(context, title: 'Error', message: 'Something went wrong')
AppTextField(label: 'Email', hint: 'Enter your email')

// ✅ REQUIRED - Localized strings
AppText(context.l10n.welcome)
AppText(context.l10n.helloWorld)
AppButton(label: context.l10n.save)
AppAlertDialog.show(
  context,
  title: context.l10n.error,
  message: context.l10n.errorSomethingWentWrong,
)
AppTextField(
  label: context.l10n.email,
  hint: context.l10n.emailHint,
)
```

**Exceptions** (only these are allowed):
- Technical keys: `'user_cache_key'`, `'API_KEY'`
- Debug logs: `logger.d('Debug info')`
- Developer-only text (not shown to users)

### 3. Colors - REQUIRED

**ALWAYS use `AppColors`. NEVER use `Colors.*` or hex values.**

```dart
// ❌ FORBIDDEN
Colors.white
Colors.black
Colors.grey
Colors.red
Color(0xFF000000)
color.withOpacity(0.5)

// ✅ REQUIRED
AppColors.textPrimaryDarkMode
AppColors.textSecondaryDarkMode
AppColors.borderDarkMode
AppColors.iconDarkMode
AppColors.surfaceDarkMode
AppColors.backgroundDarkMode
color.withValues(alpha: 0.5)

// Dark mode handling
final isDark = Theme.of(context).brightness == Brightness.dark;
final textColor = isDark 
    ? AppColors.textPrimaryDarkMode 
    : AppColors.textPrimary;
```

### 4. Dimensions - REQUIRED

**ALWAYS use `AppDimens`. NEVER use hardcoded numbers.**

```dart
// ❌ FORBIDDEN
padding: EdgeInsets.all(16.0)
height: 48.0
width: 200.0
fontSize: 14.0
borderRadius: BorderRadius.circular(8.0)

// ✅ REQUIRED
padding: EdgeInsets.all(AppDimens.paddingMedium)
height: AppDimens.touchTargetMin
width: AppDimens.buttonWidthMedium
fontSize: AppDimens.fontSizeMedium
borderRadius: BorderRadius.circular(AppDimens.radiusMedium)
```

---

---

## Design System Components Reference

### Typography (AppText)

**ALWAYS use `AppText` instead of `Text` widget.**

```dart
// ❌ FORBIDDEN - Direct Text widget
Text('Hello')
Text('Title', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
Text('Body text', style: Theme.of(context).textTheme.bodyMedium)

// ✅ REQUIRED - AppText with localization
AppText(
  context.l10n.hello,
  style: AppTextStyle.bodyMedium,
)

AppText(
  context.l10n.title,
  style: AppTextStyle.headlineLarge,
  color: AppColors.textPrimaryDarkMode,
)

AppText(
  context.l10n.subtitle,
  style: AppTextStyle.titleMedium,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)

AppText(
  context.l10n.description,
  style: AppTextStyle.bodySmall,
  color: AppColors.textSecondaryDarkMode,
)

// Available text styles
AppTextStyle.displayLarge      // 57sp - Largest display text
AppTextStyle.displayMedium     // 45sp - Medium display text
AppTextStyle.displaySmall      // 36sp - Small display text
AppTextStyle.headlineLarge     // 32sp - Large headline
AppTextStyle.headlineMedium    // 28sp - Medium headline
AppTextStyle.headlineSmall     // 24sp - Small headline
AppTextStyle.titleLarge        // 22sp - Large title
AppTextStyle.titleMedium       // 16sp - Medium title
AppTextStyle.titleSmall        // 14sp - Small title
AppTextStyle.bodyLarge         // 16sp - Large body text
AppTextStyle.bodyMedium        // 14sp - Medium body text (default)
AppTextStyle.bodySmall         // 12sp - Small body text
AppTextStyle.labelLarge        // 14sp - Large label
AppTextStyle.labelMedium       // 12sp - Medium label
AppTextStyle.labelSmall        // 11sp - Small label

// With custom color
AppText(
  context.l10n.errorMessage,
  style: AppTextStyle.bodyMedium,
  color: AppColors.errorDarkMode,
)

// With text alignment
AppText(
  context.l10n.centeredText,
  style: AppTextStyle.bodyMedium,
  textAlign: TextAlign.center,
)

// With max lines and overflow
AppText(
  context.l10n.longText,
  style: AppTextStyle.bodyMedium,
  maxLines: 3,
  overflow: TextOverflow.ellipsis,
)
```

### Buttons

```dart
// Primary button
AppButton(
  onPressed: _handleSave,
  label: context.l10n.save,  // ✅ Localized
  type: ButtonType.primary,
)

// Icon button
AppIconButton(
  icon: Icons.close,
  onPressed: _handleClose,
  tooltip: context.l10n.close,  // ✅ Localized tooltip
)

// Floating action button
AppFloatingActionButton(
  onPressed: _handleAdd,
  icon: Icons.add,
  tooltip: context.l10n.add,  // ✅ Localized
)
```

### Inputs & Forms

```dart
// Text field
AppTextField(
  controller: _emailController,
  label: context.l10n.email,  // ✅ Localized
  hint: context.l10n.emailHint,  // ✅ Localized
  errorText: _emailError,
)

// Text area
AppTextArea(
  controller: _descriptionController,
  label: context.l10n.description,  // ✅ Localized
  maxLines: 5,
)

// Search field
AppSearchField(
  hint: context.l10n.searchHint,  // ✅ Localized
  onChanged: _handleSearch,
)

// Checkbox
AppCheckbox(
  value: _isChecked,
  label: context.l10n.agreeToTerms,  // ✅ Localized
  onChanged: (value) => setState(() => _isChecked = value ?? false),
)

// Switch
AppSwitch(
  value: _isEnabled,
  label: context.l10n.enableNotifications,  // ✅ Localized
  onChanged: (value) => setState(() => _isEnabled = value),
)

// Radio group
AppRadioGroup<String>(
  value: _selectedOption,
  options: [
    RadioOption(value: 'option1', label: context.l10n.option1),  // ✅ Localized
    RadioOption(value: 'option2', label: context.l10n.option2),  // ✅ Localized
  ],
  onChanged: (value) => setState(() => _selectedOption = value),
)

// Slider
AppSlider(
  value: _volume,
  min: 0,
  max: 100,
  label: context.l10n.volume,  // ✅ Localized
  onChanged: (value) => setState(() => _volume = value),
)

// Dropdown
AppDropdown<String>(
  value: _selectedCountry,
  label: context.l10n.country,  // ✅ Localized
  items: [
    DropdownItem(value: 'vn', label: context.l10n.vietnam),  // ✅ Localized
    DropdownItem(value: 'us', label: context.l10n.unitedStates),  // ✅ Localized
  ],
  onChanged: (value) => setState(() => _selectedCountry = value),
)

// Date picker
AppDatePicker(
  selectedDate: _selectedDate,
  label: context.l10n.selectDate,  // ✅ Localized
  onDateSelected: (date) => setState(() => _selectedDate = date),
)

// Time picker
AppTimePicker(
  selectedTime: _selectedTime,
  label: context.l10n.selectTime,  // ✅ Localized
  onTimeSelected: (time) => setState(() => _selectedTime = time),
)

// Rating
AppRating(
  rating: _rating,
  label: context.l10n.rateExperience,  // ✅ Localized
  onRatingChanged: (rating) => setState(() => _rating = rating),
)
```

### Lists & Grids (MANDATORY for Collections)

```dart
// List view - REQUIRED for lists
AppListView(
  items: _messages,
  itemBuilder: (message) => AppListTile(
    title: message.senderName,
    subtitle: message.content,
    leading: AppAvatar(imageUrl: message.senderAvatar),
    trailing: Text(message.timestamp),
  ),
  emptyMessage: context.l10n.noMessages,  // ✅ Localized
)

// Grid view - REQUIRED for grids
AppGridView(
  items: _products,
  crossAxisCount: 2,
  itemBuilder: (product) => AppCard(
    child: Column(
      children: [
        AppImage(imageUrl: product.imageUrl),
        AppText(product.name, style: AppTextStyle.titleSmall),
        AppText(
          context.l10n.priceFormat(product.price),
          style: AppTextStyle.bodyMedium,
        ),  // ✅ Localized with parameter
      ],
    ),
  ),
  emptyMessage: context.l10n.noProducts,  // ✅ Localized
)

// Expansion tile
AppExpansionTile(
  title: context.l10n.advancedSettings,  // ✅ Localized
  children: [
    AppListTile(title: context.l10n.setting1),
    AppListTile(title: context.l10n.setting2),
  ],
)
```

### Cards & Badges

```dart
// Card
AppCard(
  child: Column(
    children: [
      AppText(context.l10n.cardTitle, style: AppTextStyle.titleMedium),  // ✅ Localized
      AppText(context.l10n.cardContent, style: AppTextStyle.bodyMedium),  // ✅ Localized
    ],
  ),
)

// Chip
AppChip(
  label: context.l10n.tagName,  // ✅ Localized
  onDeleted: _handleDelete,
)

// Tag
AppTag(
  label: context.l10n.statusNew,  // ✅ Localized
  type: TagType.success,
)
```

### Media

```dart
// Avatar
AppAvatar(
  imageUrl: user.avatarUrl,
  size: AvatarSize.medium,
  fallbackText: user.initials,
)

// Image
AppImage(
  imageUrl: product.imageUrl,
  fit: BoxFit.cover,
  placeholder: AppShimmer(child: Container()),
  errorWidget: Icon(Icons.error, color: AppColors.errorDarkMode),
)
```

### Dialogs & Bottom Sheets

```dart
// Alert dialog
AppAlertDialog.show(
  context,
  title: context.l10n.alertTitle,  // ✅ Localized
  message: context.l10n.alertMessage,  // ✅ Localized
  confirmText: context.l10n.ok,  // ✅ Localized
)

// Confirm dialog
AppConfirmDialog.show(
  context,
  title: context.l10n.confirmDelete,  // ✅ Localized
  message: context.l10n.confirmDeleteMessage,  // ✅ Localized
  confirmText: context.l10n.delete,  // ✅ Localized
  cancelText: context.l10n.cancel,  // ✅ Localized
  onConfirm: _handleDelete,
)

// Modal bottom sheet
AppModalBottomSheet.show(
  context,
  title: context.l10n.options,  // ✅ Localized
  child: Column(
    children: [
      AppListTile(
        title: context.l10n.edit,  // ✅ Localized
        leading: Icon(Icons.edit),
        onTap: _handleEdit,
      ),
      AppListTile(
        title: context.l10n.delete,  // ✅ Localized
        leading: Icon(Icons.delete),
        onTap: _handleDelete,
      ),
    ],
  ),
)
```

### Feedback Components

```dart
// Snackbar
AppSnackBar.show(
  context,
  message: context.l10n.saveSuccess,  // ✅ Localized
  type: SnackBarType.success,
)

// Toast
AppToast.show(
  context,
  message: context.l10n.itemAdded,  // ✅ Localized
)

// Banner
AppBanner(
  message: context.l10n.warningMessage,  // ✅ Localized
  type: BannerType.warning,
  action: AppButton(
    label: context.l10n.dismiss,  // ✅ Localized
    onPressed: _handleDismiss,
  ),
)

// Progress indicator
AppProgressIndicator(
  type: ProgressType.circular,
  message: context.l10n.loading,  // ✅ Localized (optional)
)

// Shimmer loading
AppShimmer(
  child: Column(
    children: [
      Container(height: 20, color: AppColors.surfaceDarkMode),
      SizedBox(height: AppDimens.spaceSmall),
      Container(height: 20, color: AppColors.surfaceDarkMode),
    ],
  ),
)
```

### Navigation

```dart
// Bottom navigation bar
AppBottomNavigationBar(
  items: [
    BottomNavItem(
      icon: Icons.home,
      label: context.l10n.home,  // ✅ Localized
    ),
    BottomNavItem(
      icon: Icons.chat,
      label: context.l10n.chat,  // ✅ Localized
    ),
    BottomNavItem(
      icon: Icons.person,
      label: context.l10n.profile,  // ✅ Localized
    ),
  ],
  currentIndex: _currentIndex,
  onTap: _handleNavigation,
)
```

---

## Forbidden Patterns

### ❌ NEVER Do This

```dart
// ❌ Direct Flutter widgets
Text('Hello')
Text('Title', style: TextStyle(fontSize: 24))
ListView.builder(...)
GridView.builder(...)
TextField(decoration: InputDecoration(...))
ElevatedButton(child: Text('Save'))
Container(decoration: BoxDecoration(color: Colors.white))
showDialog(context: context, builder: (_) => AlertDialog(...))
ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))

// ❌ Hardcoded strings
Text('Welcome to the app')
AppText('Click me')
AppButton(label: 'Save')
hint: 'Enter your name'
errorText: 'This field is required'

// ❌ Hardcoded colors
color: Colors.white
backgroundColor: Color(0xFF000000)
Colors.red.withOpacity(0.5)

// ❌ Hardcoded dimensions
padding: EdgeInsets.all(16.0)
height: 48.0
fontSize: 14.0
borderRadius: BorderRadius.circular(8.0)
```

### ✅ ALWAYS Do This

```dart
// ✅ Design system components
AppText(context.l10n.hello)
AppText(context.l10n.title, style: AppTextStyle.headlineLarge)
AppListView(...)
AppGridView(...)
AppTextField(label: context.l10n.email)
AppButton(label: context.l10n.save)
AppCard(child: ...)
AppAlertDialog.show(context, title: context.l10n.alert)
AppSnackBar.show(context, message: context.l10n.success)

// ✅ Localized strings
AppText(context.l10n.welcome)
AppText(context.l10n.clickMe)
AppButton(label: context.l10n.save)
hint: context.l10n.nameHint
errorText: context.l10n.fieldRequired

// ✅ Design system colors
color: AppColors.textPrimaryDarkMode
backgroundColor: AppColors.backgroundDarkMode
AppColors.errorDarkMode.withValues(alpha: 0.5)

// ✅ Design system dimensions
padding: EdgeInsets.all(AppDimens.paddingMedium)
height: AppDimens.touchTargetMin
fontSize: AppDimens.fontSizeMedium
borderRadius: BorderRadius.circular(AppDimens.radiusMedium)
```

---

## Import Paths

```dart
// Theme & Constants
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_theme.dart';
import 'package:flutter_chat_app/core/theme/app_text_style.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/constants/app_constants.dart';

// Design System Components
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/buttons.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/forms.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/inputs/inputs.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/lists/lists.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/cards/cards.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/dialogs/dialogs.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback.dart';

// Localization
import 'package:flutter_chat_app/l10n/l10n.dart';
```

---

## Localization Best Practices

### Adding New Strings

1. **Add to ARB files** (`lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`):

```json
// app_en.arb
{
  "welcome": "Welcome",
  "save": "Save",
  "cancel": "Cancel",
  "emailHint": "Enter your email address",
  "priceFormat": "Price: ${price}",
  "@priceFormat": {
    "placeholders": {
      "price": {
        "type": "String"
      }
    }
  }
}

// app_vi.arb
{
  "welcome": "Chào mừng",
  "save": "Lưu",
  "cancel": "Hủy",
  "emailHint": "Nhập địa chỉ email của bạn",
  "priceFormat": "Giá: ${price}"
}
```

2. **Generate localization files**:

```bash
flutter gen-l10n
```

3. **Use in code**:

```dart
// Simple text
AppText(context.l10n.welcome)

// With style
AppText(context.l10n.title, style: AppTextStyle.headlineLarge)

// Button with localized label
AppButton(label: context.l10n.save)

// Text field with localized hint
AppTextField(hint: context.l10n.emailHint)

// With parameter
AppText(context.l10n.priceFormat('$100'))
```

### Pluralization

```json
// app_en.arb
{
  "messageCount": "{count, plural, =0{No messages} =1{1 message} other{{count} messages}}",
  "@messageCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

```dart
Text(context.l10n.messageCount(messages.length))
```

---

## Quick Reference Checklist

### Before Writing UI Code

- [ ] Import design system components, NOT Flutter widgets
- [ ] Import `context.l10n` for localization
- [ ] Import `AppColors` for colors
- [ ] Import `AppDimens` for dimensions
- [ ] Check if the component exists in design system
- [ ] Add missing strings to ARB files first
- [ ] Run `flutter gen-l10n` after adding strings

### Code Review Checklist

- [ ] No direct Flutter widgets (ListView, TextField, ElevatedButton, etc.)
- [ ] No hardcoded strings (all use `context.l10n`)
- [ ] No `Colors.*` or hex colors (all use `AppColors`)
- [ ] No hardcoded numbers (all use `AppDimens` or `AppConstants`)
- [ ] All lists use `AppListView` or `AppGridView`
- [ ] All dialogs use `AppAlertDialog` or `AppConfirmDialog`
- [ ] All feedback uses `AppSnackBar`, `AppToast`, or `AppBanner`
- [ ] All strings exist in both `app_en.arb` and `app_vi.arb`

---

## Quick Reference

**Colors**: `AppColors.textPrimary/DarkMode`, `textSecondary`, `border`, `icon`, `surface`, `background`, `error`, `success`, `warning`

**Dimensions**: `AppDimens.paddingSmall/Medium/Large`, `spaceSmall/Medium/Large`, `radiusSmall/Medium/Large`, `touchTargetMin`, `fontSizeSmall/Medium/Large`

**Buttons**: `AppButton`, `AppIconButton`, `AppFloatingActionButton`

**Inputs**: `AppTextField`, `AppTextArea`, `AppSearchField`, `AppCheckbox`, `AppSwitch`, `AppRadioGroup`, `AppSlider`, `AppDropdown`, `AppDatePicker`, `AppTimePicker`, `AppRating`

**Lists**: `AppListView`, `AppGridView`, `AppListTile`, `AppExpansionTile` (MANDATORY for collections)

**Cards**: `AppCard`, `AppChip`, `AppTag`

**Media**: `AppAvatar`, `AppImage`

**Dialogs**: `AppAlertDialog`, `AppConfirmDialog`, `AppModalBottomSheet`

**Feedback**: `AppSnackBar`, `AppToast`, `AppBanner`, `AppProgressIndicator`, `AppShimmer`

**Navigation**: `AppBottomNavigationBar`

**Localization**: `context.l10n.keyName` (MANDATORY for all user-facing text)

---

**Status**: MANDATORY | **Updated**: 2025-01-29

# Advanced Input Components

This directory contains specialized input components for the design system.

## Components

### 1. AppRichTextEditor
Rich text editor with formatting toolbar.

**Features:**
- Formatting: bold, italic, underline, strikethrough
- Lists: bullet and numbered
- Links: insert and edit
- Undo/redo support
- Markdown output
- Mobile-optimized toolbar

**Usage:**
```dart
AppRichTextEditor(
  controller: _controller,
  onChanged: (text) => _handleTextChange(text),
  placeholder: context.l10n.typeMessage,
  minLines: 3,
  maxLines: 10,
)
```

### 2. AppMentionInput
Text input with @ mention autocomplete.

**Features:**
- Detect @ symbol trigger
- Show user suggestions overlay
- Filter suggestions as user types
- Keyboard navigation
- Support multiple mentions
- Custom mention rendering

**Usage:**
```dart
AppMentionInput(
  controller: _controller,
  onSearch: (query) async => await _searchUsers(query),
  onMentionSelected: (item) => _handleMention(item),
  placeholder: context.l10n.typeMessage,
)
```

### 3. AppAutoComplete
Text input with autocomplete suggestions.

**Features:**
- Async suggestion loading
- Debounced search (300ms default)
- Highlight matching text
- Keyboard navigation
- Custom suggestion builder
- Loading indicator
- Empty state handling

**Usage:**
```dart
AppAutoComplete<String>(
  onSearch: (query) async => await _searchItems(query),
  onSelected: (item) => _handleSelection(item),
  itemBuilder: (item) => Text(item),
  placeholder: context.l10n.typeToSearch,
)
```

### 4. AppMultiSelect
Dropdown with multiple selection support.

**Features:**
- Checkbox list in dropdown
- Selected items as chips
- Search/filter options
- Select all/none buttons
- Chip removal
- Max selection limit
- Custom item rendering

**Usage:**
```dart
AppMultiSelect<String>(
  items: [
    MultiSelectItem(value: '1', label: 'Option 1'),
    MultiSelectItem(value: '2', label: 'Option 2'),
  ],
  selectedValues: _selectedValues,
  onChanged: (values) => setState(() => _selectedValues = values),
  label: context.l10n.selectOptions,
)
```

### 5. AppTagInput
Chip-based tag input.

**Features:**
- Add tags by typing and pressing enter
- Display tags as chips
- Remove tags with backspace or chip close button
- Autocomplete suggestions
- Duplicate prevention
- Max tags limit
- Custom tag validation

**Usage:**
```dart
AppTagInput(
  tags: _tags,
  onChanged: (tags) => setState(() => _tags = tags),
  placeholder: context.l10n.addTag,
  maxTags: 10,
  suggestions: ['Flutter', 'Dart', 'Mobile'],
)
```

### 6. AppOTPInput
OTP/verification code input.

**Features:**
- Individual boxes for each digit
- Auto-focus next box on input
- Auto-focus previous on backspace
- Paste support (splits code across boxes)
- Configurable length (4, 6, 8 digits)
- Numeric or alphanumeric
- Auto-submit on completion

**Usage:**
```dart
AppOTPInput(
  length: 6,
  onCompleted: (code) => _verifyOTP(code),
  onChanged: (code) => print('Current: $code'),
  isNumeric: true,
)
```

## Design Principles

All components follow these principles:

1. **Base Classes**: Extend `BaseStatefulWidget` for lifecycle management
2. **Localization**: Use `context.l10n` for all user-facing text
3. **Theming**: Use `AppColors` and `AppDimens` - no hardcoded values
4. **Dark Mode**: Automatic support via `Theme.of(context).brightness`
5. **Accessibility**: Proper semantics and keyboard navigation
6. **Performance**: Optimized for 60fps rendering

## Keyboard Navigation

All components support keyboard navigation:

- **Arrow Up/Down**: Navigate suggestions
- **Enter**: Select/submit
- **Escape**: Close overlay/cancel
- **Backspace**: Remove last item (tags) or move to previous field (OTP)
- **Tab**: Move to next field

## Customization

All components support customization through:

- Custom builders for items/chips
- Custom validators
- Custom colors (via theme)
- Custom dimensions (via AppDimens)
- Disabled state support

## Testing

Components are designed to be testable:

- All state is managed internally
- Callbacks for all user actions
- Public methods for programmatic control
- Clear separation of concerns

## Examples

See the example app for complete usage examples of all components.

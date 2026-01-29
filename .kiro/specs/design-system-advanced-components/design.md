# Technical Design: Advanced Design System Components

## Overview

This design document specifies 39 advanced UI components to complete the enterprise-grade design system for the Sharitek Office Management chat application. Building upon the 50 components implemented in Phases 1-4, this specification adds critical form inputs, chat-specific widgets, and advanced UI elements while maintaining strict consistency with established patterns.

### Design Goals

1. **Seamless Integration**: All components integrate with existing 50 components without breaking changes
2. **Consistency**: Follow established patterns (BaseStatelessWidget, AppDimens, context.l10n)
3. **Chat-First**: Prioritize components needed for rich messaging experiences
4. **Enterprise Quality**: Production-ready with comprehensive testing and accessibility
5. **Performance**: Maintain 60fps rendering and < 150MB memory usage

### Architecture Principles

- **Base Classes**: All widgets extend BaseStatelessWidget or BaseStatefulWidget
- **Zero Hardcoding**: All dimensions use AppDimens, all strings use context.l10n
- **Theme Integration**: Automatic dark mode support via theme.brightness
- **Accessibility**: WCAG 2.1 AA compliance with proper semantics
- **Testing**: >= 90% coverage with unit, widget, and golden tests


## Architecture

### Component Organization

```
lib/presentation/widgets/design_system/
├── forms/                    # NEW - Form input components
│   ├── app_checkbox.dart
│   ├── app_radio_button.dart
│   ├── app_radio_group.dart
│   ├── app_switch.dart
│   ├── app_slider.dart
│   ├── app_dropdown.dart
│   ├── app_date_picker.dart
│   ├── app_time_picker.dart
│   ├── app_rating.dart
│   └── form_enums.dart
├── chat/                     # NEW - Chat-specific components
│   ├── app_message_bubble.dart
│   ├── app_reply_preview.dart
│   ├── app_reaction_picker.dart
│   ├── app_typing_indicator.dart
│   ├── app_voice_waveform.dart
│   ├── app_read_receipt.dart
│   ├── app_message_status.dart
│   └── chat_enums.dart
├── menus/                    # NEW - Advanced navigation
│   ├── app_context_menu.dart
│   ├── app_popup_menu.dart
│   ├── app_breadcrumb.dart
│   ├── app_tooltip.dart
│   └── app_popover.dart
├── data/                     # NEW - Data display components
│   ├── app_data_table.dart
│   ├── app_timeline.dart
│   ├── app_carousel.dart
│   ├── app_calendar.dart
│   └── app_accordion.dart
├── media/                    # ENHANCED - Additional media components
│   ├── app_file_uploader.dart
│   ├── app_image_gallery.dart
│   ├── app_video_player.dart
│   ├── app_audio_player.dart
│   └── app_emoji_picker.dart
├── advanced_inputs/          # NEW - Specialized inputs
│   ├── app_rich_text_editor.dart
│   ├── app_mention_input.dart
│   ├── app_auto_complete.dart
│   ├── app_multi_select.dart
│   ├── app_tag_input.dart
│   └── app_otp_input.dart
└── layouts/                  # NEW - Responsive layouts
    ├── app_responsive_layout.dart
    ├── app_split_view.dart
    ├── app_resizable_panel.dart
    └── app_sticky_header.dart
```

### Dependency Graph

```
Advanced Components
    ↓
Existing Components (Phases 1-4)
    ↓
Base Classes (BaseStatelessWidget, BaseStatefulWidget)
    ↓
Core (AppDimens, Theme, Localization)
```


## Components and Interfaces

### Phase 1: Form Input Components (Priority: Critical)

#### 1.1 AppCheckbox

**Purpose**: Checkbox with checked, unchecked, and indeterminate states.

**Interface**:
```dart
/// **APP CHECKBOX**
///
/// Checkbox component with three states: checked, unchecked, indeterminate.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Three-state support (checked, unchecked, indeterminate)
/// - Haptic feedback on interaction
/// - Disabled state support
/// - Custom colors and sizes
/// - Accessibility labels
/// - Dark mode support
///
/// **Usage**:
/// ```dart
/// AppCheckbox(
///   value: _isChecked,
///   onChanged: (value) => setState(() => _isChecked = value),
///   label: context.l10n.agreeToTerms,
/// )
///
/// // Indeterminate state
/// AppCheckbox(
///   value: null,
///   tristate: true,
///   onChanged: (value) => _handleChange(value),
/// )
/// ```
class AppCheckbox extends BaseStatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.tristate = false,
    this.activeColor,
    this.checkColor,
    this.size = CheckboxSize.medium,
    this.isDisabled = false,
  });

  /// Current checkbox value (null for indeterminate)
  final bool? value;

  /// Callback when value changes
  final ValueChanged<bool?>? onChanged;

  /// Optional label text
  final String? label;

  /// Whether checkbox supports three states
  final bool tristate;

  /// Active (checked) color
  final Color? activeColor;

  /// Check mark color
  final Color? checkColor;

  /// Checkbox size
  final CheckboxSize size;

  /// Whether checkbox is disabled
  final bool isDisabled;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final checkboxSize = _getCheckboxSize(size);
    
    return Semantics(
      label: label,
      checked: value,
      enabled: !isDisabled,
      child: InkWell(
        onTap: isDisabled ? null : () => _handleTap(),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingSmall),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: checkboxSize,
                height: checkboxSize,
                child: Checkbox(
                  value: value,
                  onChanged: isDisabled ? null : onChanged,
                  tristate: tristate,
                  activeColor: activeColor ?? theme.colorScheme.primary,
                  checkColor: checkColor ?? theme.colorScheme.onPrimary,
                ),
              ),
              if (label != null) ...[
                SizedBox(width: AppDimens.spaceSmall),
                Flexible(
                  child: Text(
                    label!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDisabled
                          ? (isDark ? Colors.white38 : Colors.black38)
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (onChanged == null) return;
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    if (tristate) {
      // Cycle through: false → true → null → false
      if (value == false) {
        onChanged!(true);
      } else if (value == true) {
        onChanged!(null);
      } else {
        onChanged!(false);
      }
    } else {
      onChanged!(!(value ?? false));
    }
  }

  double _getCheckboxSize(CheckboxSize size) {
    switch (size) {
      case CheckboxSize.small:
        return AppDimens.iconSmall;
      case CheckboxSize.medium:
        return AppDimens.iconMedium;
      case CheckboxSize.large:
        return AppDimens.iconLarge;
    }
  }
}

enum CheckboxSize {
  small,
  medium,
  large,
}
```


#### 1.2 AppRadioButton & AppRadioGroup

**Purpose**: Radio button selection with group management.

**Key Design Decisions**:
- AppRadioButton: Individual radio button widget
- AppRadioGroup: Container managing mutual exclusion
- Generic type support for values: `AppRadioGroup<T>`
- Automatic state management within group
- Haptic feedback on selection

**Interface Pattern**:
```dart
AppRadioGroup<String>(
  value: _selectedValue,
  onChanged: (value) => setState(() => _selectedValue = value),
  children: [
    AppRadioButton(value: 'option1', label: context.l10n.option1),
    AppRadioButton(value: 'option2', label: context.l10n.option2),
    AppRadioButton(value: 'option3', label: context.l10n.option3),
  ],
)
```

#### 1.3 AppSwitch

**Purpose**: Toggle switch for binary on/off states.

**Key Design Decisions**:
- Smooth animation between states (300ms)
- Haptic feedback on toggle
- Optional label and description
- Thumb icon support for visual feedback
- Follows Material Design 3 switch specifications

#### 1.4 AppSlider

**Purpose**: Slider for single value or range selection.

**Key Design Decisions**:
- Two modes: single value and range
- Continuous value updates during drag
- Optional value label display
- Snap to divisions support
- Min/max constraints with validation

**Interface Pattern**:
```dart
// Single value
AppSlider(
  value: _volume,
  min: 0,
  max: 100,
  onChanged: (value) => setState(() => _volume = value),
  label: '${_volume.toInt()}%',
)

// Range
AppSlider.range(
  values: RangeValues(_minPrice, _maxPrice),
  min: 0,
  max: 1000,
  onChanged: (values) => setState(() {
    _minPrice = values.start;
    _maxPrice = values.end;
  }),
)
```

#### 1.5 AppDropdown

**Purpose**: Dropdown menu with searchable options.

**Key Design Decisions**:
- Generic type support: `AppDropdown<T>`
- Search functionality for large lists
- Custom item builder support
- Keyboard navigation
- Virtual scrolling for performance

#### 1.6 AppDatePicker & AppTimePicker

**Purpose**: Date and time selection interfaces.

**Key Design Decisions**:
- AppDatePicker: Calendar-based date selection
- AppTimePicker: Clock-based time selection
- Min/max date constraints
- Locale-aware formatting
- Integration with Flutter's showDatePicker/showTimePicker
- Custom styling to match design system

#### 1.7 AppRating

**Purpose**: Star rating input component.

**Key Design Decisions**:
- Configurable star count (default 5)
- Half-star support for decimal ratings
- Read-only mode for display
- Custom icon support (not just stars)
- Tap and drag interaction


### Phase 2: Chat-Specific Components (Priority: Critical)

#### 2.1 AppMessageBubble

**Purpose**: Message bubble supporting text, images, videos, and files.

**Key Design Decisions**:
- Content type variants: text, image, video, file, audio
- Sender/receiver alignment (left/right)
- Tail indicator for message direction
- Long-press for context menu
- Media thumbnail with loading states
- Reply preview integration
- Reaction display
- Timestamp and status indicators

**Interface Pattern**:
```dart
AppMessageBubble.text(
  message: 'Hello, how are you?',
  isSender: false,
  timestamp: DateTime.now(),
  status: MessageStatus.read,
  onLongPress: () => _showContextMenu(),
)

AppMessageBubble.image(
  imageUrl: 'https://...',
  isSender: true,
  timestamp: DateTime.now(),
  onTap: () => _openGallery(),
)

AppMessageBubble.reply(
  message: 'Thanks for the info!',
  replyTo: originalMessage,
  isSender: true,
)
```

#### 2.2 AppReplyPreview

**Purpose**: Preview of message being replied to.

**Key Design Decisions**:
- Compact display with author and content snippet
- Tap to scroll to original message
- Content type indicators (text, image, video, etc.)
- Truncation for long messages
- Integration with AppMessageBubble

#### 2.3 AppReactionPicker

**Purpose**: Emoji reaction picker for messages.

**Key Design Decisions**:
- Grid layout with categories
- Search functionality
- Recently used section
- Skin tone selector
- Animated appearance
- Positioned near message bubble

#### 2.4 AppTypingIndicator

**Purpose**: Animated indicator showing who is typing.

**Key Design Decisions**:
- Bouncing dots animation
- Multiple users support ("John and 2 others are typing...")
- Auto-hide after timeout
- Positioned at bottom of chat
- Smooth fade in/out

#### 2.5 AppVoiceWaveform

**Purpose**: Audio waveform visualization with playback.

**Key Design Decisions**:
- Waveform rendering from audio data
- Playback controls (play/pause, seek)
- Progress indicator
- Speed control (1x, 1.5x, 2x)
- Duration display

#### 2.6 AppReadReceipt

**Purpose**: Message delivery and read status indicators.

**Key Design Decisions**:
- States: sending, sent, delivered, read, failed
- Icon-based indicators (checkmarks)
- Color coding (gray → blue for read)
- Animation on status change
- Compact size for message bubbles

#### 2.7 AppMessageStatus

**Purpose**: Comprehensive message status display.

**Key Design Decisions**:
- Visual states: sending (spinner), sent (✓), delivered (✓✓), read (✓✓ blue), failed (!)
- Retry button for failed messages
- Timestamp display
- Integration with AppMessageBubble


### Phase 3: Advanced Navigation Components

#### 3.1 AppContextMenu

**Purpose**: Context menu displayed at tap/click position.

**Key Design Decisions**:
- Position at tap coordinates
- Automatic edge detection and repositioning
- Menu items with icons and labels
- Dividers for grouping
- Dismiss on outside tap
- Keyboard navigation support

#### 3.2 AppPopupMenu

**Purpose**: Popup menu anchored to a widget.

**Key Design Decisions**:
- Anchored positioning relative to parent widget
- Overflow menu pattern (three dots)
- Custom menu items with callbacks
- Checkable items support
- Nested submenus support

#### 3.3 AppBreadcrumb

**Purpose**: Navigation path with clickable segments.

**Key Design Decisions**:
- Separator customization (/, >, etc.)
- Clickable segments for navigation
- Current page highlighting
- Overflow handling for long paths
- Responsive collapse on mobile

#### 3.4 AppTooltip

**Purpose**: Enhanced tooltip with rich content.

**Key Design Decisions**:
- Hover and long-press triggers
- Smart positioning (top, bottom, left, right)
- Rich content support (not just text)
- Delay before showing
- Arrow pointer to target
- Dismiss on tap outside

#### 3.5 AppPopover

**Purpose**: Floating content anchored to widget.

**Key Design Decisions**:
- Similar to tooltip but for interactive content
- Dismissible with backdrop
- Positioning relative to anchor
- Custom content support
- Animation on show/hide


### Phase 4: Data Display Components

#### 4.1 AppDataTable

**Purpose**: Sortable, filterable data table.

**Key Design Decisions**:
- Column definitions with sort support
- Row selection (single/multiple)
- Filter inputs per column
- Pagination support
- Responsive: horizontal scroll on mobile
- Fixed header on scroll
- Custom cell renderers

**Interface Pattern**:
```dart
AppDataTable<User>(
  columns: [
    DataColumn(label: context.l10n.name, sortable: true),
    DataColumn(label: context.l10n.email, sortable: true),
    DataColumn(label: context.l10n.role, filterable: true),
  ],
  rows: users,
  onSort: (columnIndex, ascending) => _handleSort(columnIndex, ascending),
  onRowTap: (user) => _viewUserDetails(user),
)
```

#### 4.2 AppTimeline

**Purpose**: Vertical timeline for chronological events.

**Key Design Decisions**:
- Vertical layout with connecting lines
- Event markers (dots, icons)
- Event cards with content
- Alternating left/right layout option
- Grouping by date
- Infinite scroll support

#### 4.3 AppCarousel

**Purpose**: Horizontal scrollable carousel.

**Key Design Decisions**:
- Page indicator dots
- Auto-play support with interval
- Swipe gestures
- Snap to page
- Loop mode
- Custom transition animations

#### 4.4 AppCalendar

**Purpose**: Calendar view with date selection.

**Key Design Decisions**:
- Month view with week headers
- Single date and range selection
- Min/max date constraints
- Disabled dates support
- Event markers on dates
- Month/year navigation
- Locale-aware (first day of week)

#### 4.5 AppAccordion

**Purpose**: Collapsible sections with expand/collapse.

**Key Design Decisions**:
- Single or multiple expansion mode
- Smooth height animation
- Custom header and content
- Expand/collapse icons
- Initial expanded state
- Callback on expansion change


### Phase 5: Media and Rich Content Components

#### 5.1 AppFileUploader

**Purpose**: File upload with progress and preview.

**Key Design Decisions**:
- Drag-and-drop support (web/desktop)
- File picker integration
- Upload progress indicator
- Multiple file support
- File type validation
- Size limit validation
- Preview thumbnails
- Remove uploaded files
- Retry failed uploads

#### 5.2 AppImageGallery

**Purpose**: Image gallery with lightbox.

**Key Design Decisions**:
- Grid layout with lazy loading
- Tap to open fullscreen lightbox
- Swipe navigation in lightbox
- Pinch to zoom
- Share and download actions
- Thumbnail caching
- Pagination for large galleries

#### 5.3 AppVideoPlayer

**Purpose**: Video player with controls.

**Key Design Decisions**:
- Play/pause button
- Seek bar with preview
- Volume control
- Fullscreen toggle
- Playback speed
- Quality selection
- Picture-in-picture support
- Auto-hide controls

#### 5.4 AppAudioPlayer

**Purpose**: Audio player with waveform.

**Key Design Decisions**:
- Play/pause button
- Seek bar
- Playback speed (1x, 1.5x, 2x)
- Duration and current time
- Waveform visualization
- Skip forward/backward (15s)
- Background playback support

#### 5.5 AppEmojiPicker

**Purpose**: Comprehensive emoji picker.

**Key Design Decisions**:
- Category tabs (smileys, animals, food, etc.)
- Search functionality
- Recently used section
- Skin tone selector
- Emoji preview on hover
- Grid layout with virtual scrolling
- Keyboard navigation


### Phase 6: Advanced Input Components

#### 6.1 AppRichTextEditor

**Purpose**: Rich text editing with formatting toolbar.

**Key Design Decisions**:
- Formatting: bold, italic, underline, strikethrough
- Lists: bullet and numbered
- Links: insert and edit
- Undo/redo support
- Markdown output option
- HTML output option
- Toolbar customization
- Mobile-optimized toolbar

#### 6.2 AppMentionInput

**Purpose**: Text input with @ mention autocomplete.

**Key Design Decisions**:
- Detect @ symbol trigger
- Show user suggestions overlay
- Filter suggestions as user types
- Keyboard navigation of suggestions
- Insert mention with formatting
- Support multiple mentions
- Custom mention rendering

**Interface Pattern**:
```dart
AppMentionInput(
  controller: _controller,
  onSearch: (query) => _searchUsers(query),
  onMentionSelected: (user) => _insertMention(user),
  mentionBuilder: (user) => UserMentionChip(user),
)
```

#### 6.3 AppAutoComplete

**Purpose**: Text input with autocomplete suggestions.

**Key Design Decisions**:
- Async suggestion loading
- Debounced search
- Highlight matching text
- Keyboard navigation
- Custom suggestion builder
- Loading indicator
- Empty state handling

#### 6.4 AppMultiSelect

**Purpose**: Dropdown with multiple selection support.

**Key Design Decisions**:
- Checkbox list in dropdown
- Selected items as chips
- Search/filter options
- Select all/none buttons
- Chip removal
- Max selection limit
- Custom item rendering

#### 6.5 AppTagInput

**Purpose**: Chip-based tag input.

**Key Design Decisions**:
- Add tags by typing and pressing enter
- Display tags as chips
- Remove tags with backspace or chip close button
- Autocomplete suggestions
- Duplicate prevention
- Max tags limit
- Custom tag validation

#### 6.6 AppOTPInput

**Purpose**: OTP/verification code input.

**Key Design Decisions**:
- Individual boxes for each digit
- Auto-focus next box on input
- Auto-focus previous on backspace
- Paste support (splits code across boxes)
- Configurable length (4, 6, 8 digits)
- Numeric or alphanumeric
- Auto-submit on completion


### Phase 7: Layout and Responsive Components

#### 7.1 AppResponsiveLayout

**Purpose**: Adaptive layout for mobile/tablet/desktop.

**Key Design Decisions**:
- Breakpoint-based layout switching
- Builder pattern for each layout variant
- Smooth transitions between layouts
- Orientation handling
- Safe area management

**Interface Pattern**:
```dart
AppResponsiveLayout(
  mobile: (context) => MobileLayout(),
  tablet: (context) => TabletLayout(),
  desktop: (context) => DesktopLayout(),
)
```

#### 7.2 AppSplitView

**Purpose**: Master-detail layout with resizable divider.

**Key Design Decisions**:
- Desktop: side-by-side with draggable divider
- Mobile: separate screens with navigation
- Tablet: adaptive based on orientation
- Min/max width constraints
- Persist divider position
- Collapse/expand master panel

#### 7.3 AppResizablePanel

**Purpose**: Panels with draggable dividers.

**Key Design Decisions**:
- Horizontal and vertical layouts
- Multiple panels support
- Drag handles between panels
- Min/max size constraints
- Proportional resizing
- Persist panel sizes

#### 7.4 AppStickyHeader

**Purpose**: Header that sticks on scroll.

**Key Design Decisions**:
- Smooth transition to sticky state
- Elevation change when sticky
- Scroll offset detection
- Custom header content
- Optional shrinking animation
- Z-index management


## Data Models

### Enums

#### Form Enums
```dart
// lib/presentation/widgets/design_system/forms/form_enums.dart

enum CheckboxSize { small, medium, large }

enum RadioButtonSize { small, medium, large }

enum SwitchSize { small, medium, large }

enum SliderType { single, range }

enum DropdownPosition { below, above, auto }

enum RatingSize { small, medium, large }
```

#### Chat Enums
```dart
// lib/presentation/widgets/design_system/chat/chat_enums.dart

enum MessageType { text, image, video, audio, file }

enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageAlignment { left, right }

enum ReactionType { like, love, laugh, sad, angry, wow }

enum TypingIndicatorSize { small, medium, large }
```

#### Menu Enums
```dart
// lib/presentation/widgets/design_system/menus/menu_enums.dart

enum MenuPosition { topLeft, topRight, bottomLeft, bottomRight, auto }

enum TooltipPosition { top, bottom, left, right, auto }

enum BreadcrumbSeparator { slash, chevron, arrow, dot }
```

#### Data Display Enums
```dart
// lib/presentation/widgets/design_system/data/data_enums.dart

enum SortDirection { ascending, descending }

enum TimelineAlignment { left, right, alternating }

enum CarouselIndicatorPosition { top, bottom, none }

enum CalendarSelectionMode { single, range, multiple }

enum AccordionMode { single, multiple }
```

### Value Objects

#### DateRange
```dart
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end);
  }

  Duration get duration => end.difference(start);
}
```

#### TimeRange
```dart
class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeRange({required this.start, required this.end});
}
```

#### Mention
```dart
class Mention {
  final String id;
  final String displayName;
  final int startIndex;
  final int endIndex;

  const Mention({
    required this.id,
    required this.displayName,
    required this.startIndex,
    required this.endIndex,
  });
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing all acceptance criteria, I identified the following redundancies:
- Properties 1.17, 1.19, 1.20 (form components) are similar to 8.2, 8.3, 8.4 (all components) → Consolidate into universal properties
- Properties 2.17, 2.18, 2.19 (chat components) are covered by universal properties → Remove duplicates
- Properties testing "FOR ALL components" can be consolidated into fewer comprehensive properties

### Form Component Properties

**Property 1: Checkbox State Rendering**
*For any* AppCheckbox configuration, rendering the checkbox should correctly display checked, unchecked, or indeterminate state based on the value property.
**Validates: Requirements 1.1**

**Property 2: Checkbox Interaction Feedback**
*For any* AppCheckbox with onChanged callback, tapping the checkbox should trigger haptic feedback and invoke the callback with the new value.
**Validates: Requirements 1.2**

**Property 3: Radio Button Mutual Exclusion**
*For any* AppRadioGroup with multiple radio buttons, selecting one button should deselect all other buttons in the group.
**Validates: Requirements 1.3, 1.4**

**Property 4: Switch Toggle Animation**
*For any* AppSwitch, toggling the switch should animate the transition smoothly and provide haptic feedback.
**Validates: Requirements 1.5, 1.6**

**Property 5: Slider Value Updates**
*For any* AppSlider, dragging the slider should continuously update the value within the min/max range and trigger onChanged callbacks.
**Validates: Requirements 1.7, 1.8**

**Property 6: Dropdown Search Filtering**
*For any* AppDropdown with search enabled, typing a search query should filter the displayed options to only those matching the query.
**Validates: Requirements 1.9**

**Property 7: Dropdown Selection Behavior**
*For any* AppDropdown, selecting an option should update the selected value, trigger onChanged callback, and close the dropdown.
**Validates: Requirements 1.10**

### Chat Component Properties

**Property 8: Message Bubble Content Type Rendering**
*For any* AppMessageBubble with content type (text, image, video, file), the bubble should render the appropriate content with correct styling and layout.
**Validates: Requirements 2.1**

**Property 9: Message Bubble Long-Press Menu**
*For any* AppMessageBubble, long-pressing the bubble should display a context menu with available actions.
**Validates: Requirements 2.3**

**Property 10: Reaction Selection**
*For any* AppReactionPicker, selecting a reaction should add it to the message, trigger the onReactionSelected callback, and close the picker.
**Validates: Requirements 2.6**

**Property 11: Message Alignment by Sender**
*For any* chat component with isSender property, sender messages should align right and receiver messages should align left.
**Validates: Requirements 2.16**

### Navigation Component Properties

**Property 12: Context Menu Positioning**
*For any* AppContextMenu, the menu should appear at the tap/click coordinates and remain within screen bounds.
**Validates: Requirements 3.1**

**Property 13: Context Menu Dismissal**
*For any* AppContextMenu, tapping outside the menu should dismiss it with animation.
**Validates: Requirements 3.2**

**Property 14: Breadcrumb Navigation**
*For any* AppBreadcrumb, clicking a segment should trigger the onTap callback with the correct segment index.
**Validates: Requirements 3.6**

**Property 15: Tooltip Smart Positioning**
*For any* AppTooltip near screen edges, the tooltip should reposition itself to remain fully visible on screen.
**Validates: Requirements 3.8**

### Data Display Component Properties

**Property 16: Data Table Sorting**
*For any* AppDataTable with sortable columns, clicking a column header should sort the data by that column in the specified direction.
**Validates: Requirements 4.2**

**Property 17: Data Table Filtering**
*For any* AppDataTable with filters applied, only rows matching all filter criteria should be displayed.
**Validates: Requirements 4.4**

**Property 18: Carousel Swipe Navigation**
*For any* AppCarousel, swiping left/right should animate to the previous/next item and update the page indicator.
**Validates: Requirements 4.8**

**Property 19: Calendar Range Selection**
*For any* AppCalendar in range mode, selecting start and end dates should highlight all dates in the range and trigger onRangeSelected.
**Validates: Requirements 4.10**

**Property 20: Accordion Toggle Behavior**
*For any* AppAccordion, tapping a header should toggle that section's expanded state with smooth animation.
**Validates: Requirements 4.12**

### Media Component Properties

**Property 21: File Upload Progress**
*For any* AppFileUploader during upload, the progress indicator should update continuously from 0% to 100% and display the current percentage.
**Validates: Requirements 5.2**

**Property 22: Image Gallery Lightbox**
*For any* AppImageGallery, tapping an image should open a fullscreen lightbox at that image with swipe navigation enabled.
**Validates: Requirements 5.5**

**Property 23: File Type Validation**
*For any* media upload component with file type restrictions, attempting to upload an invalid file type should be rejected with an error message.
**Validates: Requirements 5.13**

**Property 24: Network Error Retry**
*For any* media component with network error, the retry button should re-attempt the operation when tapped.
**Validates: Requirements 5.18**

### Advanced Input Component Properties

**Property 25: Rich Text Formatting**
*For any* AppRichTextEditor, applying formatting (bold, italic, etc.) should update the text with correct markup while maintaining cursor position.
**Validates: Requirements 6.2**

**Property 26: Mention Filtering**
*For any* AppMentionInput, typing after @ should filter user suggestions to only those matching the typed text.
**Validates: Requirements 6.4**

**Property 27: Mention Insertion**
*For any* AppMentionInput, selecting a mention should insert it with proper formatting and allow continued typing.
**Validates: Requirements 6.5**

**Property 28: Multi-Select Chip Display**
*For any* AppMultiSelect, selecting options should display them as chips with remove buttons.
**Validates: Requirements 6.9**

**Property 29: OTP Auto-Focus**
*For any* AppOTPInput, entering a digit should automatically focus the next input box until all digits are entered.
**Validates: Requirements 6.13**

**Property 30: OTP Completion Callback**
*For any* AppOTPInput, entering the final digit should trigger onCompleted callback with the complete OTP code.
**Validates: Requirements 6.14**

**Property 31: Paste Parsing**
*For any* advanced input component, pasting content should parse it correctly according to the component's format requirements.
**Validates: Requirements 6.15**

### Layout Component Properties

**Property 32: Responsive Layout Selection**
*For any* AppResponsiveLayout, the component should render the mobile layout when width < 600dp, tablet layout when 600dp ≤ width < 1200dp, and desktop layout when width ≥ 1200dp.
**Validates: Requirements 7.1**

**Property 33: Split View Mobile Behavior**
*For any* AppSplitView on mobile screen size, master and detail should render as separate navigable screens.
**Validates: Requirements 7.4**

**Property 34: Resizable Panel Constraints**
*For any* AppResizablePanel, dragging the divider should resize panels while maintaining min/max size constraints.
**Validates: Requirements 7.6**

**Property 35: Sticky Header Transition**
*For any* AppStickyHeader, scrolling past the threshold should transition the header to sticky state with elevation change.
**Validates: Requirements 7.8**

### Universal Component Properties

**Property 36: Base Class Extension**
*For all* new components, each component should extend either BaseStatelessWidget or BaseStatefulWidget.
**Validates: Requirements 8.1**

**Property 37: AppDimens Usage**
*For all* new components, all dimension values should use AppDimens constants (no hardcoded numeric values for spacing, sizing, or radius).
**Validates: Requirements 1.20, 2.17, 8.2**

**Property 38: Localization Usage**
*For all* new components with user-facing text, all strings should use context.l10n (no hardcoded string literals).
**Validates: Requirements 8.3**

**Property 39: Dark Mode Support**
*For all* new components, rendering in dark theme (brightness == Brightness.dark) should use appropriate dark mode colors.
**Validates: Requirements 1.19, 2.18, 8.4**

**Property 40: Accessibility Labels**
*For all* interactive components, each should have proper Semantics widget with meaningful labels.
**Validates: Requirements 1.18, 2.19**

**Property 41: Touch Target Size**
*For all* interactive components, touch targets should be >= 48dp (AppDimens.touchTargetMin).
**Validates: Requirements 8.10**

**Property 42: Disabled State Rendering**
*For all* form and interactive components, disabled state should render with reduced opacity and prevent interactions.
**Validates: Requirements 1.17**

### Performance Properties

**Property 43: List Builder Usage**
*For all* list-based components, the implementation should use ListView.builder or GridView.builder (not ListView/GridView with children).
**Validates: Requirements 10.1**

**Property 44: Image Lazy Loading**
*For all* components displaying images, images should load lazily (only when visible in viewport).
**Validates: Requirements 10.3**

**Property 45: Animation Controller Disposal**
*For all* components with AnimationController, the controller should be disposed in the dispose() method.
**Validates: Requirements 10.5**

**Property 46: Stream Subscription Cancellation**
*For all* components with StreamSubscription, subscriptions should be cancelled in the dispose() method.
**Validates: Requirements 10.8**

**Property 47: Const Constructor Usage**
*For all* stateless components without mutable fields, the constructor should be const.
**Validates: Requirements 10.10**


## Error Handling

### Error Handling Strategy

All components follow consistent error handling patterns:

1. **Validation Errors**: Display inline error messages with red color and error icon
2. **Network Errors**: Show retry button with error message
3. **Loading Errors**: Display AppErrorState with retry action
4. **File Upload Errors**: Show error badge on file with retry/remove options
5. **Media Loading Errors**: Display placeholder with error icon and retry button

### Error States

```dart
// Form validation error
AppTextField(
  controller: _controller,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return context.l10n.fieldRequired;
    }
    return null;
  },
  errorText: _errorText, // Displayed below field in red
)

// Network error with retry
AppImage.network(
  url: imageUrl,
  errorWidget: AppErrorImage(
    onRetry: () => _retryLoad(),
  ),
)

// Upload error
AppFileUploader(
  onError: (file, error) {
    AppSnackBar.error(
      context,
      message: context.l10n.uploadFailed(file.name),
      action: SnackBarAction(
        label: context.l10n.retry,
        onPressed: () => _retryUpload(file),
      ),
    );
  },
)
```

### Error Logging

All errors are logged using AppLogger:

```dart
try {
  await _uploadFile(file);
} catch (e, stackTrace) {
  _logger.error('File upload failed', e, stackTrace);
  _showErrorMessage(context.l10n.uploadFailed);
}
```


## Testing Strategy

### Dual Testing Approach

All components require both unit tests and property-based tests:

- **Unit Tests**: Verify specific examples, edge cases, and error conditions
- **Property Tests**: Verify universal properties across all inputs
- **Together**: Comprehensive coverage (unit tests catch concrete bugs, property tests verify general correctness)

### Unit Testing

**Coverage Target**: >= 90% code coverage

**Test Categories**:
1. **Rendering Tests**: Verify component renders correctly
2. **Interaction Tests**: Verify user interactions work
3. **State Tests**: Verify state updates correctly
4. **Edge Case Tests**: Verify null values, empty lists, boundary conditions
5. **Error Tests**: Verify error handling

**Example Unit Test**:
```dart
group('AppCheckbox', () {
  testWidgets('should render checked state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCheckbox(
            value: true,
            onChanged: (_) {},
            label: 'Test',
          ),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsOneWidget);
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, true);
  });

  testWidgets('should trigger haptic feedback on tap', (tester) async {
    bool callbackInvoked = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCheckbox(
            value: false,
            onChanged: (value) => callbackInvoked = true,
            label: 'Test',
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppCheckbox));
    await tester.pump();

    expect(callbackInvoked, true);
  });

  testWidgets('should support indeterminate state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCheckbox(
            value: null,
            tristate: true,
            onChanged: (_) {},
            label: 'Test',
          ),
        ),
      ),
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, null);
    expect(checkbox.tristate, true);
  });
});
```

### Property-Based Testing

**Configuration**: Minimum 100 iterations per property test

**Property Test Library**: Use `test` package with custom generators

**Tag Format**: `Feature: design-system-advanced-components, Property {number}: {property_text}`

**Example Property Test**:
```dart
group('Property Tests', () {
  test('Property 1: Checkbox State Rendering', () {
    // Feature: design-system-advanced-components, Property 1: Checkbox State Rendering
    
    final random = Random();
    
    for (int i = 0; i < 100; i++) {
      // Generate random checkbox configuration
      final value = random.nextBool() ? random.nextBool() : null;
      final tristate = value == null;
      
      testWidgets('iteration $i', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppCheckbox(
                value: value,
                tristate: tristate,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, value);
        expect(checkbox.tristate, tristate);
      });
    }
  });

  test('Property 3: Radio Button Mutual Exclusion', () {
    // Feature: design-system-advanced-components, Property 3: Radio Button Mutual Exclusion
    
    final random = Random();
    
    for (int i = 0; i < 100; i++) {
      // Generate random number of radio buttons (2-10)
      final buttonCount = 2 + random.nextInt(9);
      final selectedIndex = random.nextInt(buttonCount);
      
      testWidgets('iteration $i with $buttonCount buttons', (tester) async {
        String? selectedValue;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppRadioGroup<int>(
                value: selectedIndex,
                onChanged: (value) => selectedValue = value.toString(),
                children: List.generate(
                  buttonCount,
                  (index) => AppRadioButton(
                    value: index,
                    label: 'Option $index',
                  ),
                ),
              ),
            ),
          ),
        );

        // Verify only one radio button is selected
        final radioButtons = tester.widgetList<Radio>(find.byType(Radio));
        int selectedCount = 0;
        for (final radio in radioButtons) {
          if (radio.groupValue == radio.value) {
            selectedCount++;
          }
        }
        expect(selectedCount, 1);
      });
    }
  });
});
```

### Widget Testing

**Test All Variants**: Each component variant must have widget tests

**Test All States**: normal, hover, pressed, disabled, error, loading

**Test Themes**: Both light and dark themes

**Test Accessibility**: Semantic properties and labels

**Example Widget Test**:
```dart
group('AppButton Variants', () {
  testWidgets('primary variant renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            text: 'Primary',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Primary'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('secondary variant renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.secondary(
            text: 'Secondary',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Secondary'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
});
```

### Golden Testing

**Visual Regression**: Test visual appearance doesn't change

**Test Coverage**:
- All component variants
- All component states
- Light and dark themes
- RTL layouts
- Different screen sizes

**Example Golden Test**:
```dart
group('AppCheckbox Golden Tests', () {
  testWidgets('checked state light theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: AppCheckbox(
            value: true,
            onChanged: (_) {},
            label: 'Checked',
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(AppCheckbox),
      matchesGoldenFile('goldens/checkbox_checked_light.png'),
    );
  });

  testWidgets('checked state dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AppCheckbox(
            value: true,
            onChanged: (_) {},
            label: 'Checked',
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(AppCheckbox),
      matchesGoldenFile('goldens/checkbox_checked_dark.png'),
    );
  });
});
```

### Performance Testing

**Metrics to Measure**:
- Frame rate during scrolling (target: 60fps)
- Memory usage (target: < 150MB)
- Widget build time (target: < 16ms)
- Image loading time (target: < 100ms cached)

**Example Performance Test**:
```dart
test('AppListView maintains 60fps during scroll', () async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppListView(
          itemCount: 1000,
          itemBuilder: (context, index) => ListTile(
            title: Text('Item $index'),
          ),
        ),
      ),
    ),
  );

  await binding.watchPerformance(() async {
    await tester.fling(
      find.byType(AppListView),
      const Offset(0, -500),
      1000,
    );
    await tester.pumpAndSettle();
  });

  final summary = binding.reportData;
  expect(summary['average_frame_build_time_millis'], lessThan(16));
});
```

### Test Organization

```
test/
├── unit/
│   └── widgets/
│       └── design_system/
│           ├── forms/
│           │   ├── app_checkbox_test.dart
│           │   ├── app_radio_button_test.dart
│           │   └── ...
│           ├── chat/
│           │   ├── app_message_bubble_test.dart
│           │   └── ...
│           └── ...
├── widget/
│   └── design_system/
│       ├── forms/
│       │   ├── app_checkbox_widget_test.dart
│       │   └── ...
│       └── ...
├── golden/
│   └── design_system/
│       ├── forms/
│       │   ├── app_checkbox_golden_test.dart
│       │   └── ...
│       └── ...
└── integration/
    └── design_system/
        ├── performance_test.dart
        └── ...
```

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-29  
**Status**: Draft - Awaiting Review


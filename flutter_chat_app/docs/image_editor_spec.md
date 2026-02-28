# Image Editor Integration Specification

## Project Overview
- **Project**: Chat App Image Editor Integration
- **Library**: [pro_image_editor](https://pub.dev/packages/pro_image_editor)
- **Purpose**: Add image editing capability to the chat app following the existing design system pattern

## Requirements Analysis

### Current State
1. **MediaPreview** (`lib/features/chat/presentation/widgets/chat/media_preview.dart`): Displays image/video thumbnails in chat messages with tap-to-view functionality
2. **ImageViewerScreen** (`lib/presentation/screens/media/image_viewer_screen.dart`): Full-screen image viewer with zoom, reactions, and share functionality
3. **ChatInput** (`lib/features/chat/presentation/widgets/chat/chat_input.dart`): Handles message input and attachment selection

### User Flow
1. **Send image with edit option**: User selects image → preview shown → edit button available → edit → send
2. **Edit received image**: User taps image → full view → three-dot menu → edit → update message

### Functional Requirements
- [ ] Add edit button overlay on MediaPreview widget
- [ ] Add edit option in ImageViewerScreen's three-dot menu
- [ ] Use pro_image_editor for editing interface
- [ ] Support both local file and network URL editing
- [ ] Replace/send edited image back to chat

## Architecture

### Design System Pattern
Following existing design system (`lib/presentation/widgets/design_system/`):
- Create wrapper service for pro_image_editor
- Use existing AppIconButton, theme colors
- Consistent with app styling

### Component Structure
```
lib/
├── core/
│   └── services/
│       └── image_editor_service.dart    # NEW: Wrapper service
├── features/chat/presentation/
│   ├── widgets/chat/
│   │   └── media_preview.dart           # MODIFIED: Add edit button
│   └── screens/media/
│       └── image_viewer_screen.dart     # MODIFIED: Add edit menu option
```

## Implementation Plan

### Phase 1: Setup
1. Add `pro_image_editor` to `pubspec.yaml`
2. Create `ImageEditorService` wrapper

### Phase 2: MediaPreview Enhancement
- Add edit button overlay (bottom-right corner)
- Icon: `Icons.edit` or `Icons.edit_outlined`
- Position: Absolute positioning within MediaPreview Stack
- Size: Small (24-32px), matching other action buttons
- Only show for images (not videos)
- Callback: `onEditTap` → opens editor

### Phase 3: ImageViewerScreen Enhancement
- Add edit option to AppPopupMenu (three-dot menu)
- Menu item: "Chỉnh sửa" / "Edit"
- Opens editor with current image

### Phase 4: Integration
- Handle edited image bytes
- Update message with new image OR send as new message
- Show loading state during editing

## pro_image_editor Usage

### Basic Usage
```dart
ProImageEditor.memory(
  imageBytes,
  callbacks: ProImageEditorCallbacks(
    onImageEditingComplete: (Uint8List bytes) {
      // Handle edited image
    },
    onCloseEditor: () {
      // Handle cancel
    },
  ),
)
```

### Network Image
```dart
ProImageEditor.network(
  'https://example.com/image.jpg',
  callbacks: ProImageEditorCallbacks(
    onImageEditingComplete: (Uint8List bytes) {
      // Handle edited image
    },
  ),
)
```

### Local File
```dart
ProImageEditor.file(
  File('path/to/image.jpg'),
  callbacks: ProImageEditorCallbacks(
    onImageEditingComplete: (Uint8List bytes) {
      // Handle edited image
    },
  ),
)
```

## UI/UX Guidelines

### Edit Button on MediaPreview
- **Position**: Bottom-right corner, 8px padding
- **Size**: 28x28px
- **Style**: Semi-transparent dark background (black 50%)
- **Icon**: Icons.edit, white, 16px
- **Border radius**: 14px (circular)

### Edit Option in ImageViewerScreen
- **Location**: AppPopupMenu items list
- **Label**: "Chỉnh sửa" (Vietnamese)
- **Icon**: Icons.edit (optional, before text)

## Configuration Options
- Enable/disable editing via feature flag
- Configure available editing tools (crop, filters, text, etc.)
- Theme matching (dark/light mode support)

## Edge Cases
- Large images: Show loading indicator during edit
- Network failure: Handle gracefully with error message
- Edit cancel: Return to original view
- Memory management: Dispose bytes after use

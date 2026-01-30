# Layout Components

Responsive layout and panel management components for adaptive UI design.

## Components

### AppResponsiveLayout
Adaptive layout that renders different layouts based on screen size.

**Features:**
- Breakpoint-based layout switching (mobile < 600dp, tablet < 1200dp, desktop ≥ 1200dp)
- Builder pattern for each layout variant
- Smooth transitions between layouts
- Orientation handling
- Safe area management

**Usage:**
```dart
AppResponsiveLayout(
  mobile: (context) => MobileLayout(),
  tablet: (context) => TabletLayout(),
  desktop: (context) => DesktopLayout(),
  enableTransition: true,
)
```

### AppResponsiveBuilder
Builder widget that provides current layout type to child.

**Usage:**
```dart
AppResponsiveBuilder(
  builder: (context, layoutType) {
    if (layoutType.isMobile) {
      return MobileWidget();
    }
    return DesktopWidget();
  },
)
```

### AppResponsiveValue
Returns different values based on current layout type.

**Usage:**
```dart
final padding = AppResponsiveValue<double>(
  context: context,
  mobile: 8.0,
  tablet: 16.0,
  desktop: 24.0,
).value;
```

### AppSplitView
Master-detail layout with resizable divider.

**Features:**
- Desktop: side-by-side with draggable divider
- Mobile: separate screens with navigation
- Min/max width constraints
- Collapse/expand master panel
- Persist divider position

**Usage:**
```dart
AppSplitView(
  master: (context) => MasterPanel(),
  detail: (context) => DetailPanel(),
  initialMasterWidth: 300,
  minMasterWidth: 200,
  maxMasterWidth: 500,
)
```

### AppResizablePanel
Multiple panels with draggable dividers.

**Features:**
- Horizontal and vertical layouts
- Multiple panels support
- Drag handles between panels
- Min/max size constraints
- Proportional resizing

**Usage:**
```dart
AppResizablePanel(
  orientation: PanelOrientation.horizontal,
  panels: [
    PanelConfig(
      builder: (context) => Panel1(),
      initialSize: 200,
      minSize: 100,
    ),
    PanelConfig(
      builder: (context) => Panel2(),
      initialSize: 300,
      minSize: 150,
    ),
  ],
)
```

### AppStickyHeader
Header that sticks to the top when scrolling.

**Features:**
- Smooth transition to sticky state
- Elevation change when sticky
- Scroll offset detection
- Optional shrinking animation
- Custom header content

**Usage:**
```dart
AppStickyHeader(
  header: AppBar(title: Text('Header')),
  body: ListView(...),
  mode: StickyHeaderMode.onScroll,
  enableShrinking: true,
  maxHeaderHeight: 200,
  minHeaderHeight: 56,
)
```

## Enums

### LayoutType
- `mobile`: width < 600dp
- `tablet`: 600dp ≤ width < 1200dp
- `desktop`: width ≥ 1200dp

### SplitViewMode
- `sideBySide`: Desktop layout
- `separate`: Mobile layout
- `adaptive`: Tablet layout

### PanelOrientation
- `horizontal`: Panels side by side
- `vertical`: Panels stacked

### StickyHeaderMode
- `always`: Always sticky
- `onScroll`: Sticky on scroll
- `never`: Never sticky

## Best Practices

1. **Use AppResponsiveLayout for adaptive UIs**
   ```dart
   AppResponsiveLayout(
     mobile: (context) => MobileLayout(),
     desktop: (context) => DesktopLayout(),
   )
   ```

2. **Use AppResponsiveValue for responsive values**
   ```dart
   final padding = AppResponsiveValue<double>(
     context: context,
     mobile: 8.0,
     desktop: 24.0,
   ).value;
   ```

3. **Use AppSplitView for master-detail patterns**
   ```dart
   AppSplitView(
     master: (context) => ListPanel(),
     detail: (context) => DetailPanel(),
   )
   ```

4. **Use AppResizablePanel for complex layouts**
   ```dart
   AppResizablePanel(
     panels: [
       PanelConfig(builder: (context) => Sidebar()),
       PanelConfig(builder: (context) => Content()),
       PanelConfig(builder: (context) => Inspector()),
     ],
   )
   ```

5. **Use AppStickyHeader for scrollable content**
   ```dart
   AppStickyHeader(
     header: CustomHeader(),
     body: ScrollableContent(),
     mode: StickyHeaderMode.onScroll,
   )
   ```

## Architecture

All layout components:
- ✅ Extend BaseStatefulWidget or BaseStatelessWidget
- ✅ Use AppColors for theming
- ✅ Use AppConstants for dimensions/durations
- ✅ Support dark mode automatically
- ✅ Handle safe areas properly
- ✅ Provide smooth animations

## Testing

Components are tested for:
- Responsive behavior at different screen sizes
- Layout transitions
- Drag interactions
- Constraints enforcement
- Dark mode rendering
- Accessibility

---

**Status**: Production Ready | **Version**: 1.0.0 | **Last Updated**: 2025-01-30

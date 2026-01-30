/// **LAYOUT COMPONENTS**
///
/// Barrel export file for all layout and responsive components.
///
/// **Components**:
/// - AppResponsiveLayout: Breakpoint-based adaptive layout
/// - AppSplitView: Master-detail with resizable divider
/// - AppResizablePanel: Multiple panels with draggable dividers
/// - AppStickyHeader: Scroll-aware sticky header
///
/// **Usage**:
/// ```dart
/// import 'package:flutter_chat_app/presentation/widgets/design_system/layouts/layouts.dart';
///
/// // Responsive layout
/// AppResponsiveLayout(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
///
/// // Split view
/// AppSplitView(
///   master: (context) => MasterPanel(),
///   detail: (context) => DetailPanel(),
/// )
/// ```
library;

// Enums
export 'layout_enums.dart';

// Components
export 'app_resizable_panel.dart';
export 'app_responsive_layout.dart';
export 'app_split_view.dart';
export 'app_sticky_header.dart';

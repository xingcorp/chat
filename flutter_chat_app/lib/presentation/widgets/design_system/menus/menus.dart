/// **MENU & NAVIGATION COMPONENTS**
///
/// Barrel file exporting all advanced navigation and menu components.
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Barrel export for clean imports
///
/// **Components**:
/// - AppContextMenu: Context menu with smart positioning
/// - AppPopupMenu: Popup menu anchored to widgets
/// - AppBreadcrumb: Breadcrumb navigation with customizable separators
/// - AppTooltip: Enhanced tooltip with rich content support
/// - AppPopover: Interactive popover with dismissible backdrop
///
/// **Usage**:
/// ```dart
/// import 'package:flutter_chat_app/presentation/widgets/design_system/menus/menus.dart';
///
/// // All menu components available
/// AppContextMenu.show(...)
/// AppPopupMenu(...)
/// AppBreadcrumb(...)
/// AppTooltip(...)
/// AppPopover.show(...)
/// ```
library;

// Components
export 'app_breadcrumb.dart';
export 'app_context_menu.dart';
export 'app_popover.dart';
export 'app_popup_menu.dart';
export 'app_tooltip.dart';

// Enums
export 'menu_enums.dart';

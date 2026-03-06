import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/performance_service.dart';
import 'package:get_it/get_it.dart';

/// Widget bọc ứng dụng chính với các tính năng bổ sung
class AppWrapper extends StatelessWidget {
  /// Widget con chính của ứng dụng (thường là MaterialApp)
  final Widget child;

  /// Constructor
  const AppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool showPerformanceToggle =
        kDebugMode && GetIt.I.isRegistered<PerformanceService>();

    return Stack(
      children: [
        // Widget chính của ứng dụng
        child,

        // Các widget overlay debug (chỉ hiển thị trong chế độ debug)
        if (showPerformanceToggle) _buildPerformanceToggleButton(),
      ],
    );
  }

  /// Tạo nút toggle hiển thị performance overlay
  Widget _buildPerformanceToggleButton() {
    return Positioned(
      top: 50, // Vị trí cách đỉnh 50px
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Toggle performance overlay
            if (GetIt.I.isRegistered<PerformanceService>()) {
              final performanceService = GetIt.I<PerformanceService>();
              performanceService.togglePerformanceOverlay();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: const Icon(
              Icons.speed,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hàm tiện ích để bọc widget bất kỳ trong AppWrapper
Widget wrapApp(Widget child) {
  return AppWrapper(child: child);
}

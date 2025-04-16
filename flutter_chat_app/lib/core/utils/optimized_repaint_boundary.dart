import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';
import 'package:get_it/get_it.dart';

/// A wrapper around [RepaintBoundary] that conditionally applies the boundary
/// and tracks painting performance.
class OptimizedRepaintBoundary extends StatefulWidget {
  /// The child widget to be rendered with repaint boundary optimization
  final Widget child;
  
  /// Whether to apply the boundary (can be turned off for low-end devices)
  final bool applyBoundary;
  
  /// Tag for performance tracking
  final String? perfTag;
  
  /// Whether to track performance metrics
  final bool trackPerformance;
  
  /// Creates an optimized repaint boundary
  const OptimizedRepaintBoundary({
    Key? key,
    required this.child,
    this.applyBoundary = true,
    this.perfTag,
    this.trackPerformance = false,
  }) : super(key: key);

  @override
  State<OptimizedRepaintBoundary> createState() => _OptimizedRepaintBoundaryState();
}

class _OptimizedRepaintBoundaryState extends State<OptimizedRepaintBoundary> {
  late final PerformanceMonitor? _performanceMonitor;
  final GlobalKey _paintKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    // Get the performance monitor from the service locator if tracking is enabled
    if (widget.trackPerformance) {
      try {
        _performanceMonitor = GetIt.I<PerformanceMonitor>();
      } catch (e) {
        debugPrint('Failed to get PerformanceMonitor: $e');
        // Continue without performance monitoring
      }
    } else {
      _performanceMonitor = null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // For low-end devices, we might want to skip the repaint boundary
    if (!widget.applyBoundary) {
      return widget.child;
    }
    
    return RepaintBoundary(
      key: _paintKey,
      child: _PaintTimeTracker(
        child: widget.child,
        onPaint: widget.trackPerformance ? _trackPaintPerformance : null,
      ),
    );
  }
  
  void _trackPaintPerformance(Duration duration) {
    if (widget.trackPerformance && widget.perfTag != null && _performanceMonitor != null) {
      // Record the paint time as a custom metric
      _performanceMonitor!.recordCustomMetric(
        'paint_time_${widget.perfTag}',
        duration.inMicroseconds.toDouble(),
      );
      
      // If the paint time is too high, log a warning
      // 16ms is the threshold for 60fps rendering
      if (duration.inMilliseconds > 16) {
        debugPrint('⚠️ High paint time for ${widget.perfTag}: ${duration.inMilliseconds}ms');
        
        // Record as an event when we have a significant performance issue
        if (duration.inMilliseconds > 32) { // More than 2 frames worth of time
          _performanceMonitor!.recordEvent(
            'high_paint_time',
            parameters: {
              'tag': widget.perfTag!,
              'duration_ms': duration.inMilliseconds,
            },
          );
        }
      }
    }
  }
}

/// A widget that tracks paint time
class _PaintTimeTracker extends SingleChildRenderObjectWidget {
  /// Callback when paint completes, with the duration it took
  final void Function(Duration duration)? onPaint;
  
  const _PaintTimeTracker({
    required Widget child,
    this.onPaint,
  }) : super(child: child);
  
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _PaintTimeTrackerRenderObject(onPaint: onPaint);
  }
  
  @override
  void updateRenderObject(
      BuildContext context, _PaintTimeTrackerRenderObject renderObject) {
    renderObject.onPaint = onPaint;
  }
}

/// A render object that measures paint time
class _PaintTimeTrackerRenderObject extends RenderProxyBox {
  /// Callback for paint duration
  void Function(Duration duration)? onPaint;
  
  _PaintTimeTrackerRenderObject({this.onPaint});
  
  @override
  void paint(PaintingContext context, Offset offset) {
    if (onPaint != null) {
      final stopwatch = Stopwatch()..start();
      
      try {
        super.paint(context, offset);
      } finally {
        stopwatch.stop();
        onPaint!(stopwatch.elapsed);
      }
    } else {
      super.paint(context, offset);
    }
  }
  
  @override
  bool get isRepaintBoundary => true;
} 
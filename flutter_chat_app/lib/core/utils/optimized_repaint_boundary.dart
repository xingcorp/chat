import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chat_app/core/monitoring/performance_monitor.dart';

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
  late PerformanceMonitor? _performanceMonitor;
  final GlobalKey _paintKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    if (widget.trackPerformance) {
      _performanceMonitor = PerformanceMonitor();
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
    if (widget.trackPerformance && widget.perfTag != null) {
      _performanceMonitor?.recordCustomMetric(
        'paint_time_${widget.perfTag}',
        duration.inMicroseconds.toDouble(),
      );
      
      // If the paint time is too high, log it
      if (duration.inMilliseconds > 16) { // Aiming for 60fps (16.6ms per frame)
        _performanceMonitor?.logWarning(
          'High paint time for ${widget.perfTag}: ${duration.inMilliseconds}ms',
        );
      }
    }
  }
}

/// A widget that tracks paint time
class _PaintTimeTracker extends SingleChildRenderObjectWidget {
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

class _PaintTimeTrackerRenderObject extends RenderProxyBox {
  void Function(Duration duration)? onPaint;
  
  _PaintTimeTrackerRenderObject({this.onPaint});
  
  @override
  void paint(PaintingContext context, Offset offset) {
    if (onPaint != null) {
      final Stopwatch stopwatch = Stopwatch()..start();
      super.paint(context, offset);
      stopwatch.stop();
      onPaint!(stopwatch.elapsed);
    } else {
      super.paint(context, offset);
    }
  }
} 
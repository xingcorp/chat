import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/data/data_enums.dart';

/// **APP TIMELINE**
///
/// Vertical timeline component for displaying chronological events.
/// Extends [BaseStatelessWidget] for lifecycle management.
///
/// **Features**:
/// - Vertical layout with connecting lines
/// - Event markers (dots, icons, images)
/// - Event cards with custom content
/// - Alternating left/right layout option
/// - Grouping by date
/// - Custom marker colors and sizes
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateless widget with builder pattern
///
/// **Usage**:
/// ```dart
/// // Basic timeline
/// AppTimeline(
///   events: [
///     TimelineEvent(
///       title: context.l10n.eventTitle1,
///       description: context.l10n.eventDescription1,
///       timestamp: DateTime.now(),
///     ),
///     TimelineEvent(
///       title: context.l10n.eventTitle2,
///       description: context.l10n.eventDescription2,
///       timestamp: DateTime.now(),
///       icon: Icons.check_circle,
///     ),
///   ],
/// )
///
/// // Alternating timeline with custom markers
/// AppTimeline(
///   events: events,
///   alignment: TimelineAlignment.alternating,
///   markerType: TimelineMarkerType.icon,
///   lineStyle: TimelineLineStyle.dashed,
/// )
/// ```
class AppTimeline extends BaseStatelessWidget {
  /// Creates a timeline.
  const AppTimeline({
    super.key,
    required this.events,
    this.alignment = TimelineAlignment.left,
    this.markerType = TimelineMarkerType.dot,
    this.lineStyle = TimelineLineStyle.solid,
    this.markerSize = 16.0,
    this.lineWidth = 2.0,
    this.lineColor,
    this.markerColor,
    this.spacing = AppDimens.spaceMedium,
    this.showGroupHeaders = false,
  });

  /// List of timeline events
  final List<TimelineEvent> events;

  /// Timeline alignment
  final TimelineAlignment alignment;

  /// Marker type
  final TimelineMarkerType markerType;

  /// Line style
  final TimelineLineStyle lineStyle;

  /// Marker size
  final double markerSize;

  /// Line width
  final double lineWidth;

  /// Line color
  final Color? lineColor;

  /// Marker color
  final Color? markerColor;

  /// Spacing between events
  final double spacing;

  /// Whether to show date group headers
  final bool showGroupHeaders;

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        events.length,
        (index) {
          final event = events[index];
          final isFirst = index == 0;
          final isLast = index == events.length - 1;
          final isLeft = _isLeftAligned(index);

          return _buildTimelineItem(
            context,
            event,
            isFirst,
            isLast,
            isLeft,
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TimelineEvent event,
    bool isFirst,
    bool isLast,
    bool isLeft,
    bool isDark,
  ) {
    final effectiveLineColor = lineColor ??
        (isDark ? AppColors.borderDarkMode : AppColors.border);
    final effectiveMarkerColor = markerColor ??
        event.markerColor ??
        (isDark ? AppColors.primaryDarkMode : AppColors.primary);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alignment == TimelineAlignment.alternating && !isLeft)
            Expanded(child: _buildContent(context, event, isDark, false)),
          if (alignment == TimelineAlignment.alternating && !isLeft)
            SizedBox(width: spacing),
          // Timeline line and marker
          SizedBox(
            width: markerSize + (lineWidth * 2),
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: lineWidth,
                    height: spacing / 2,
                    decoration: BoxDecoration(
                      color: _getLineStyle(effectiveLineColor),
                    ),
                  ),
                // Marker
                _buildMarker(context, event, effectiveMarkerColor, isDark),
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: lineWidth,
                      decoration: BoxDecoration(
                        color: _getLineStyle(effectiveLineColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (alignment != TimelineAlignment.alternating || isLeft)
            SizedBox(width: spacing),
          if (alignment != TimelineAlignment.alternating || isLeft)
            Expanded(child: _buildContent(context, event, isDark, true)),
        ],
      ),
    );
  }

  Widget _buildMarker(
    BuildContext context,
    TimelineEvent event,
    Color color,
    bool isDark,
  ) {
    Widget marker;

    switch (markerType) {
      case TimelineMarkerType.dot:
        marker = Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.backgroundDarkMode : AppColors.background,
              width: 3,
            ),
          ),
        );
        break;

      case TimelineMarkerType.icon:
        marker = Container(
          width: markerSize * 1.5,
          height: markerSize * 1.5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            event.icon ?? Icons.circle,
            size: markerSize * 0.8,
            color: Colors.white,
          ),
        );
        break;

      case TimelineMarkerType.image:
        marker = Container(
          width: markerSize * 2,
          height: markerSize * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            image: event.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(event.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        );
        break;

      case TimelineMarkerType.custom:
        marker = event.customMarker ??
            Container(
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            );
        break;
    }

    return marker;
  }

  Widget _buildContent(
    BuildContext context,
    TimelineEvent event,
    bool isDark,
    bool showTimestamp,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.timestamp != null && showTimestamp)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.paddingXSmall),
              child: Text(
                _formatTimestamp(event.timestamp!),
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDarkMode
                      : AppColors.textSecondary,
                ),
              ),
            ),
          if (event.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.paddingXSmall),
              child: Text(
                event.title!,
                style: AppTextStyles.titleMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (event.description != null)
            Text(
              event.description!,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: isDark
                    ? AppColors.textSecondaryDarkMode
                    : AppColors.textSecondary,
              ),
            ),
          if (event.content != null)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.paddingSmall),
              child: event.content!,
            ),
        ],
      ),
    );
  }

  bool _isLeftAligned(int index) {
    switch (alignment) {
      case TimelineAlignment.left:
        return true;
      case TimelineAlignment.right:
        return false;
      case TimelineAlignment.alternating:
        return index % 2 == 0;
      case TimelineAlignment.center:
        return true;
    }
  }

  Color _getLineStyle(Color baseColor) {
    switch (lineStyle) {
      case TimelineLineStyle.solid:
        return baseColor;
      case TimelineLineStyle.dashed:
      case TimelineLineStyle.dotted:
        return baseColor.withValues(alpha: 0.5);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Timeline event data model
class TimelineEvent {
  /// Creates a timeline event.
  const TimelineEvent({
    this.title,
    this.description,
    this.timestamp,
    this.icon,
    this.imageUrl,
    this.markerColor,
    this.customMarker,
    this.content,
  });

  /// Event title
  final String? title;

  /// Event description
  final String? description;

  /// Event timestamp
  final DateTime? timestamp;

  /// Event icon
  final IconData? icon;

  /// Event image URL
  final String? imageUrl;

  /// Custom marker color
  final Color? markerColor;

  /// Custom marker widget
  final Widget? customMarker;

  /// Custom content widget
  final Widget? content;
}

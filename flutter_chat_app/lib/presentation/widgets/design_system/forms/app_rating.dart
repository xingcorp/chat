import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/form_enums.dart';

/// A customizable rating component with star or custom icons.
///
/// Features:
/// - Star rating (1-5 or custom max)
/// - Custom icons support
/// - Half-star support
/// - Read-only and interactive modes
/// - Size variants
/// - Custom colors
/// - Accessibility compliant
/// - Dark mode support
///
/// Example:
/// ```dart
/// // Basic star rating
/// AppRating(
///   rating: 4.5,
///   onRatingChanged: (rating) => _handleRatingChange(rating),
/// )
///
/// // Read-only rating
/// AppRating(
///   rating: 3.5,
///   isReadOnly: true,
/// )
///
/// // Custom icon and color
/// AppRating(
///   rating: 4.0,
///   icon: Icons.favorite,
///   color: Colors.red,
///   onRatingChanged: (rating) => _handleRatingChange(rating),
/// )
/// ```
class AppRating extends BaseStatefulWidget {
  /// Creates an [AppRating].
  const AppRating({
    required this.rating,
    this.onRatingChanged,
    this.maxRating = 5,
    this.size = RatingSize.medium,
    this.icon = Icons.star,
    this.color,
    this.unratedColor,
    this.allowHalfRating = true,
    this.isReadOnly = false,
    this.spacing,
    super.key,
  });

  /// Current rating value (0.0 to maxRating).
  final double rating;

  /// Callback when rating changes.
  final ValueChanged<double>? onRatingChanged;

  /// Maximum rating value.
  final int maxRating;

  /// Size of the rating icons.
  final RatingSize size;

  /// Icon to use for rating.
  final IconData icon;

  /// Color for rated icons.
  final Color? color;

  /// Color for unrated icons.
  final Color? unratedColor;

  /// Whether to allow half ratings (e.g., 3.5).
  final bool allowHalfRating;

  /// Whether rating is read-only (non-interactive).
  final bool isReadOnly;

  /// Spacing between icons.
  final double? spacing;

  @override
  AppRatingState createState() => AppRatingState();
}

/// State for [AppRating].
class AppRatingState extends BaseState<AppRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(AppRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rating != oldWidget.rating) {
      _currentRating = widget.rating;
    }
  }

  void _handleTap(int index) {
    if (widget.isReadOnly || widget.onRatingChanged == null) return;

    final newRating = (index + 1).toDouble();
    safeSetState(() {
      _currentRating = newRating;
    });
    widget.onRatingChanged?.call(newRating);
  }

  void _handleDragUpdate(DragUpdateDetails details, int index) {
    if (widget.isReadOnly || widget.onRatingChanged == null) return;
    if (!widget.allowHalfRating) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final iconSize = _getIconSize();
    final spacing = widget.spacing ?? AppDimens.spaceXSmall;
    final totalWidth = (iconSize * widget.maxRating) + (spacing * (widget.maxRating - 1));
    
    // Calculate rating based on position
    final position = localPosition.dx.clamp(0.0, totalWidth);
    var newRating = (position / (iconSize + spacing)).clamp(0.0, widget.maxRating.toDouble());
    
    // Round to nearest 0.5 if half rating is allowed
    if (widget.allowHalfRating) {
      newRating = (newRating * 2).round() / 2;
    } else {
      newRating = newRating.round().toDouble();
    }

    if (newRating != _currentRating) {
      safeSetState(() {
        _currentRating = newRating;
      });
      widget.onRatingChanged?.call(newRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratedColor = widget.color ?? theme.colorScheme.primary;
    final unratedColor = widget.unratedColor ?? theme.colorScheme.outline;
    final iconSize = _getIconSize();
    final spacing = widget.spacing ?? AppDimens.spaceXSmall;

    return Semantics(
      label: 'Rating: ${_currentRating.toStringAsFixed(1)} out of ${widget.maxRating}',
      value: _currentRating.toString(),
      enabled: !widget.isReadOnly,
      child: GestureDetector(
        onHorizontalDragUpdate: widget.isReadOnly
            ? null
            : (details) => _handleDragUpdate(details, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.maxRating,
            (index) => Padding(
              padding: EdgeInsets.only(
                right: index < widget.maxRating - 1 ? spacing : 0,
              ),
              child: GestureDetector(
                onTap: widget.isReadOnly ? null : () => _handleTap(index),
                child: _buildRatingIcon(
                  index: index,
                  iconSize: iconSize,
                  ratedColor: ratedColor,
                  unratedColor: unratedColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingIcon({
    required int index,
    required double iconSize,
    required Color ratedColor,
    required Color unratedColor,
  }) {
    final difference = _currentRating - index;

    if (difference >= 1) {
      // Full icon
      return Icon(
        widget.icon,
        size: iconSize,
        color: ratedColor,
      );
    } else if (difference > 0 && difference < 1 && widget.allowHalfRating) {
      // Half icon
      return Stack(
        children: [
          Icon(
            widget.icon,
            size: iconSize,
            color: unratedColor,
          ),
          ClipRect(
            clipper: _HalfClipper(percentage: difference),
            child: Icon(
              widget.icon,
              size: iconSize,
              color: ratedColor,
            ),
          ),
        ],
      );
    } else {
      // Empty icon
      return Icon(
        widget.icon,
        size: iconSize,
        color: unratedColor,
      );
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case RatingSize.small:
        return AppDimens.iconSmall;
      case RatingSize.medium:
        return AppDimens.iconMedium;
      case RatingSize.large:
        return AppDimens.iconLarge;
    }
  }
}

/// Custom clipper for half-filled icons.
class _HalfClipper extends CustomClipper<Rect> {
  const _HalfClipper({required this.percentage});

  final double percentage;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      0,
      0,
      size.width * percentage,
      size.height,
    );
  }

  @override
  bool shouldReclip(_HalfClipper oldClipper) {
    return oldClipper.percentage != percentage;
  }
}

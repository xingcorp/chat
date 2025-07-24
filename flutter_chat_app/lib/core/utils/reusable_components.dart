/// **REUSABLE COMPONENTS - MAXIMIZE CODE REUSABILITY**
///
/// Professional reusable components following enterprise standards:
/// - Generic types and parameterized functions
/// - Common patterns extracted into mixins and extensions
/// - Comprehensive documentation with usage examples
/// - Consistent API design across components
///
/// **Architecture:** Clean Architecture + Reusability Patterns

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_colors.dart';
import 'package:flutter_chat_app/core/constants/app_dimensions.dart';

/// **REUSABLE WIDGET MIXINS**

/// **Loading State Mixin**
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  Widget buildLoadingOverlay({
    required Widget child,
    String? loadingText,
    Color? overlayColor,
  }) {
    return Stack(
      children: [
        child,
        if (_isLoading)
          Container(
            color: overlayColor ?? AppColors.OVERLAY_LIGHT,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (loadingText != null) ...[
                    SizedBox(height: AppDimensions.SPACING_DEFAULT),
                    Text(
                      loadingText,
                      style: const TextStyle(color: AppColors.WHITE),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// **Error State Mixin**
mixin ErrorStateMixin<T extends StatefulWidget> on State<T> {
  String? _errorMessage;

  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void setError(String? error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  void clearError() => setError(null);

  Widget buildErrorWidget({
    VoidCallback? onRetry,
    String? retryText = 'Thử lại',
  }) {
    if (!hasError) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.PADDING_DEFAULT),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: AppDimensions.ICON_HUGE,
            color: AppColors.ERROR,
          ),
          SizedBox(height: AppDimensions.SPACING_DEFAULT),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.ERROR),
          ),
          if (onRetry != null) ...[
            SizedBox(height: AppDimensions.SPACING_DEFAULT),
            ElevatedButton(
              onPressed: () {
                clearError();
                onRetry();
              },
              child: Text(retryText!),
            ),
          ],
        ],
      ),
    );
  }
}

/// **REUSABLE UTILITY EXTENSIONS**

/// **String Extensions**
extension StringExtensions on String {
  /// **Check if string is empty or null**
  bool get isNullOrEmpty => isEmpty;

  /// **Capitalize first letter**
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// **Truncate string with ellipsis**
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// **Check if string is valid email**
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// **Check if string is valid phone number**
  bool get isValidPhone {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(this);
  }

  /// **Remove all whitespace**
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// **Convert to snake_case**
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }
}

/// **DateTime Extensions**
extension DateTimeExtensions on DateTime {
  /// **Check if date is today**
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// **Check if date is yesterday**
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }

  /// **Get relative time string**
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 7) {
      return '${day}/${month}/${year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// **Format as chat time**
  String get chatTimeFormat {
    if (isToday) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
      return 'Hôm qua';
    } else {
      return '${day}/${month}';
    }
  }
}

/// **List Extensions**
extension ListExtensions<T> on List<T> {
  /// **Get element at index safely**
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// **Check if list is null or empty**
  bool get isNullOrEmpty => isEmpty;

  /// **Get unique elements**
  List<T> get unique => toSet().toList();

  /// **Chunk list into smaller lists**
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size > length) ? length : i + size));
    }
    return chunks;
  }
}

/// **BuildContext Extensions**
extension BuildContextExtensions on BuildContext {
  /// **Get screen size**
  Size get screenSize => MediaQuery.of(this).size;

  /// **Get screen width**
  double get screenWidth => screenSize.width;

  /// **Get screen height**
  double get screenHeight => screenSize.height;

  /// **Check if device is mobile**
  bool get isMobile => screenWidth < AppDimensions.BREAKPOINT_MOBILE;

  /// **Check if device is tablet**
  bool get isTablet => screenWidth >= AppDimensions.BREAKPOINT_MOBILE && 
                       screenWidth < AppDimensions.BREAKPOINT_DESKTOP;

  /// **Check if device is desktop**
  bool get isDesktop => screenWidth >= AppDimensions.BREAKPOINT_DESKTOP;

  /// **Get theme**
  ThemeData get theme => Theme.of(this);

  /// **Get text theme**
  TextTheme get textTheme => theme.textTheme;

  /// **Get color scheme**
  ColorScheme get colorScheme => theme.colorScheme;

  /// **Show snackbar**
  void showSnackBar(String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  /// **Show error snackbar**
  void showErrorSnackBar(String message) {
    showSnackBar(
      message,
      duration: const Duration(seconds: 5),
    );
  }
}

/// **REUSABLE GENERIC COMPONENTS**

/// **Generic Result Class**
class Result<T, E> {
  final T? data;
  final E? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});

  /// **Create success result**
  factory Result.success(T data) => Result._(data: data, isSuccess: true);

  /// **Create error result**
  factory Result.error(E error) => Result._(error: error, isSuccess: false);

  /// **Check if result is success**
  bool get isError => !isSuccess;

  /// **Fold result**
  R fold<R>(R Function(E error) onError, R Function(T data) onSuccess) {
    return isSuccess ? onSuccess(data as T) : onError(error as E);
  }

  /// **Map data**
  Result<R, E> map<R>(R Function(T data) mapper) {
    return isSuccess 
        ? Result.success(mapper(data as T))
        : Result.error(error as E);
  }

  /// **Map error**
  Result<T, R> mapError<R>(R Function(E error) mapper) {
    return isSuccess 
        ? Result.success(data as T)
        : Result.error(mapper(error as E));
  }
}

/// **Generic Cache Class**
class Cache<K, V> {
  final Map<K, _CacheEntry<V>> _cache = {};
  final Duration _defaultTtl;
  final int _maxSize;

  Cache({
    Duration defaultTtl = const Duration(hours: 1),
    int maxSize = 100,
  }) : _defaultTtl = defaultTtl, _maxSize = maxSize;

  /// **Put value in cache**
  void put(K key, V value, {Duration? ttl}) {
    if (_cache.length >= _maxSize) {
      _evictOldest();
    }

    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? _defaultTtl),
    );
  }

  /// **Get value from cache**
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// **Check if key exists**
  bool containsKey(K key) => get(key) != null;

  /// **Remove key**
  void remove(K key) => _cache.remove(key);

  /// **Clear cache**
  void clear() => _cache.clear();

  /// **Get cache size**
  int get size => _cache.length;

  /// **Evict oldest entry**
  void _evictOldest() {
    if (_cache.isEmpty) return;
    final oldestKey = _cache.keys.first;
    _cache.remove(oldestKey);
  }
}

/// **Cache Entry**
class _CacheEntry<V> {
  final V value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// **Usage Examples:**
/// 
/// ```dart
/// // ✅ CORRECT - Using reusable components
/// class MyWidget extends StatefulWidget {
///   @override
///   _MyWidgetState createState() => _MyWidgetState();
/// }
/// 
/// class _MyWidgetState extends State<MyWidget> 
///     with LoadingStateMixin, ErrorStateMixin {
///   
///   @override
///   Widget build(BuildContext context) {
///     return buildLoadingOverlay(
///       child: hasError 
///           ? buildErrorWidget(onRetry: _retry)
///           : _buildContent(),
///     );
///   }
/// 
///   void _retry() {
///     // Retry logic
///   }
/// 
///   Widget _buildContent() {
///     return Container(
///       padding: EdgeInsets.all(AppDimensions.PADDING_DEFAULT),
///       child: Text(
///         'Hello World'.capitalize,
///         style: context.textTheme.bodyLarge,
///       ),
///     );
///   }
/// }
/// ```

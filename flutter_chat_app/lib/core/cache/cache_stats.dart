import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý thống kê và phân tích hiệu quả của cache
class CacheStats {
  /// Singleton instance
  static final CacheStats _instance = CacheStats._internal();
  
  /// Factory constructor
  factory CacheStats() => _instance;
  
  /// Logger
  final _logger = Logger();
  
  /// Thống kê hit/miss cho cache API
  int _apiHits = 0;
  int _apiMisses = 0;
  
  /// Thống kê hit/miss cho cache media
  int _mediaHits = 0;
  int _mediaMisses = 0;
  
  /// Map theo dõi thời gian tải
  final Map<String, double> _loadTimes = {};
  
  /// Queue lưu lịch sử truy cập cache gần đây
  final ListQueue<CacheAccess> _recentAccesses = ListQueue<CacheAccess>(100);
  
  /// SharedPreferences instance
  SharedPreferences? _prefs;
  
  /// Private constructor
  CacheStats._internal();
  
  /// Khởi tạo
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadStats();
    _logger.i('CacheStats đã được khởi tạo');
  }
  
  /// Ghi nhận API cache hit
  void recordApiHit(String key, double loadTimeMs) {
    _apiHits++;
    _saveStats();
    _recordAccess(key, true, loadTimeMs, isApi: true);
    _loadTimes[key] = loadTimeMs;
  }
  
  /// Ghi nhận API cache miss
  void recordApiMiss(String key, double loadTimeMs) {
    _apiMisses++;
    _saveStats();
    _recordAccess(key, false, loadTimeMs, isApi: true);
  }
  
  /// Ghi nhận media cache hit
  void recordMediaHit(String url, double loadTimeMs) {
    _mediaHits++;
    _saveStats();
    _recordAccess(url, true, loadTimeMs, isApi: false);
    _loadTimes[url] = loadTimeMs;
  }
  
  /// Ghi nhận media cache miss
  void recordMediaMiss(String url, double loadTimeMs) {
    _mediaMisses++;
    _saveStats();
    _recordAccess(url, false, loadTimeMs, isApi: false);
  }
  
  /// Ghi nhận truy cập vào cache
  void _recordAccess(String key, bool isHit, double loadTimeMs, {required bool isApi}) {
    final access = CacheAccess(
      key: key,
      timestamp: DateTime.now(),
      isHit: isHit,
      loadTimeMs: loadTimeMs,
      isApi: isApi,
    );
    
    // Thêm vào Queue, nếu đầy thì loại bỏ access cũ nhất
    if (_recentAccesses.length >= 100) {
      _recentAccesses.removeFirst();
    }
    _recentAccesses.add(access);
  }
  
  /// Tính hit rate cho API cache
  double getApiHitRate() {
    final total = _apiHits + _apiMisses;
    if (total == 0) return 0;
    return _apiHits / total;
  }
  
  /// Tính hit rate cho media cache
  double getMediaHitRate() {
    final total = _mediaHits + _mediaMisses;
    if (total == 0) return 0;
    return _mediaHits / total;
  }
  
  /// Tính hit rate tổng thể
  double getOverallHitRate() {
    final totalHits = _apiHits + _mediaHits;
    final totalRequests = totalHits + _apiMisses + _mediaMisses;
    if (totalRequests == 0) return 0;
    return totalHits / totalRequests;
  }
  
  /// Lấy thời gian tải trung bình (ms)
  double getAverageLoadTime({bool onlyHits = false}) {
    final accesses = onlyHits 
        ? _recentAccesses.where((a) => a.isHit)
        : _recentAccesses;
    
    if (accesses.isEmpty) return 0;
    
    final totalTime = accesses.fold<double>(
      0, (sum, access) => sum + access.loadTimeMs);
    return totalTime / accesses.length;
  }
  
  /// Lấy keys được truy cập nhiều nhất
  List<String> getMostAccessedKeys({int limit = 10}) {
    final accessMap = <String, int>{};
    
    for (final access in _recentAccesses) {
      accessMap[access.key] = (accessMap[access.key] ?? 0) + 1;
    }
    
    final sortedEntries = accessMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(limit)
        .map((e) => e.key)
        .toList();
  }
  
  /// Lấy thống kê tóm tắt
  Map<String, dynamic> getSummaryStats() {
    return {
      'apiHitRate': getApiHitRate(),
      'mediaHitRate': getMediaHitRate(),
      'overallHitRate': getOverallHitRate(),
      'averageLoadTime': getAverageLoadTime(),
      'averageCachedLoadTime': getAverageLoadTime(onlyHits: true),
      'apiHits': _apiHits,
      'apiMisses': _apiMisses,
      'mediaHits': _mediaHits,
      'mediaMisses': _mediaMisses,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
  
  /// Reset thống kê
  void resetStats() {
    _apiHits = 0;
    _apiMisses = 0;
    _mediaHits = 0;
    _mediaMisses = 0;
    _loadTimes.clear();
    _recentAccesses.clear();
    _saveStats();
    _logger.i('Đã reset thống kê cache');
  }
  
  /// Lưu thống kê vào persistent storage
  void _saveStats() {
    if (_prefs == null) return;
    
    _prefs!.setInt('cache_stats_api_hits', _apiHits);
    _prefs!.setInt('cache_stats_api_misses', _apiMisses);
    _prefs!.setInt('cache_stats_media_hits', _mediaHits);
    _prefs!.setInt('cache_stats_media_misses', _mediaMisses);
  }
  
  /// Tải thống kê từ persistent storage
  void _loadStats() {
    if (_prefs == null) return;
    
    _apiHits = _prefs!.getInt('cache_stats_api_hits') ?? 0;
    _apiMisses = _prefs!.getInt('cache_stats_api_misses') ?? 0;
    _mediaHits = _prefs!.getInt('cache_stats_media_hits') ?? 0;
    _mediaMisses = _prefs!.getInt('cache_stats_media_misses') ?? 0;
  }
  
  /// Lấy dữ liệu thống kê để hiển thị trên UI
  String getStatsReport() {
    final stats = getSummaryStats();
    final apiHitRate = (stats['apiHitRate'] as double) * 100;
    final mediaHitRate = (stats['mediaHitRate'] as double) * 100;
    final overallHitRate = (stats['overallHitRate'] as double) * 100;
    final averageLoadTime = stats['averageLoadTime'] as double;
    final averageCachedLoadTime = stats['averageCachedLoadTime'] as double;
    final apiHits = stats['apiHits'] as int;
    final apiMisses = stats['apiMisses'] as int;
    final mediaHits = stats['mediaHits'] as int;
    final mediaMisses = stats['mediaMisses'] as int;

    return '''
    === Báo cáo hiệu quả Cache ===
    Tỷ lệ trúng API: ${apiHitRate.toStringAsFixed(1)}%
    Tỷ lệ trúng Media: ${mediaHitRate.toStringAsFixed(1)}%
    Tỷ lệ trúng tổng thể: ${overallHitRate.toStringAsFixed(1)}%

    Thời gian tải trung bình: ${averageLoadTime.toStringAsFixed(2)}ms
    Thời gian tải với cache: ${averageCachedLoadTime.toStringAsFixed(2)}ms

    Tổng API requests: ${apiHits + apiMisses}
    Tổng Media requests: ${mediaHits + mediaMisses}
    ''';
  }
}

/// Class lưu thông tin truy cập cache
class CacheAccess {
  /// Key hoặc URL
  final String key;
  
  /// Thời điểm truy cập
  final DateTime timestamp;
  
  /// Cache hit hay miss
  final bool isHit;
  
  /// Thời gian tải (ms)
  final double loadTimeMs;
  
  /// API hay Media cache
  final bool isApi;
  
  /// Constructor
  CacheAccess({
    required this.key,
    required this.timestamp,
    required this.isHit,
    required this.loadTimeMs,
    required this.isApi,
  });
} 
import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/data/graphql/chat_operations.dart';

/// Service quản lý frequently used reactions của user.
///
/// Fetch top emoji từ backend `chatReactionFrequentlyUsed`, cache in-memory
/// với TTL 5 phút, và expose qua stream cho UI.
///
/// **Features:**
/// - In-memory cache với TTL 5 phút
/// - Debounced refetch 10s sau khi user react
/// - Fallback về default reactions khi API fail hoặc trả về rỗng
/// - Sync access qua [currentReactions] getter cho modal UI
@lazySingleton
class FrequentReactionService {
  final GraphQLClientWrapper _graphqlClient;
  final AppLogger _logger;

  static const List<String> _defaultReactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const Duration _refetchDebounce = Duration(seconds: 10);

  List<String> _cachedReactions = _defaultReactions;
  DateTime? _lastFetchTime;
  Timer? _refetchTimer;
  bool _isFetching = false;

  final _reactionsSubject = BehaviorSubject<List<String>>.seeded(_defaultReactions);

  FrequentReactionService(this._graphqlClient, this._logger);

  /// Stream cho UI rebuild khi reactions thay đổi.
  Stream<List<String>> get reactionsStream => _reactionsSubject.stream;

  /// Sync access cho modal/context menu — luôn trả về data hiện tại.
  List<String> get currentReactions => _cachedReactions;

  /// Fetch reactions từ backend.
  ///
  /// Bỏ qua nếu cache còn hợp lệ (TTL chưa hết) hoặc đang fetch.
  Future<void> fetch({bool forceRefresh = false}) async {
    if (_isFetching) return;
    if (!forceRefresh && _isCacheValid()) return;

    _isFetching = true;
    try {
      final data = await _graphqlClient.mutate(
        ChatMutations.getFrequentlyUsedReactions,
      );

      final rawList = data['chatReactionFrequentlyUsed'];
      final reactions = (rawList is List && rawList.isNotEmpty)
          ? rawList.cast<String>()
          : _defaultReactions;

      _cachedReactions = reactions;
      _lastFetchTime = DateTime.now();
      _reactionsSubject.add(_cachedReactions);

      _logger.d('FrequentReactionService: fetched ${reactions.length} reactions');
    } catch (e) {
      _logger.w('FrequentReactionService: fetch failed, using cache/defaults — $e');
      // Giữ cached data (hoặc defaults nếu chưa có cache)
    } finally {
      _isFetching = false;
    }
  }

  /// Invalidate cache và schedule refetch sau debounce delay.
  ///
  /// Gọi sau khi user react thành công để đảm bảo reactions list cập nhật
  /// mà không spam API (debounced 10s).
  void invalidateAfterReaction() {
    _refetchTimer?.cancel();
    _refetchTimer = Timer(_refetchDebounce, () => fetch(forceRefresh: true));
  }

  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheTtl;
  }

  void dispose() {
    _refetchTimer?.cancel();
    _reactionsSubject.close();
  }
}

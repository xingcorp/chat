import 'package:flutter_chat_app/core/exceptions/exceptions.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/chat_model.dart';
import 'package:flutter_chat_app/domain/entities/chat.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_repository.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';

/// Thời gian cache hợp lệ (30 phút)
const Duration _cacheTtl = Duration(minutes: 30);

/// Implementation of [IChatRepository]
@LazySingleton(as: IChatRepository)
class ChatRepositoryImpl implements IChatRepository {
  final NetworkInfo _networkInfo;
  final ChatLocalDataSource _localDataSource;
  final ChatRemoteDataSource _remoteDataSource;
  final GraphQLClientWrapper _graphQLClient;

  /// Lưu trữ thời gian cập nhật cho mỗi chat
  final Map<String, DateTime> _lastChatRefreshTime = {};
  
  /// Lưu trữ thời gian cập nhật cho toàn bộ danh sách chat
  DateTime? _lastChatsListRefreshTime;

  /// Constructor
  ChatRepositoryImpl(
    this._networkInfo,
    this._localDataSource,
    this._remoteDataSource,
    this._graphQLClient,
  );

  @override
  GraphQLClient get client => _graphQLClient.client;

  /// Kiểm tra xem cache có còn hiệu lực không
  bool _isCacheValid(String? chatId) {
    final now = DateTime.now();
    
    // Nếu có chat ID cụ thể, kiểm tra cache cho chat đó
    if (chatId != null) {
      final lastRefresh = _lastChatRefreshTime[chatId];
      if (lastRefresh == null) return false;
      
      return now.difference(lastRefresh) < _cacheTtl;
    }
    
    // Nếu không có chat ID, kiểm tra cache cho toàn bộ danh sách
    if (_lastChatsListRefreshTime == null) return false;
    return now.difference(_lastChatsListRefreshTime!) < _cacheTtl;
  }
  
  /// Cập nhật thời gian refresh cho cache
  void _updateCacheTimestamp(String? chatId) {
    final now = DateTime.now();
    
    if (chatId != null) {
      _lastChatRefreshTime[chatId] = now;
    } else {
      _lastChatsListRefreshTime = now;
    }
  }

  @override
  Future<List<Chat>> getChats() async {
    // Kiểm tra có kết nối không
    final isConnected = await _networkInfo.isConnected;
    
    // Kiểm tra cache còn hiệu lực không
    final isCacheValid = _isCacheValid(null);
    
    // Nếu có kết nối và cache không còn hiệu lực, lấy dữ liệu từ server
    if (isConnected && !isCacheValid) {
      try {
        final remoteChatModels = await _remoteDataSource.getUserChats();
        
        // Lưu chats vào local storage và cập nhật thời gian cache
        await Future.wait(
          remoteChatModels.map((model) => _localDataSource.saveChat(model))
        );
        
        _updateCacheTimestamp(null);
        
        // Chuyển đổi sang domain entities
        return remoteChatModels.map((model) => model.toDomain()).toList();
      } on Exception catch (e) {
        // Log lỗi trước khi dùng dữ liệu local
        print('Lỗi khi tải dữ liệu từ server: $e');
        return getChatsFromLocalStorage();
      }
    } else {
      // Nếu không có kết nối hoặc cache còn hiệu lực, dùng dữ liệu local
      return getChatsFromLocalStorage();
    }
  }

  @override
  Future<Chat?> getChatById(String chatId) async {
    // Kiểm tra có kết nối không
    final isConnected = await _networkInfo.isConnected;
    
    // Kiểm tra cache còn hiệu lực không
    final isCacheValid = _isCacheValid(chatId);
    
    // Nếu có kết nối và cache không còn hiệu lực, lấy dữ liệu từ server
    if (isConnected && !isCacheValid) {
      try {
        final remoteChatModel = await _remoteDataSource.getChatDetails(chatId);
        
        // Lưu vào local storage và cập nhật thời gian cache
        await _localDataSource.saveChat(remoteChatModel);
        _updateCacheTimestamp(chatId);
        
        return remoteChatModel.toDomain();
      } on Exception catch (e) {
        // Log lỗi trước khi dùng dữ liệu local
        print('Lỗi khi tải chi tiết chat từ server: $e');
        final localChatModel = await _localDataSource.getChatById(chatId);
        return localChatModel?.toDomain();
      }
    } else {
      // Nếu không có kết nối hoặc cache còn hiệu lực, dùng dữ liệu local
      final localChatModel = await _localDataSource.getChatById(chatId);
      return localChatModel?.toDomain();
    }
  }

  @override
  Future<List<Chat>> getChatsFromLocalStorage() async {
    final localChatModels = await _localDataSource.getAllChats();
    return localChatModels.map((model) => model.toDomain()).toList();
  }

  @override
  Future<void> saveChatLocally(Chat chat) async {
    final chatModel = ChatModel.fromDomain(chat);
    await _localDataSource.saveChat(chatModel);
    
    // Cập nhật timestamp để biết cache này mới
    _updateCacheTimestamp(chat.id);
  }

  @override
  Future<Chat> createChat({
    required String name,
    required List<String> participantIds,
    bool isGroup = false,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final ChatModel result;
      
      if (isGroup) {
        result = await _remoteDataSource.createGroupChat(name, participantIds);
      } else {
        if (participantIds.length != 1) {
          throw const InvalidArgumentException(
            'Direct chats must have exactly one participant'
          );
        }
        result = await _remoteDataSource.createDirectChat(participantIds.first);
      }
      
      // Lưu vào local storage và cập nhật cache
      await _localDataSource.saveChat(result);
      _updateCacheTimestamp(result.id);
      
      // Phải vô hiệu hóa cache danh sách chat vì đã có chat mới
      _lastChatsListRefreshTime = null;
      
      return result.toDomain();
    } catch (e) {
      throw ServerException(message: 'Failed to create chat: $e');
    }
  }

  @override
  Future<Chat> updateChat({
    required String chatId,
    String? name,
    String? avatarUrl,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final result = await _remoteDataSource.updateChat(
        chatId,
        name: name,
        avatarUrl: avatarUrl,
      );
      
      // Lưu vào local storage và cập nhật cache
      await _localDataSource.saveChat(result);
      _updateCacheTimestamp(chatId);
      
      // Vô hiệu hóa cache danh sách chat
      _lastChatsListRefreshTime = null;
      
      return result.toDomain();
    } catch (e) {
      throw ServerException(message: 'Failed to update chat: $e');
    }
  }

  @override
  Future<bool> addParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    if (!(await _networkInfo.isConnected)) {
      throw NoInternetException();
    }

    try {
      final result = await _remoteDataSource.addUsersToChat(chatId, userIds);
      
      // Cập nhật local cache
      if (result) {
        await syncChat(chatId);
      }
      
      return result;
    } catch (e) {
      throw ServerException(message: 'Failed to add participants: $e');
    }
  }

  /// Vô hiệu hóa cache cho một chat cụ thể
  void invalidateCache(String chatId) {
    _lastChatRefreshTime.remove(chatId);
  }
  
  /// Vô hiệu hóa toàn bộ cache
  void invalidateAllCache() {
    _lastChatRefreshTime.clear();
    _lastChatsListRefreshTime = null;
  }
  
  /// Đồng bộ chat và vô hiệu hóa cache 
  @override
  Future<void> syncChat(String chatId) async {
    // Vô hiệu hóa cache
    invalidateCache(chatId);
    
    if (await _networkInfo.isConnected) {
      try {
        // Lấy dữ liệu mới từ server
        final remoteChatModel = await _remoteDataSource.getChatDetails(chatId);
        
        // Lưu vào local storage
        await _localDataSource.saveChat(remoteChatModel);
        
        // Cập nhật thời gian cache
        _updateCacheTimestamp(chatId);
      } catch (e) {
        // Nếu có lỗi, ghi log nhưng không throw exception
        print('Không thể đồng bộ chat $chatId: $e');
      }
    }
  }
} 
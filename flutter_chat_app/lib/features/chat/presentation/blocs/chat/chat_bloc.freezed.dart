// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatEventCopyWith<$Res> {
  factory $ChatEventCopyWith(ChatEvent value, $Res Function(ChatEvent) then) =
      _$ChatEventCopyWithImpl<$Res, ChatEvent>;
}

/// @nodoc
class _$ChatEventCopyWithImpl<$Res, $Val extends ChatEvent>
    implements $ChatEventCopyWith<$Res> {
  _$ChatEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$LoadChatsImplCopyWith<$Res> {
  factory _$$LoadChatsImplCopyWith(
          _$LoadChatsImpl value, $Res Function(_$LoadChatsImpl) then) =
      __$$LoadChatsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool forceRefresh});
}

/// @nodoc
class __$$LoadChatsImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$LoadChatsImpl>
    implements _$$LoadChatsImplCopyWith<$Res> {
  __$$LoadChatsImplCopyWithImpl(
      _$LoadChatsImpl _value, $Res Function(_$LoadChatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? forceRefresh = null,
  }) {
    return _then(_$LoadChatsImpl(
      forceRefresh: null == forceRefresh
          ? _value.forceRefresh
          : forceRefresh // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$LoadChatsImpl implements _LoadChats {
  const _$LoadChatsImpl({this.forceRefresh = false});

  @override
  @JsonKey()
  final bool forceRefresh;

  @override
  String toString() {
    return 'ChatEvent.loadChats(forceRefresh: $forceRefresh)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadChatsImpl &&
            (identical(other.forceRefresh, forceRefresh) ||
                other.forceRefresh == forceRefresh));
  }

  @override
  int get hashCode => Object.hash(runtimeType, forceRefresh);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadChatsImplCopyWith<_$LoadChatsImpl> get copyWith =>
      __$$LoadChatsImplCopyWithImpl<_$LoadChatsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return loadChats(forceRefresh);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return loadChats?.call(forceRefresh);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (loadChats != null) {
      return loadChats(forceRefresh);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return loadChats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return loadChats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (loadChats != null) {
      return loadChats(this);
    }
    return orElse();
  }
}

abstract class _LoadChats implements ChatEvent {
  const factory _LoadChats({final bool forceRefresh}) = _$LoadChatsImpl;

  bool get forceRefresh;
  @JsonKey(ignore: true)
  _$$LoadChatsImplCopyWith<_$LoadChatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadMoreChatsImplCopyWith<$Res> {
  factory _$$LoadMoreChatsImplCopyWith(
          _$LoadMoreChatsImpl value, $Res Function(_$LoadMoreChatsImpl) then) =
      __$$LoadMoreChatsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadMoreChatsImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$LoadMoreChatsImpl>
    implements _$$LoadMoreChatsImplCopyWith<$Res> {
  __$$LoadMoreChatsImplCopyWithImpl(
      _$LoadMoreChatsImpl _value, $Res Function(_$LoadMoreChatsImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoadMoreChatsImpl implements _LoadMoreChats {
  const _$LoadMoreChatsImpl();

  @override
  String toString() {
    return 'ChatEvent.loadMoreChats()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadMoreChatsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return loadMoreChats();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return loadMoreChats?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (loadMoreChats != null) {
      return loadMoreChats();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return loadMoreChats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return loadMoreChats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (loadMoreChats != null) {
      return loadMoreChats(this);
    }
    return orElse();
  }
}

abstract class _LoadMoreChats implements ChatEvent {
  const factory _LoadMoreChats() = _$LoadMoreChatsImpl;
}

/// @nodoc
abstract class _$$LoadChatDetailsImplCopyWith<$Res> {
  factory _$$LoadChatDetailsImplCopyWith(_$LoadChatDetailsImpl value,
          $Res Function(_$LoadChatDetailsImpl) then) =
      __$$LoadChatDetailsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId});
}

/// @nodoc
class __$$LoadChatDetailsImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$LoadChatDetailsImpl>
    implements _$$LoadChatDetailsImplCopyWith<$Res> {
  __$$LoadChatDetailsImplCopyWithImpl(
      _$LoadChatDetailsImpl _value, $Res Function(_$LoadChatDetailsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
  }) {
    return _then(_$LoadChatDetailsImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$LoadChatDetailsImpl implements _LoadChatDetails {
  const _$LoadChatDetailsImpl({required this.chatId});

  @override
  final String chatId;

  @override
  String toString() {
    return 'ChatEvent.loadChatDetails(chatId: $chatId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadChatDetailsImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadChatDetailsImplCopyWith<_$LoadChatDetailsImpl> get copyWith =>
      __$$LoadChatDetailsImplCopyWithImpl<_$LoadChatDetailsImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return loadChatDetails(chatId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return loadChatDetails?.call(chatId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (loadChatDetails != null) {
      return loadChatDetails(chatId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return loadChatDetails(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return loadChatDetails?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (loadChatDetails != null) {
      return loadChatDetails(this);
    }
    return orElse();
  }
}

abstract class _LoadChatDetails implements ChatEvent {
  const factory _LoadChatDetails({required final String chatId}) =
      _$LoadChatDetailsImpl;

  String get chatId;
  @JsonKey(ignore: true)
  _$$LoadChatDetailsImplCopyWith<_$LoadChatDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadMessagesImplCopyWith<$Res> {
  factory _$$LoadMessagesImplCopyWith(
          _$LoadMessagesImpl value, $Res Function(_$LoadMessagesImpl) then) =
      __$$LoadMessagesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, int limit, int offset});
}

/// @nodoc
class __$$LoadMessagesImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$LoadMessagesImpl>
    implements _$$LoadMessagesImplCopyWith<$Res> {
  __$$LoadMessagesImplCopyWithImpl(
      _$LoadMessagesImpl _value, $Res Function(_$LoadMessagesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? limit = null,
    Object? offset = null,
  }) {
    return _then(_$LoadMessagesImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$LoadMessagesImpl implements _LoadMessages {
  const _$LoadMessagesImpl(
      {required this.chatId, this.limit = 20, this.offset = 0});

  @override
  final String chatId;
  @override
  @JsonKey()
  final int limit;
  @override
  @JsonKey()
  final int offset;

  @override
  String toString() {
    return 'ChatEvent.loadMessages(chatId: $chatId, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadMessagesImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId, limit, offset);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadMessagesImplCopyWith<_$LoadMessagesImpl> get copyWith =>
      __$$LoadMessagesImplCopyWithImpl<_$LoadMessagesImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return loadMessages(chatId, limit, offset);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return loadMessages?.call(chatId, limit, offset);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (loadMessages != null) {
      return loadMessages(chatId, limit, offset);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return loadMessages(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return loadMessages?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (loadMessages != null) {
      return loadMessages(this);
    }
    return orElse();
  }
}

abstract class _LoadMessages implements ChatEvent {
  const factory _LoadMessages(
      {required final String chatId,
      final int limit,
      final int offset}) = _$LoadMessagesImpl;

  String get chatId;
  int get limit;
  int get offset;
  @JsonKey(ignore: true)
  _$$LoadMessagesImplCopyWith<_$LoadMessagesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SendMessageImplCopyWith<$Res> {
  factory _$$SendMessageImplCopyWith(
          _$SendMessageImpl value, $Res Function(_$SendMessageImpl) then) =
      __$$SendMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String chatId,
      String content,
      ContentType contentType,
      List<String> attachmentIds});
}

/// @nodoc
class __$$SendMessageImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$SendMessageImpl>
    implements _$$SendMessageImplCopyWith<$Res> {
  __$$SendMessageImplCopyWithImpl(
      _$SendMessageImpl _value, $Res Function(_$SendMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? content = null,
    Object? contentType = null,
    Object? attachmentIds = null,
  }) {
    return _then(_$SendMessageImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      contentType: null == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as ContentType,
      attachmentIds: null == attachmentIds
          ? _value._attachmentIds
          : attachmentIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$SendMessageImpl implements _SendMessage {
  const _$SendMessageImpl(
      {required this.chatId,
      required this.content,
      required this.contentType,
      final List<String> attachmentIds = const []})
      : _attachmentIds = attachmentIds;

  @override
  final String chatId;
  @override
  final String content;
  @override
  final ContentType contentType;
  final List<String> _attachmentIds;
  @override
  @JsonKey()
  List<String> get attachmentIds {
    if (_attachmentIds is EqualUnmodifiableListView) return _attachmentIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachmentIds);
  }

  @override
  String toString() {
    return 'ChatEvent.sendMessage(chatId: $chatId, content: $content, contentType: $contentType, attachmentIds: $attachmentIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendMessageImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            const DeepCollectionEquality()
                .equals(other._attachmentIds, _attachmentIds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId, content, contentType,
      const DeepCollectionEquality().hash(_attachmentIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SendMessageImplCopyWith<_$SendMessageImpl> get copyWith =>
      __$$SendMessageImplCopyWithImpl<_$SendMessageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return sendMessage(chatId, content, contentType, attachmentIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return sendMessage?.call(chatId, content, contentType, attachmentIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (sendMessage != null) {
      return sendMessage(chatId, content, contentType, attachmentIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return sendMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return sendMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (sendMessage != null) {
      return sendMessage(this);
    }
    return orElse();
  }
}

abstract class _SendMessage implements ChatEvent {
  const factory _SendMessage(
      {required final String chatId,
      required final String content,
      required final ContentType contentType,
      final List<String> attachmentIds}) = _$SendMessageImpl;

  String get chatId;
  String get content;
  ContentType get contentType;
  List<String> get attachmentIds;
  @JsonKey(ignore: true)
  _$$SendMessageImplCopyWith<_$SendMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CreateChatImplCopyWith<$Res> {
  factory _$$CreateChatImplCopyWith(
          _$CreateChatImpl value, $Res Function(_$CreateChatImpl) then) =
      __$$CreateChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {ChatType type,
      String? name,
      String? description,
      List<String> participantIds});
}

/// @nodoc
class __$$CreateChatImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$CreateChatImpl>
    implements _$$CreateChatImplCopyWith<$Res> {
  __$$CreateChatImplCopyWithImpl(
      _$CreateChatImpl _value, $Res Function(_$CreateChatImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? name = freezed,
    Object? description = freezed,
    Object? participantIds = null,
  }) {
    return _then(_$CreateChatImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ChatType,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      participantIds: null == participantIds
          ? _value._participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$CreateChatImpl implements _CreateChat {
  const _$CreateChatImpl(
      {required this.type,
      this.name,
      this.description,
      required final List<String> participantIds})
      : _participantIds = participantIds;

  @override
  final ChatType type;
  @override
  final String? name;
  @override
  final String? description;
  final List<String> _participantIds;
  @override
  List<String> get participantIds {
    if (_participantIds is EqualUnmodifiableListView) return _participantIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantIds);
  }

  @override
  String toString() {
    return 'ChatEvent.createChat(type: $type, name: $name, description: $description, participantIds: $participantIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateChatImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._participantIds, _participantIds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, type, name, description,
      const DeepCollectionEquality().hash(_participantIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateChatImplCopyWith<_$CreateChatImpl> get copyWith =>
      __$$CreateChatImplCopyWithImpl<_$CreateChatImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return createChat(type, name, description, participantIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return createChat?.call(type, name, description, participantIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (createChat != null) {
      return createChat(type, name, description, participantIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return createChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return createChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (createChat != null) {
      return createChat(this);
    }
    return orElse();
  }
}

abstract class _CreateChat implements ChatEvent {
  const factory _CreateChat(
      {required final ChatType type,
      final String? name,
      final String? description,
      required final List<String> participantIds}) = _$CreateChatImpl;

  ChatType get type;
  String? get name;
  String? get description;
  List<String> get participantIds;
  @JsonKey(ignore: true)
  _$$CreateChatImplCopyWith<_$CreateChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateChatImplCopyWith<$Res> {
  factory _$$UpdateChatImplCopyWith(
          _$UpdateChatImpl value, $Res Function(_$UpdateChatImpl) then) =
      __$$UpdateChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, String? name, String? description, String? avatar});
}

/// @nodoc
class __$$UpdateChatImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$UpdateChatImpl>
    implements _$$UpdateChatImplCopyWith<$Res> {
  __$$UpdateChatImplCopyWithImpl(
      _$UpdateChatImpl _value, $Res Function(_$UpdateChatImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? name = freezed,
    Object? description = freezed,
    Object? avatar = freezed,
  }) {
    return _then(_$UpdateChatImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UpdateChatImpl implements _UpdateChat {
  const _$UpdateChatImpl(
      {required this.chatId, this.name, this.description, this.avatar});

  @override
  final String chatId;
  @override
  final String? name;
  @override
  final String? description;
  @override
  final String? avatar;

  @override
  String toString() {
    return 'ChatEvent.updateChat(chatId: $chatId, name: $name, description: $description, avatar: $avatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateChatImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.avatar, avatar) || other.avatar == avatar));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, chatId, name, description, avatar);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateChatImplCopyWith<_$UpdateChatImpl> get copyWith =>
      __$$UpdateChatImplCopyWithImpl<_$UpdateChatImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return updateChat(chatId, name, description, avatar);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return updateChat?.call(chatId, name, description, avatar);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (updateChat != null) {
      return updateChat(chatId, name, description, avatar);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return updateChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return updateChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (updateChat != null) {
      return updateChat(this);
    }
    return orElse();
  }
}

abstract class _UpdateChat implements ChatEvent {
  const factory _UpdateChat(
      {required final String chatId,
      final String? name,
      final String? description,
      final String? avatar}) = _$UpdateChatImpl;

  String get chatId;
  String? get name;
  String? get description;
  String? get avatar;
  @JsonKey(ignore: true)
  _$$UpdateChatImplCopyWith<_$UpdateChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LeaveChatImplCopyWith<$Res> {
  factory _$$LeaveChatImplCopyWith(
          _$LeaveChatImpl value, $Res Function(_$LeaveChatImpl) then) =
      __$$LeaveChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId});
}

/// @nodoc
class __$$LeaveChatImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$LeaveChatImpl>
    implements _$$LeaveChatImplCopyWith<$Res> {
  __$$LeaveChatImplCopyWithImpl(
      _$LeaveChatImpl _value, $Res Function(_$LeaveChatImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
  }) {
    return _then(_$LeaveChatImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$LeaveChatImpl implements _LeaveChat {
  const _$LeaveChatImpl({required this.chatId});

  @override
  final String chatId;

  @override
  String toString() {
    return 'ChatEvent.leaveChat(chatId: $chatId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaveChatImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaveChatImplCopyWith<_$LeaveChatImpl> get copyWith =>
      __$$LeaveChatImplCopyWithImpl<_$LeaveChatImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return leaveChat(chatId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return leaveChat?.call(chatId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (leaveChat != null) {
      return leaveChat(chatId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return leaveChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return leaveChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (leaveChat != null) {
      return leaveChat(this);
    }
    return orElse();
  }
}

abstract class _LeaveChat implements ChatEvent {
  const factory _LeaveChat({required final String chatId}) = _$LeaveChatImpl;

  String get chatId;
  @JsonKey(ignore: true)
  _$$LeaveChatImplCopyWith<_$LeaveChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AddUsersToChatImplCopyWith<$Res> {
  factory _$$AddUsersToChatImplCopyWith(_$AddUsersToChatImpl value,
          $Res Function(_$AddUsersToChatImpl) then) =
      __$$AddUsersToChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, List<String> userIds});
}

/// @nodoc
class __$$AddUsersToChatImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$AddUsersToChatImpl>
    implements _$$AddUsersToChatImplCopyWith<$Res> {
  __$$AddUsersToChatImplCopyWithImpl(
      _$AddUsersToChatImpl _value, $Res Function(_$AddUsersToChatImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? userIds = null,
  }) {
    return _then(_$AddUsersToChatImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      userIds: null == userIds
          ? _value._userIds
          : userIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$AddUsersToChatImpl implements _AddUsersToChat {
  const _$AddUsersToChatImpl(
      {required this.chatId, required final List<String> userIds})
      : _userIds = userIds;

  @override
  final String chatId;
  final List<String> _userIds;
  @override
  List<String> get userIds {
    if (_userIds is EqualUnmodifiableListView) return _userIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userIds);
  }

  @override
  String toString() {
    return 'ChatEvent.addUsersToChat(chatId: $chatId, userIds: $userIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddUsersToChatImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            const DeepCollectionEquality().equals(other._userIds, _userIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, chatId, const DeepCollectionEquality().hash(_userIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AddUsersToChatImplCopyWith<_$AddUsersToChatImpl> get copyWith =>
      __$$AddUsersToChatImplCopyWithImpl<_$AddUsersToChatImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return addUsersToChat(chatId, userIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return addUsersToChat?.call(chatId, userIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (addUsersToChat != null) {
      return addUsersToChat(chatId, userIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return addUsersToChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return addUsersToChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (addUsersToChat != null) {
      return addUsersToChat(this);
    }
    return orElse();
  }
}

abstract class _AddUsersToChat implements ChatEvent {
  const factory _AddUsersToChat(
      {required final String chatId,
      required final List<String> userIds}) = _$AddUsersToChatImpl;

  String get chatId;
  List<String> get userIds;
  @JsonKey(ignore: true)
  _$$AddUsersToChatImplCopyWith<_$AddUsersToChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RemoveUsersFromChatImplCopyWith<$Res> {
  factory _$$RemoveUsersFromChatImplCopyWith(_$RemoveUsersFromChatImpl value,
          $Res Function(_$RemoveUsersFromChatImpl) then) =
      __$$RemoveUsersFromChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, List<String> userIds});
}

/// @nodoc
class __$$RemoveUsersFromChatImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$RemoveUsersFromChatImpl>
    implements _$$RemoveUsersFromChatImplCopyWith<$Res> {
  __$$RemoveUsersFromChatImplCopyWithImpl(_$RemoveUsersFromChatImpl _value,
      $Res Function(_$RemoveUsersFromChatImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? userIds = null,
  }) {
    return _then(_$RemoveUsersFromChatImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      userIds: null == userIds
          ? _value._userIds
          : userIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$RemoveUsersFromChatImpl implements _RemoveUsersFromChat {
  const _$RemoveUsersFromChatImpl(
      {required this.chatId, required final List<String> userIds})
      : _userIds = userIds;

  @override
  final String chatId;
  final List<String> _userIds;
  @override
  List<String> get userIds {
    if (_userIds is EqualUnmodifiableListView) return _userIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userIds);
  }

  @override
  String toString() {
    return 'ChatEvent.removeUsersFromChat(chatId: $chatId, userIds: $userIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoveUsersFromChatImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            const DeepCollectionEquality().equals(other._userIds, _userIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, chatId, const DeepCollectionEquality().hash(_userIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RemoveUsersFromChatImplCopyWith<_$RemoveUsersFromChatImpl> get copyWith =>
      __$$RemoveUsersFromChatImplCopyWithImpl<_$RemoveUsersFromChatImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return removeUsersFromChat(chatId, userIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return removeUsersFromChat?.call(chatId, userIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (removeUsersFromChat != null) {
      return removeUsersFromChat(chatId, userIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return removeUsersFromChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return removeUsersFromChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (removeUsersFromChat != null) {
      return removeUsersFromChat(this);
    }
    return orElse();
  }
}

abstract class _RemoveUsersFromChat implements ChatEvent {
  const factory _RemoveUsersFromChat(
      {required final String chatId,
      required final List<String> userIds}) = _$RemoveUsersFromChatImpl;

  String get chatId;
  List<String> get userIds;
  @JsonKey(ignore: true)
  _$$RemoveUsersFromChatImplCopyWith<_$RemoveUsersFromChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MarkMessagesAsReadImplCopyWith<$Res> {
  factory _$$MarkMessagesAsReadImplCopyWith(_$MarkMessagesAsReadImpl value,
          $Res Function(_$MarkMessagesAsReadImpl) then) =
      __$$MarkMessagesAsReadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, List<String> messageIds});
}

/// @nodoc
class __$$MarkMessagesAsReadImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$MarkMessagesAsReadImpl>
    implements _$$MarkMessagesAsReadImplCopyWith<$Res> {
  __$$MarkMessagesAsReadImplCopyWithImpl(_$MarkMessagesAsReadImpl _value,
      $Res Function(_$MarkMessagesAsReadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? messageIds = null,
  }) {
    return _then(_$MarkMessagesAsReadImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      messageIds: null == messageIds
          ? _value._messageIds
          : messageIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$MarkMessagesAsReadImpl implements _MarkMessagesAsRead {
  const _$MarkMessagesAsReadImpl(
      {required this.chatId, required final List<String> messageIds})
      : _messageIds = messageIds;

  @override
  final String chatId;
  final List<String> _messageIds;
  @override
  List<String> get messageIds {
    if (_messageIds is EqualUnmodifiableListView) return _messageIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messageIds);
  }

  @override
  String toString() {
    return 'ChatEvent.markMessagesAsRead(chatId: $chatId, messageIds: $messageIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarkMessagesAsReadImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            const DeepCollectionEquality()
                .equals(other._messageIds, _messageIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, chatId, const DeepCollectionEquality().hash(_messageIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MarkMessagesAsReadImplCopyWith<_$MarkMessagesAsReadImpl> get copyWith =>
      __$$MarkMessagesAsReadImplCopyWithImpl<_$MarkMessagesAsReadImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return markMessagesAsRead(chatId, messageIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return markMessagesAsRead?.call(chatId, messageIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (markMessagesAsRead != null) {
      return markMessagesAsRead(chatId, messageIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return markMessagesAsRead(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return markMessagesAsRead?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (markMessagesAsRead != null) {
      return markMessagesAsRead(this);
    }
    return orElse();
  }
}

abstract class _MarkMessagesAsRead implements ChatEvent {
  const factory _MarkMessagesAsRead(
      {required final String chatId,
      required final List<String> messageIds}) = _$MarkMessagesAsReadImpl;

  String get chatId;
  List<String> get messageIds;
  @JsonKey(ignore: true)
  _$$MarkMessagesAsReadImplCopyWith<_$MarkMessagesAsReadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncChatsImplCopyWith<$Res> {
  factory _$$SyncChatsImplCopyWith(
          _$SyncChatsImpl value, $Res Function(_$SyncChatsImpl) then) =
      __$$SyncChatsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncChatsImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$SyncChatsImpl>
    implements _$$SyncChatsImplCopyWith<$Res> {
  __$$SyncChatsImplCopyWithImpl(
      _$SyncChatsImpl _value, $Res Function(_$SyncChatsImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SyncChatsImpl implements _SyncChats {
  const _$SyncChatsImpl();

  @override
  String toString() {
    return 'ChatEvent.syncChats()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SyncChatsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return syncChats();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return syncChats?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (syncChats != null) {
      return syncChats();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return syncChats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return syncChats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (syncChats != null) {
      return syncChats(this);
    }
    return orElse();
  }
}

abstract class _SyncChats implements ChatEvent {
  const factory _SyncChats() = _$SyncChatsImpl;
}

/// @nodoc
abstract class _$$SyncMessagesImplCopyWith<$Res> {
  factory _$$SyncMessagesImplCopyWith(
          _$SyncMessagesImpl value, $Res Function(_$SyncMessagesImpl) then) =
      __$$SyncMessagesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId});
}

/// @nodoc
class __$$SyncMessagesImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$SyncMessagesImpl>
    implements _$$SyncMessagesImplCopyWith<$Res> {
  __$$SyncMessagesImplCopyWithImpl(
      _$SyncMessagesImpl _value, $Res Function(_$SyncMessagesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
  }) {
    return _then(_$SyncMessagesImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SyncMessagesImpl implements _SyncMessages {
  const _$SyncMessagesImpl({required this.chatId});

  @override
  final String chatId;

  @override
  String toString() {
    return 'ChatEvent.syncMessages(chatId: $chatId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncMessagesImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncMessagesImplCopyWith<_$SyncMessagesImpl> get copyWith =>
      __$$SyncMessagesImplCopyWithImpl<_$SyncMessagesImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return syncMessages(chatId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return syncMessages?.call(chatId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (syncMessages != null) {
      return syncMessages(chatId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return syncMessages(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return syncMessages?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (syncMessages != null) {
      return syncMessages(this);
    }
    return orElse();
  }
}

abstract class _SyncMessages implements ChatEvent {
  const factory _SyncMessages({required final String chatId}) =
      _$SyncMessagesImpl;

  String get chatId;
  @JsonKey(ignore: true)
  _$$SyncMessagesImplCopyWith<_$SyncMessagesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NewMessageReceivedImplCopyWith<$Res> {
  factory _$$NewMessageReceivedImplCopyWith(_$NewMessageReceivedImpl value,
          $Res Function(_$NewMessageReceivedImpl) then) =
      __$$NewMessageReceivedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ChatMessage message});
}

/// @nodoc
class __$$NewMessageReceivedImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$NewMessageReceivedImpl>
    implements _$$NewMessageReceivedImplCopyWith<$Res> {
  __$$NewMessageReceivedImplCopyWithImpl(_$NewMessageReceivedImpl _value,
      $Res Function(_$NewMessageReceivedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$NewMessageReceivedImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as ChatMessage,
    ));
  }
}

/// @nodoc

class _$NewMessageReceivedImpl implements _NewMessageReceived {
  const _$NewMessageReceivedImpl(this.message);

  @override
  final ChatMessage message;

  @override
  String toString() {
    return 'ChatEvent.newMessageReceived(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewMessageReceivedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NewMessageReceivedImplCopyWith<_$NewMessageReceivedImpl> get copyWith =>
      __$$NewMessageReceivedImplCopyWithImpl<_$NewMessageReceivedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return newMessageReceived(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return newMessageReceived?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (newMessageReceived != null) {
      return newMessageReceived(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return newMessageReceived(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return newMessageReceived?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (newMessageReceived != null) {
      return newMessageReceived(this);
    }
    return orElse();
  }
}

abstract class _NewMessageReceived implements ChatEvent {
  const factory _NewMessageReceived(final ChatMessage message) =
      _$NewMessageReceivedImpl;

  ChatMessage get message;
  @JsonKey(ignore: true)
  _$$NewMessageReceivedImplCopyWith<_$NewMessageReceivedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ConnectivityChangedImplCopyWith<$Res> {
  factory _$$ConnectivityChangedImplCopyWith(_$ConnectivityChangedImpl value,
          $Res Function(_$ConnectivityChangedImpl) then) =
      __$$ConnectivityChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool isConnected});
}

/// @nodoc
class __$$ConnectivityChangedImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$ConnectivityChangedImpl>
    implements _$$ConnectivityChangedImplCopyWith<$Res> {
  __$$ConnectivityChangedImplCopyWithImpl(_$ConnectivityChangedImpl _value,
      $Res Function(_$ConnectivityChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isConnected = null,
  }) {
    return _then(_$ConnectivityChangedImpl(
      null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ConnectivityChangedImpl implements _ConnectivityChanged {
  const _$ConnectivityChangedImpl(this.isConnected);

  @override
  final bool isConnected;

  @override
  String toString() {
    return 'ChatEvent.connectivityChanged(isConnected: $isConnected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectivityChangedImpl &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isConnected);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectivityChangedImplCopyWith<_$ConnectivityChangedImpl> get copyWith =>
      __$$ConnectivityChangedImplCopyWithImpl<_$ConnectivityChangedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return connectivityChanged(isConnected);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return connectivityChanged?.call(isConnected);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (connectivityChanged != null) {
      return connectivityChanged(isConnected);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return connectivityChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return connectivityChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (connectivityChanged != null) {
      return connectivityChanged(this);
    }
    return orElse();
  }
}

abstract class _ConnectivityChanged implements ChatEvent {
  const factory _ConnectivityChanged(final bool isConnected) =
      _$ConnectivityChangedImpl;

  bool get isConnected;
  @JsonKey(ignore: true)
  _$$ConnectivityChangedImplCopyWith<_$ConnectivityChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessageStatusUpdatedImplCopyWith<$Res> {
  factory _$$MessageStatusUpdatedImplCopyWith(_$MessageStatusUpdatedImpl value,
          $Res Function(_$MessageStatusUpdatedImpl) then) =
      __$$MessageStatusUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({QueuedMessage message});
}

/// @nodoc
class __$$MessageStatusUpdatedImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$MessageStatusUpdatedImpl>
    implements _$$MessageStatusUpdatedImplCopyWith<$Res> {
  __$$MessageStatusUpdatedImplCopyWithImpl(_$MessageStatusUpdatedImpl _value,
      $Res Function(_$MessageStatusUpdatedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$MessageStatusUpdatedImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as QueuedMessage,
    ));
  }
}

/// @nodoc

class _$MessageStatusUpdatedImpl implements _MessageStatusUpdated {
  const _$MessageStatusUpdatedImpl(this.message);

  @override
  final QueuedMessage message;

  @override
  String toString() {
    return 'ChatEvent.messageStatusUpdated(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageStatusUpdatedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageStatusUpdatedImplCopyWith<_$MessageStatusUpdatedImpl>
      get copyWith =>
          __$$MessageStatusUpdatedImplCopyWithImpl<_$MessageStatusUpdatedImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return messageStatusUpdated(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return messageStatusUpdated?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (messageStatusUpdated != null) {
      return messageStatusUpdated(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return messageStatusUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return messageStatusUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (messageStatusUpdated != null) {
      return messageStatusUpdated(this);
    }
    return orElse();
  }
}

abstract class _MessageStatusUpdated implements ChatEvent {
  const factory _MessageStatusUpdated(final QueuedMessage message) =
      _$MessageStatusUpdatedImpl;

  QueuedMessage get message;
  @JsonKey(ignore: true)
  _$$MessageStatusUpdatedImplCopyWith<_$MessageStatusUpdatedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatUpdatedImplCopyWith<$Res> {
  factory _$$ChatUpdatedImplCopyWith(
          _$ChatUpdatedImpl value, $Res Function(_$ChatUpdatedImpl) then) =
      __$$ChatUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Chat chat});
}

/// @nodoc
class __$$ChatUpdatedImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$ChatUpdatedImpl>
    implements _$$ChatUpdatedImplCopyWith<$Res> {
  __$$ChatUpdatedImplCopyWithImpl(
      _$ChatUpdatedImpl _value, $Res Function(_$ChatUpdatedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chat = null,
  }) {
    return _then(_$ChatUpdatedImpl(
      chat: null == chat
          ? _value.chat
          : chat // ignore: cast_nullable_to_non_nullable
              as Chat,
    ));
  }
}

/// @nodoc

class _$ChatUpdatedImpl implements _ChatUpdated {
  const _$ChatUpdatedImpl({required this.chat});

  @override
  final Chat chat;

  @override
  String toString() {
    return 'ChatEvent.chatUpdated(chat: $chat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatUpdatedImpl &&
            (identical(other.chat, chat) || other.chat == chat));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatUpdatedImplCopyWith<_$ChatUpdatedImpl> get copyWith =>
      __$$ChatUpdatedImplCopyWithImpl<_$ChatUpdatedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return chatUpdated(chat);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return chatUpdated?.call(chat);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (chatUpdated != null) {
      return chatUpdated(chat);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return chatUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return chatUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (chatUpdated != null) {
      return chatUpdated(this);
    }
    return orElse();
  }
}

abstract class _ChatUpdated implements ChatEvent {
  const factory _ChatUpdated({required final Chat chat}) = _$ChatUpdatedImpl;

  Chat get chat;
  @JsonKey(ignore: true)
  _$$ChatUpdatedImplCopyWith<_$ChatUpdatedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchChatsImplCopyWith<$Res> {
  factory _$$SearchChatsImplCopyWith(
          _$SearchChatsImpl value, $Res Function(_$SearchChatsImpl) then) =
      __$$SearchChatsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String keyword});
}

/// @nodoc
class __$$SearchChatsImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$SearchChatsImpl>
    implements _$$SearchChatsImplCopyWith<$Res> {
  __$$SearchChatsImplCopyWithImpl(
      _$SearchChatsImpl _value, $Res Function(_$SearchChatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyword = null,
  }) {
    return _then(_$SearchChatsImpl(
      keyword: null == keyword
          ? _value.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SearchChatsImpl implements _SearchChats {
  const _$SearchChatsImpl({required this.keyword});

  @override
  final String keyword;

  @override
  String toString() {
    return 'ChatEvent.searchChats(keyword: $keyword)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchChatsImpl &&
            (identical(other.keyword, keyword) || other.keyword == keyword));
  }

  @override
  int get hashCode => Object.hash(runtimeType, keyword);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchChatsImplCopyWith<_$SearchChatsImpl> get copyWith =>
      __$$SearchChatsImplCopyWithImpl<_$SearchChatsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return searchChats(keyword);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return searchChats?.call(keyword);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (searchChats != null) {
      return searchChats(keyword);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return searchChats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return searchChats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (searchChats != null) {
      return searchChats(this);
    }
    return orElse();
  }
}

abstract class _SearchChats implements ChatEvent {
  const factory _SearchChats({required final String keyword}) =
      _$SearchChatsImpl;

  String get keyword;
  @JsonKey(ignore: true)
  _$$SearchChatsImplCopyWith<_$SearchChatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ClearSearchImplCopyWith<$Res> {
  factory _$$ClearSearchImplCopyWith(
          _$ClearSearchImpl value, $Res Function(_$ClearSearchImpl) then) =
      __$$ClearSearchImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ClearSearchImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$ClearSearchImpl>
    implements _$$ClearSearchImplCopyWith<$Res> {
  __$$ClearSearchImplCopyWithImpl(
      _$ClearSearchImpl _value, $Res Function(_$ClearSearchImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$ClearSearchImpl implements _ClearSearch {
  const _$ClearSearchImpl();

  @override
  String toString() {
    return 'ChatEvent.clearSearch()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ClearSearchImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool forceRefresh) loadChats,
    required TResult Function() loadMoreChats,
    required TResult Function(String chatId) loadChatDetails,
    required TResult Function(String chatId, int limit, int offset)
        loadMessages,
    required TResult Function(String chatId, String content,
            ContentType contentType, List<String> attachmentIds)
        sendMessage,
    required TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)
        createChat,
    required TResult Function(
            String chatId, String? name, String? description, String? avatar)
        updateChat,
    required TResult Function(String chatId) leaveChat,
    required TResult Function(String chatId, List<String> userIds)
        addUsersToChat,
    required TResult Function(String chatId, List<String> userIds)
        removeUsersFromChat,
    required TResult Function(String chatId, List<String> messageIds)
        markMessagesAsRead,
    required TResult Function() syncChats,
    required TResult Function(String chatId) syncMessages,
    required TResult Function(ChatMessage message) newMessageReceived,
    required TResult Function(bool isConnected) connectivityChanged,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(Chat chat) chatUpdated,
    required TResult Function(String keyword) searchChats,
    required TResult Function() clearSearch,
  }) {
    return clearSearch();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool forceRefresh)? loadChats,
    TResult? Function()? loadMoreChats,
    TResult? Function(String chatId)? loadChatDetails,
    TResult? Function(String chatId, int limit, int offset)? loadMessages,
    TResult? Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult? Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult? Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult? Function(String chatId)? leaveChat,
    TResult? Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult? Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult? Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult? Function()? syncChats,
    TResult? Function(String chatId)? syncMessages,
    TResult? Function(ChatMessage message)? newMessageReceived,
    TResult? Function(bool isConnected)? connectivityChanged,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(Chat chat)? chatUpdated,
    TResult? Function(String keyword)? searchChats,
    TResult? Function()? clearSearch,
  }) {
    return clearSearch?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool forceRefresh)? loadChats,
    TResult Function()? loadMoreChats,
    TResult Function(String chatId)? loadChatDetails,
    TResult Function(String chatId, int limit, int offset)? loadMessages,
    TResult Function(String chatId, String content, ContentType contentType,
            List<String> attachmentIds)?
        sendMessage,
    TResult Function(ChatType type, String? name, String? description,
            List<String> participantIds)?
        createChat,
    TResult Function(
            String chatId, String? name, String? description, String? avatar)?
        updateChat,
    TResult Function(String chatId)? leaveChat,
    TResult Function(String chatId, List<String> userIds)? addUsersToChat,
    TResult Function(String chatId, List<String> userIds)? removeUsersFromChat,
    TResult Function(String chatId, List<String> messageIds)?
        markMessagesAsRead,
    TResult Function()? syncChats,
    TResult Function(String chatId)? syncMessages,
    TResult Function(ChatMessage message)? newMessageReceived,
    TResult Function(bool isConnected)? connectivityChanged,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(Chat chat)? chatUpdated,
    TResult Function(String keyword)? searchChats,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    if (clearSearch != null) {
      return clearSearch();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadChats value) loadChats,
    required TResult Function(_LoadMoreChats value) loadMoreChats,
    required TResult Function(_LoadChatDetails value) loadChatDetails,
    required TResult Function(_LoadMessages value) loadMessages,
    required TResult Function(_SendMessage value) sendMessage,
    required TResult Function(_CreateChat value) createChat,
    required TResult Function(_UpdateChat value) updateChat,
    required TResult Function(_LeaveChat value) leaveChat,
    required TResult Function(_AddUsersToChat value) addUsersToChat,
    required TResult Function(_RemoveUsersFromChat value) removeUsersFromChat,
    required TResult Function(_MarkMessagesAsRead value) markMessagesAsRead,
    required TResult Function(_SyncChats value) syncChats,
    required TResult Function(_SyncMessages value) syncMessages,
    required TResult Function(_NewMessageReceived value) newMessageReceived,
    required TResult Function(_ConnectivityChanged value) connectivityChanged,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_ChatUpdated value) chatUpdated,
    required TResult Function(_SearchChats value) searchChats,
    required TResult Function(_ClearSearch value) clearSearch,
  }) {
    return clearSearch(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadChats value)? loadChats,
    TResult? Function(_LoadMoreChats value)? loadMoreChats,
    TResult? Function(_LoadChatDetails value)? loadChatDetails,
    TResult? Function(_LoadMessages value)? loadMessages,
    TResult? Function(_SendMessage value)? sendMessage,
    TResult? Function(_CreateChat value)? createChat,
    TResult? Function(_UpdateChat value)? updateChat,
    TResult? Function(_LeaveChat value)? leaveChat,
    TResult? Function(_AddUsersToChat value)? addUsersToChat,
    TResult? Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult? Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult? Function(_SyncChats value)? syncChats,
    TResult? Function(_SyncMessages value)? syncMessages,
    TResult? Function(_NewMessageReceived value)? newMessageReceived,
    TResult? Function(_ConnectivityChanged value)? connectivityChanged,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_ChatUpdated value)? chatUpdated,
    TResult? Function(_SearchChats value)? searchChats,
    TResult? Function(_ClearSearch value)? clearSearch,
  }) {
    return clearSearch?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadChats value)? loadChats,
    TResult Function(_LoadMoreChats value)? loadMoreChats,
    TResult Function(_LoadChatDetails value)? loadChatDetails,
    TResult Function(_LoadMessages value)? loadMessages,
    TResult Function(_SendMessage value)? sendMessage,
    TResult Function(_CreateChat value)? createChat,
    TResult Function(_UpdateChat value)? updateChat,
    TResult Function(_LeaveChat value)? leaveChat,
    TResult Function(_AddUsersToChat value)? addUsersToChat,
    TResult Function(_RemoveUsersFromChat value)? removeUsersFromChat,
    TResult Function(_MarkMessagesAsRead value)? markMessagesAsRead,
    TResult Function(_SyncChats value)? syncChats,
    TResult Function(_SyncMessages value)? syncMessages,
    TResult Function(_NewMessageReceived value)? newMessageReceived,
    TResult Function(_ConnectivityChanged value)? connectivityChanged,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_ChatUpdated value)? chatUpdated,
    TResult Function(_SearchChats value)? searchChats,
    TResult Function(_ClearSearch value)? clearSearch,
    required TResult orElse(),
  }) {
    if (clearSearch != null) {
      return clearSearch(this);
    }
    return orElse();
  }
}

abstract class _ClearSearch implements ChatEvent {
  const factory _ClearSearch() = _$ClearSearchImpl;
}

/// @nodoc
mixin _$ChatState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) then) =
      _$ChatStateCopyWithImpl<$Res, ChatState>;
}

/// @nodoc
class _$ChatStateCopyWithImpl<$Res, $Val extends ChatState>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'ChatState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements ChatState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
          _$LoadingImpl value, $Res Function(_$LoadingImpl) then) =
      __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
      _$LoadingImpl _value, $Res Function(_$LoadingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'ChatState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements ChatState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
          _$LoadedImpl value, $Res Function(_$LoadedImpl) then) =
      __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {List<Chat> chats,
      bool hasMore,
      bool isLoadingMore,
      int page,
      int pageSize,
      int total});
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
      _$LoadedImpl _value, $Res Function(_$LoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chats = null,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? page = null,
    Object? pageSize = null,
    Object? total = null,
  }) {
    return _then(_$LoadedImpl(
      chats: null == chats
          ? _value._chats
          : chats // ignore: cast_nullable_to_non_nullable
              as List<Chat>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl(
      {required final List<Chat> chats,
      this.hasMore = false,
      this.isLoadingMore = false,
      this.page = 0,
      this.pageSize = 25,
      this.total = 0})
      : _chats = chats;

  final List<Chat> _chats;
  @override
  List<Chat> get chats {
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chats);
  }

  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  @JsonKey()
  final int page;
  @override
  @JsonKey()
  final int pageSize;
  @override
  @JsonKey()
  final int total;

  @override
  String toString() {
    return 'ChatState.loaded(chats: $chats, hasMore: $hasMore, isLoadingMore: $isLoadingMore, page: $page, pageSize: $pageSize, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            const DeepCollectionEquality().equals(other._chats, _chats) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.total, total) || other.total == total));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_chats),
      hasMore,
      isLoadingMore,
      page,
      pageSize,
      total);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return loaded(chats, hasMore, isLoadingMore, page, pageSize, total);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(chats, hasMore, isLoadingMore, page, pageSize, total);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(chats, hasMore, isLoadingMore, page, pageSize, total);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements ChatState {
  const factory _Loaded(
      {required final List<Chat> chats,
      final bool hasMore,
      final bool isLoadingMore,
      final int page,
      final int pageSize,
      final int total}) = _$LoadedImpl;

  List<Chat> get chats;
  bool get hasMore;
  bool get isLoadingMore;
  int get page;
  int get pageSize;
  int get total;
  @JsonKey(ignore: true)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatDetailsLoadedImplCopyWith<$Res> {
  factory _$$ChatDetailsLoadedImplCopyWith(_$ChatDetailsLoadedImpl value,
          $Res Function(_$ChatDetailsLoadedImpl) then) =
      __$$ChatDetailsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Chat chat});
}

/// @nodoc
class __$$ChatDetailsLoadedImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatDetailsLoadedImpl>
    implements _$$ChatDetailsLoadedImplCopyWith<$Res> {
  __$$ChatDetailsLoadedImplCopyWithImpl(_$ChatDetailsLoadedImpl _value,
      $Res Function(_$ChatDetailsLoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chat = null,
  }) {
    return _then(_$ChatDetailsLoadedImpl(
      chat: null == chat
          ? _value.chat
          : chat // ignore: cast_nullable_to_non_nullable
              as Chat,
    ));
  }
}

/// @nodoc

class _$ChatDetailsLoadedImpl implements _ChatDetailsLoaded {
  const _$ChatDetailsLoadedImpl({required this.chat});

  @override
  final Chat chat;

  @override
  String toString() {
    return 'ChatState.chatDetailsLoaded(chat: $chat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatDetailsLoadedImpl &&
            (identical(other.chat, chat) || other.chat == chat));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatDetailsLoadedImplCopyWith<_$ChatDetailsLoadedImpl> get copyWith =>
      __$$ChatDetailsLoadedImplCopyWithImpl<_$ChatDetailsLoadedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return chatDetailsLoaded(chat);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return chatDetailsLoaded?.call(chat);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (chatDetailsLoaded != null) {
      return chatDetailsLoaded(chat);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return chatDetailsLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return chatDetailsLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (chatDetailsLoaded != null) {
      return chatDetailsLoaded(this);
    }
    return orElse();
  }
}

abstract class _ChatDetailsLoaded implements ChatState {
  const factory _ChatDetailsLoaded({required final Chat chat}) =
      _$ChatDetailsLoadedImpl;

  Chat get chat;
  @JsonKey(ignore: true)
  _$$ChatDetailsLoadedImplCopyWith<_$ChatDetailsLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessagesLoadingImplCopyWith<$Res> {
  factory _$$MessagesLoadingImplCopyWith(_$MessagesLoadingImpl value,
          $Res Function(_$MessagesLoadingImpl) then) =
      __$$MessagesLoadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<Chat>? chats});
}

/// @nodoc
class __$$MessagesLoadingImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$MessagesLoadingImpl>
    implements _$$MessagesLoadingImplCopyWith<$Res> {
  __$$MessagesLoadingImplCopyWithImpl(
      _$MessagesLoadingImpl _value, $Res Function(_$MessagesLoadingImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chats = freezed,
  }) {
    return _then(_$MessagesLoadingImpl(
      chats: freezed == chats
          ? _value._chats
          : chats // ignore: cast_nullable_to_non_nullable
              as List<Chat>?,
    ));
  }
}

/// @nodoc

class _$MessagesLoadingImpl implements _MessagesLoading {
  const _$MessagesLoadingImpl({final List<Chat>? chats}) : _chats = chats;

  final List<Chat>? _chats;
  @override
  List<Chat>? get chats {
    final value = _chats;
    if (value == null) return null;
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ChatState.messagesLoading(chats: $chats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessagesLoadingImpl &&
            const DeepCollectionEquality().equals(other._chats, _chats));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_chats));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessagesLoadingImplCopyWith<_$MessagesLoadingImpl> get copyWith =>
      __$$MessagesLoadingImplCopyWithImpl<_$MessagesLoadingImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return messagesLoading(chats);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return messagesLoading?.call(chats);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (messagesLoading != null) {
      return messagesLoading(chats);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return messagesLoading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return messagesLoading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (messagesLoading != null) {
      return messagesLoading(this);
    }
    return orElse();
  }
}

abstract class _MessagesLoading implements ChatState {
  const factory _MessagesLoading({final List<Chat>? chats}) =
      _$MessagesLoadingImpl;

  List<Chat>? get chats;
  @JsonKey(ignore: true)
  _$$MessagesLoadingImplCopyWith<_$MessagesLoadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessagesLoadedImplCopyWith<$Res> {
  factory _$$MessagesLoadedImplCopyWith(_$MessagesLoadedImpl value,
          $Res Function(_$MessagesLoadedImpl) then) =
      __$$MessagesLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<Chat>? chats, String chatId, List<ChatMessage> messages});
}

/// @nodoc
class __$$MessagesLoadedImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$MessagesLoadedImpl>
    implements _$$MessagesLoadedImplCopyWith<$Res> {
  __$$MessagesLoadedImplCopyWithImpl(
      _$MessagesLoadedImpl _value, $Res Function(_$MessagesLoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chats = freezed,
    Object? chatId = null,
    Object? messages = null,
  }) {
    return _then(_$MessagesLoadedImpl(
      chats: freezed == chats
          ? _value._chats
          : chats // ignore: cast_nullable_to_non_nullable
              as List<Chat>?,
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
    ));
  }
}

/// @nodoc

class _$MessagesLoadedImpl implements _MessagesLoaded {
  const _$MessagesLoadedImpl(
      {final List<Chat>? chats,
      required this.chatId,
      required final List<ChatMessage> messages})
      : _chats = chats,
        _messages = messages;

  final List<Chat>? _chats;
  @override
  List<Chat>? get chats {
    final value = _chats;
    if (value == null) return null;
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String chatId;
  final List<ChatMessage> _messages;
  @override
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'ChatState.messagesLoaded(chats: $chats, chatId: $chatId, messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessagesLoadedImpl &&
            const DeepCollectionEquality().equals(other._chats, _chats) &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_chats),
      chatId,
      const DeepCollectionEquality().hash(_messages));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessagesLoadedImplCopyWith<_$MessagesLoadedImpl> get copyWith =>
      __$$MessagesLoadedImplCopyWithImpl<_$MessagesLoadedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return messagesLoaded(chats, chatId, messages);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return messagesLoaded?.call(chats, chatId, messages);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (messagesLoaded != null) {
      return messagesLoaded(chats, chatId, messages);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return messagesLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return messagesLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (messagesLoaded != null) {
      return messagesLoaded(this);
    }
    return orElse();
  }
}

abstract class _MessagesLoaded implements ChatState {
  const factory _MessagesLoaded(
      {final List<Chat>? chats,
      required final String chatId,
      required final List<ChatMessage> messages}) = _$MessagesLoadedImpl;

  List<Chat>? get chats;
  String get chatId;
  List<ChatMessage> get messages;
  @JsonKey(ignore: true)
  _$$MessagesLoadedImplCopyWith<_$MessagesLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessageSendingImplCopyWith<$Res> {
  factory _$$MessageSendingImplCopyWith(_$MessageSendingImpl value,
          $Res Function(_$MessageSendingImpl) then) =
      __$$MessageSendingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, String localId});
}

/// @nodoc
class __$$MessageSendingImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$MessageSendingImpl>
    implements _$$MessageSendingImplCopyWith<$Res> {
  __$$MessageSendingImplCopyWithImpl(
      _$MessageSendingImpl _value, $Res Function(_$MessageSendingImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? localId = null,
  }) {
    return _then(_$MessageSendingImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      localId: null == localId
          ? _value.localId
          : localId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MessageSendingImpl implements _MessageSending {
  const _$MessageSendingImpl({required this.chatId, required this.localId});

  @override
  final String chatId;
  @override
  final String localId;

  @override
  String toString() {
    return 'ChatState.messageSending(chatId: $chatId, localId: $localId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageSendingImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.localId, localId) || other.localId == localId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId, localId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageSendingImplCopyWith<_$MessageSendingImpl> get copyWith =>
      __$$MessageSendingImplCopyWithImpl<_$MessageSendingImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return messageSending(chatId, localId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return messageSending?.call(chatId, localId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (messageSending != null) {
      return messageSending(chatId, localId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return messageSending(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return messageSending?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (messageSending != null) {
      return messageSending(this);
    }
    return orElse();
  }
}

abstract class _MessageSending implements ChatState {
  const factory _MessageSending(
      {required final String chatId,
      required final String localId}) = _$MessageSendingImpl;

  String get chatId;
  String get localId;
  @JsonKey(ignore: true)
  _$$MessageSendingImplCopyWith<_$MessageSendingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessageStatusChangedImplCopyWith<$Res> {
  factory _$$MessageStatusChangedImplCopyWith(_$MessageStatusChangedImpl value,
          $Res Function(_$MessageStatusChangedImpl) then) =
      __$$MessageStatusChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String chatId,
      String localId,
      MessageQueueStatus status,
      String? serverId});
}

/// @nodoc
class __$$MessageStatusChangedImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$MessageStatusChangedImpl>
    implements _$$MessageStatusChangedImplCopyWith<$Res> {
  __$$MessageStatusChangedImplCopyWithImpl(_$MessageStatusChangedImpl _value,
      $Res Function(_$MessageStatusChangedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? localId = null,
    Object? status = null,
    Object? serverId = freezed,
  }) {
    return _then(_$MessageStatusChangedImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      localId: null == localId
          ? _value.localId
          : localId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MessageQueueStatus,
      serverId: freezed == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MessageStatusChangedImpl implements _MessageStatusChanged {
  const _$MessageStatusChangedImpl(
      {required this.chatId,
      required this.localId,
      required this.status,
      this.serverId});

  @override
  final String chatId;
  @override
  final String localId;
  @override
  final MessageQueueStatus status;
  @override
  final String? serverId;

  @override
  String toString() {
    return 'ChatState.messageStatusChanged(chatId: $chatId, localId: $localId, status: $status, serverId: $serverId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageStatusChangedImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.localId, localId) || other.localId == localId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, chatId, localId, status, serverId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageStatusChangedImplCopyWith<_$MessageStatusChangedImpl>
      get copyWith =>
          __$$MessageStatusChangedImplCopyWithImpl<_$MessageStatusChangedImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return messageStatusChanged(chatId, localId, status, serverId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return messageStatusChanged?.call(chatId, localId, status, serverId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (messageStatusChanged != null) {
      return messageStatusChanged(chatId, localId, status, serverId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return messageStatusChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return messageStatusChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (messageStatusChanged != null) {
      return messageStatusChanged(this);
    }
    return orElse();
  }
}

abstract class _MessageStatusChanged implements ChatState {
  const factory _MessageStatusChanged(
      {required final String chatId,
      required final String localId,
      required final MessageQueueStatus status,
      final String? serverId}) = _$MessageStatusChangedImpl;

  String get chatId;
  String get localId;
  MessageQueueStatus get status;
  String? get serverId;
  @JsonKey(ignore: true)
  _$$MessageStatusChangedImplCopyWith<_$MessageStatusChangedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncingImplCopyWith<$Res> {
  factory _$$SyncingImplCopyWith(
          _$SyncingImpl value, $Res Function(_$SyncingImpl) then) =
      __$$SyncingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncingImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$SyncingImpl>
    implements _$$SyncingImplCopyWith<$Res> {
  __$$SyncingImplCopyWithImpl(
      _$SyncingImpl _value, $Res Function(_$SyncingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SyncingImpl implements _Syncing {
  const _$SyncingImpl();

  @override
  String toString() {
    return 'ChatState.syncing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SyncingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return syncing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return syncing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (syncing != null) {
      return syncing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return syncing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return syncing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (syncing != null) {
      return syncing(this);
    }
    return orElse();
  }
}

abstract class _Syncing implements ChatState {
  const factory _Syncing() = _$SyncingImpl;
}

/// @nodoc
abstract class _$$OfflineImplCopyWith<$Res> {
  factory _$$OfflineImplCopyWith(
          _$OfflineImpl value, $Res Function(_$OfflineImpl) then) =
      __$$OfflineImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OfflineImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$OfflineImpl>
    implements _$$OfflineImplCopyWith<$Res> {
  __$$OfflineImplCopyWithImpl(
      _$OfflineImpl _value, $Res Function(_$OfflineImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$OfflineImpl implements _Offline {
  const _$OfflineImpl();

  @override
  String toString() {
    return 'ChatState.offline()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$OfflineImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return offline();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return offline?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (offline != null) {
      return offline();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return offline(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return offline?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (offline != null) {
      return offline(this);
    }
    return orElse();
  }
}

abstract class _Offline implements ChatState {
  const factory _Offline() = _$OfflineImpl;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'ChatState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Chat> chats, bool hasMore,
            bool isLoadingMore, int page, int pageSize, int total)
        loaded,
    required TResult Function(Chat chat) chatDetailsLoaded,
    required TResult Function(List<Chat>? chats) messagesLoading,
    required TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)
        messagesLoaded,
    required TResult Function(String chatId, String localId) messageSending,
    required TResult Function(String chatId, String localId,
            MessageQueueStatus status, String? serverId)
        messageStatusChanged,
    required TResult Function() syncing,
    required TResult Function() offline,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult? Function(Chat chat)? chatDetailsLoaded,
    TResult? Function(List<Chat>? chats)? messagesLoading,
    TResult? Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult? Function(String chatId, String localId)? messageSending,
    TResult? Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult? Function()? syncing,
    TResult? Function()? offline,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Chat> chats, bool hasMore, bool isLoadingMore,
            int page, int pageSize, int total)?
        loaded,
    TResult Function(Chat chat)? chatDetailsLoaded,
    TResult Function(List<Chat>? chats)? messagesLoading,
    TResult Function(
            List<Chat>? chats, String chatId, List<ChatMessage> messages)?
        messagesLoaded,
    TResult Function(String chatId, String localId)? messageSending,
    TResult Function(String chatId, String localId, MessageQueueStatus status,
            String? serverId)?
        messageStatusChanged,
    TResult Function()? syncing,
    TResult Function()? offline,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_ChatDetailsLoaded value) chatDetailsLoaded,
    required TResult Function(_MessagesLoading value) messagesLoading,
    required TResult Function(_MessagesLoaded value) messagesLoaded,
    required TResult Function(_MessageSending value) messageSending,
    required TResult Function(_MessageStatusChanged value) messageStatusChanged,
    required TResult Function(_Syncing value) syncing,
    required TResult Function(_Offline value) offline,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult? Function(_MessagesLoading value)? messagesLoading,
    TResult? Function(_MessagesLoaded value)? messagesLoaded,
    TResult? Function(_MessageSending value)? messageSending,
    TResult? Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult? Function(_Syncing value)? syncing,
    TResult? Function(_Offline value)? offline,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_ChatDetailsLoaded value)? chatDetailsLoaded,
    TResult Function(_MessagesLoading value)? messagesLoading,
    TResult Function(_MessagesLoaded value)? messagesLoaded,
    TResult Function(_MessageSending value)? messageSending,
    TResult Function(_MessageStatusChanged value)? messageStatusChanged,
    TResult Function(_Syncing value)? syncing,
    TResult Function(_Offline value)? offline,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements ChatState {
  const factory _Error({required final String message}) = _$ErrorImpl;

  String get message;
  @JsonKey(ignore: true)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

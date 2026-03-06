// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MessageState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String chatId) loading,
    required TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)
        loaded,
    required TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)
        error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(String chatId)? loading,
    TResult? Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult? Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String chatId)? loading,
    TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageInitial value) initial,
    required TResult Function(MessagesLoading value) loading,
    required TResult Function(MessagesLoaded value) loaded,
    required TResult Function(MessagesError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageInitial value)? initial,
    TResult? Function(MessagesLoading value)? loading,
    TResult? Function(MessagesLoaded value)? loaded,
    TResult? Function(MessagesError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageInitial value)? initial,
    TResult Function(MessagesLoading value)? loading,
    TResult Function(MessagesLoaded value)? loaded,
    TResult Function(MessagesError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageStateCopyWith<$Res> {
  factory $MessageStateCopyWith(
          MessageState value, $Res Function(MessageState) then) =
      _$MessageStateCopyWithImpl<$Res, MessageState>;
}

/// @nodoc
class _$MessageStateCopyWithImpl<$Res, $Val extends MessageState>
    implements $MessageStateCopyWith<$Res> {
  _$MessageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$MessageInitialImplCopyWith<$Res> {
  factory _$$MessageInitialImplCopyWith(_$MessageInitialImpl value,
          $Res Function(_$MessageInitialImpl) then) =
      __$$MessageInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$MessageInitialImplCopyWithImpl<$Res>
    extends _$MessageStateCopyWithImpl<$Res, _$MessageInitialImpl>
    implements _$$MessageInitialImplCopyWith<$Res> {
  __$$MessageInitialImplCopyWithImpl(
      _$MessageInitialImpl _value, $Res Function(_$MessageInitialImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$MessageInitialImpl extends MessageInitial {
  const _$MessageInitialImpl() : super._();

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String chatId) loading,
    required TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)
        loaded,
    required TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)
        error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(String chatId)? loading,
    TResult? Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult? Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String chatId)? loading,
    TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
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
    required TResult Function(MessageInitial value) initial,
    required TResult Function(MessagesLoading value) loading,
    required TResult Function(MessagesLoaded value) loaded,
    required TResult Function(MessagesError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageInitial value)? initial,
    TResult? Function(MessagesLoading value)? loading,
    TResult? Function(MessagesLoaded value)? loaded,
    TResult? Function(MessagesError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageInitial value)? initial,
    TResult Function(MessagesLoading value)? loading,
    TResult Function(MessagesLoaded value)? loaded,
    TResult Function(MessagesError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class MessageInitial extends MessageState {
  const factory MessageInitial() = _$MessageInitialImpl;
  const MessageInitial._() : super._();
}

/// @nodoc
abstract class _$$MessagesLoadingImplCopyWith<$Res> {
  factory _$$MessagesLoadingImplCopyWith(_$MessagesLoadingImpl value,
          $Res Function(_$MessagesLoadingImpl) then) =
      __$$MessagesLoadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId});
}

/// @nodoc
class __$$MessagesLoadingImplCopyWithImpl<$Res>
    extends _$MessageStateCopyWithImpl<$Res, _$MessagesLoadingImpl>
    implements _$$MessagesLoadingImplCopyWith<$Res> {
  __$$MessagesLoadingImplCopyWithImpl(
      _$MessagesLoadingImpl _value, $Res Function(_$MessagesLoadingImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
  }) {
    return _then(_$MessagesLoadingImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MessagesLoadingImpl extends MessagesLoading {
  const _$MessagesLoadingImpl({required this.chatId}) : super._();

  @override
  final String chatId;

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
    required TResult Function(String chatId) loading,
    required TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)
        loaded,
    required TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)
        error,
  }) {
    return loading(chatId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(String chatId)? loading,
    TResult? Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult? Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
  }) {
    return loading?.call(chatId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String chatId)? loading,
    TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(chatId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageInitial value) initial,
    required TResult Function(MessagesLoading value) loading,
    required TResult Function(MessagesLoaded value) loaded,
    required TResult Function(MessagesError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageInitial value)? initial,
    TResult? Function(MessagesLoading value)? loading,
    TResult? Function(MessagesLoaded value)? loaded,
    TResult? Function(MessagesError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageInitial value)? initial,
    TResult Function(MessagesLoading value)? loading,
    TResult Function(MessagesLoaded value)? loaded,
    TResult Function(MessagesError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class MessagesLoading extends MessageState {
  const factory MessagesLoading({required final String chatId}) =
      _$MessagesLoadingImpl;
  const MessagesLoading._() : super._();

  String get chatId;
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
  $Res call(
      {String chatId,
      List<ChatMessage> messages,
      List<MessageUIState> uiMessages,
      bool hasReachedMax,
      String? paginationError,
      MessageDataSource dataSource,
      bool isBackgroundFetching,
      List<ConversationMember> conversationMembers,
      List<String> frequentReactions,
      String? receiverId});
}

/// @nodoc
class __$$MessagesLoadedImplCopyWithImpl<$Res>
    extends _$MessageStateCopyWithImpl<$Res, _$MessagesLoadedImpl>
    implements _$$MessagesLoadedImplCopyWith<$Res> {
  __$$MessagesLoadedImplCopyWithImpl(
      _$MessagesLoadedImpl _value, $Res Function(_$MessagesLoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? messages = null,
    Object? uiMessages = null,
    Object? hasReachedMax = null,
    Object? paginationError = freezed,
    Object? dataSource = null,
    Object? isBackgroundFetching = null,
    Object? conversationMembers = null,
    Object? frequentReactions = null,
    Object? receiverId = freezed,
  }) {
    return _then(_$MessagesLoadedImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      uiMessages: null == uiMessages
          ? _value._uiMessages
          : uiMessages // ignore: cast_nullable_to_non_nullable
              as List<MessageUIState>,
      hasReachedMax: null == hasReachedMax
          ? _value.hasReachedMax
          : hasReachedMax // ignore: cast_nullable_to_non_nullable
              as bool,
      paginationError: freezed == paginationError
          ? _value.paginationError
          : paginationError // ignore: cast_nullable_to_non_nullable
              as String?,
      dataSource: null == dataSource
          ? _value.dataSource
          : dataSource // ignore: cast_nullable_to_non_nullable
              as MessageDataSource,
      isBackgroundFetching: null == isBackgroundFetching
          ? _value.isBackgroundFetching
          : isBackgroundFetching // ignore: cast_nullable_to_non_nullable
              as bool,
      conversationMembers: null == conversationMembers
          ? _value._conversationMembers
          : conversationMembers // ignore: cast_nullable_to_non_nullable
              as List<ConversationMember>,
      frequentReactions: null == frequentReactions
          ? _value._frequentReactions
          : frequentReactions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      receiverId: freezed == receiverId
          ? _value.receiverId
          : receiverId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MessagesLoadedImpl extends MessagesLoaded {
  const _$MessagesLoadedImpl(
      {required this.chatId,
      required final List<ChatMessage> messages,
      final List<MessageUIState> uiMessages = const [],
      this.hasReachedMax = false,
      this.paginationError,
      this.dataSource = MessageDataSource.server,
      this.isBackgroundFetching = false,
      final List<ConversationMember> conversationMembers = const [],
      final List<String> frequentReactions = const <String>[
        '👍',
        '❤️',
        '😂',
        '😮',
        '😢',
        '😡'
      ],
      this.receiverId})
      : _messages = messages,
        _uiMessages = uiMessages,
        _conversationMembers = conversationMembers,
        _frequentReactions = frequentReactions,
        super._();

  @override
  final String chatId;
  final List<ChatMessage> _messages;
  @override
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  final List<MessageUIState> _uiMessages;
  @override
  @JsonKey()
  List<MessageUIState> get uiMessages {
    if (_uiMessages is EqualUnmodifiableListView) return _uiMessages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_uiMessages);
  }

  @override
  @JsonKey()
  final bool hasReachedMax;
  @override
  final String? paginationError;
// === Phase 2 + 3 fields ===
  /// Nguồn dữ liệu hiện tại (default: server — giữ backward compat Phase 1)
  @override
  @JsonKey()
  final MessageDataSource dataSource;

  /// Đang có background fetch chạy không
  @override
  @JsonKey()
  final bool isBackgroundFetching;

  /// Danh sách members từ ConversationDetailBloc (cho read receipts)
  final List<ConversationMember> _conversationMembers;

  /// Danh sách members từ ConversationDetailBloc (cho read receipts)
  @override
  @JsonKey()
  List<ConversationMember> get conversationMembers {
    if (_conversationMembers is EqualUnmodifiableListView)
      return _conversationMembers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conversationMembers);
  }

  /// Danh sách emoji reactions hay dùng nhất của user
  final List<String> _frequentReactions;

  /// Danh sách emoji reactions hay dùng nhất của user
  @override
  @JsonKey()
  List<String> get frequentReactions {
    if (_frequentReactions is EqualUnmodifiableListView)
      return _frequentReactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frequentReactions);
  }

  /// For pending direct chats — receiverId to auto-create conversation on first message
  @override
  final String? receiverId;

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
    required TResult Function(String chatId) loading,
    required TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)
        loaded,
    required TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)
        error,
  }) {
    return loaded(
        chatId,
        messages,
        uiMessages,
        hasReachedMax,
        paginationError,
        dataSource,
        isBackgroundFetching,
        conversationMembers,
        frequentReactions,
        receiverId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(String chatId)? loading,
    TResult? Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult? Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
  }) {
    return loaded?.call(
        chatId,
        messages,
        uiMessages,
        hasReachedMax,
        paginationError,
        dataSource,
        isBackgroundFetching,
        conversationMembers,
        frequentReactions,
        receiverId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String chatId)? loading,
    TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(
          chatId,
          messages,
          uiMessages,
          hasReachedMax,
          paginationError,
          dataSource,
          isBackgroundFetching,
          conversationMembers,
          frequentReactions,
          receiverId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageInitial value) initial,
    required TResult Function(MessagesLoading value) loading,
    required TResult Function(MessagesLoaded value) loaded,
    required TResult Function(MessagesError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageInitial value)? initial,
    TResult? Function(MessagesLoading value)? loading,
    TResult? Function(MessagesLoaded value)? loaded,
    TResult? Function(MessagesError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageInitial value)? initial,
    TResult Function(MessagesLoading value)? loading,
    TResult Function(MessagesLoaded value)? loaded,
    TResult Function(MessagesError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class MessagesLoaded extends MessageState {
  const factory MessagesLoaded(
      {required final String chatId,
      required final List<ChatMessage> messages,
      final List<MessageUIState> uiMessages,
      final bool hasReachedMax,
      final String? paginationError,
      final MessageDataSource dataSource,
      final bool isBackgroundFetching,
      final List<ConversationMember> conversationMembers,
      final List<String> frequentReactions,
      final String? receiverId}) = _$MessagesLoadedImpl;
  const MessagesLoaded._() : super._();

  String get chatId;
  List<ChatMessage> get messages;
  List<MessageUIState> get uiMessages;
  bool get hasReachedMax;
  String? get paginationError; // === Phase 2 + 3 fields ===
  /// Nguồn dữ liệu hiện tại (default: server — giữ backward compat Phase 1)
  MessageDataSource get dataSource;

  /// Đang có background fetch chạy không
  bool get isBackgroundFetching;

  /// Danh sách members từ ConversationDetailBloc (cho read receipts)
  List<ConversationMember> get conversationMembers;

  /// Danh sách emoji reactions hay dùng nhất của user
  List<String> get frequentReactions;

  /// For pending direct chats — receiverId to auto-create conversation on first message
  String? get receiverId;
  @JsonKey(ignore: true)
  _$$MessagesLoadedImplCopyWith<_$MessagesLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessagesErrorImplCopyWith<$Res> {
  factory _$$MessagesErrorImplCopyWith(
          _$MessagesErrorImpl value, $Res Function(_$MessagesErrorImpl) then) =
      __$$MessagesErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, String error, List<ChatMessage>? previousMessages});
}

/// @nodoc
class __$$MessagesErrorImplCopyWithImpl<$Res>
    extends _$MessageStateCopyWithImpl<$Res, _$MessagesErrorImpl>
    implements _$$MessagesErrorImplCopyWith<$Res> {
  __$$MessagesErrorImplCopyWithImpl(
      _$MessagesErrorImpl _value, $Res Function(_$MessagesErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? error = null,
    Object? previousMessages = freezed,
  }) {
    return _then(_$MessagesErrorImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      error: null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
      previousMessages: freezed == previousMessages
          ? _value._previousMessages
          : previousMessages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>?,
    ));
  }
}

/// @nodoc

class _$MessagesErrorImpl extends MessagesError {
  const _$MessagesErrorImpl(
      {required this.chatId,
      required this.error,
      final List<ChatMessage>? previousMessages})
      : _previousMessages = previousMessages,
        super._();

  @override
  final String chatId;
  @override
  final String error;

  /// Preserve previous messages for better UX
  final List<ChatMessage>? _previousMessages;

  /// Preserve previous messages for better UX
  @override
  List<ChatMessage>? get previousMessages {
    final value = _previousMessages;
    if (value == null) return null;
    if (_previousMessages is EqualUnmodifiableListView)
      return _previousMessages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MessagesErrorImplCopyWith<_$MessagesErrorImpl> get copyWith =>
      __$$MessagesErrorImplCopyWithImpl<_$MessagesErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(String chatId) loading,
    required TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)
        loaded,
    required TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)
        error,
  }) {
    return error(chatId, this.error, previousMessages);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(String chatId)? loading,
    TResult? Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult? Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
  }) {
    return error?.call(chatId, this.error, previousMessages);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(String chatId)? loading,
    TResult Function(
            String chatId,
            List<ChatMessage> messages,
            List<MessageUIState> uiMessages,
            bool hasReachedMax,
            String? paginationError,
            MessageDataSource dataSource,
            bool isBackgroundFetching,
            List<ConversationMember> conversationMembers,
            List<String> frequentReactions,
            String? receiverId)?
        loaded,
    TResult Function(
            String chatId, String error, List<ChatMessage>? previousMessages)?
        error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(chatId, this.error, previousMessages);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageInitial value) initial,
    required TResult Function(MessagesLoading value) loading,
    required TResult Function(MessagesLoaded value) loaded,
    required TResult Function(MessagesError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageInitial value)? initial,
    TResult? Function(MessagesLoading value)? loading,
    TResult? Function(MessagesLoaded value)? loaded,
    TResult? Function(MessagesError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageInitial value)? initial,
    TResult Function(MessagesLoading value)? loading,
    TResult Function(MessagesLoaded value)? loaded,
    TResult Function(MessagesError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class MessagesError extends MessageState {
  const factory MessagesError(
      {required final String chatId,
      required final String error,
      final List<ChatMessage>? previousMessages}) = _$MessagesErrorImpl;
  const MessagesError._() : super._();

  String get chatId;
  String get error;

  /// Preserve previous messages for better UX
  List<ChatMessage>? get previousMessages;
  @JsonKey(ignore: true)
  _$$MessagesErrorImplCopyWith<_$MessagesErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

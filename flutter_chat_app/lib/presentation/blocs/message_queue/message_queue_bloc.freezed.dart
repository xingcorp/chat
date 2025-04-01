// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_queue_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MessageQueueEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chatId, String content,
            ContentType contentType, List<Attachment> attachments)
        enqueueMessage,
    required TResult Function(String messageId) cancelMessage,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function() loadPendingMessages,
    required TResult Function() clearCompletedMessages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult? Function(String messageId)? cancelMessage,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function()? loadPendingMessages,
    TResult? Function()? clearCompletedMessages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult Function(String messageId)? cancelMessage,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function()? loadPendingMessages,
    TResult Function()? clearCompletedMessages,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EnqueueMessage value) enqueueMessage,
    required TResult Function(_CancelMessage value) cancelMessage,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_LoadPendingMessages value) loadPendingMessages,
    required TResult Function(_ClearCompletedMessages value)
        clearCompletedMessages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EnqueueMessage value)? enqueueMessage,
    TResult? Function(_CancelMessage value)? cancelMessage,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult? Function(_ClearCompletedMessages value)? clearCompletedMessages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EnqueueMessage value)? enqueueMessage,
    TResult Function(_CancelMessage value)? cancelMessage,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult Function(_ClearCompletedMessages value)? clearCompletedMessages,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageQueueEventCopyWith<$Res> {
  factory $MessageQueueEventCopyWith(
          MessageQueueEvent value, $Res Function(MessageQueueEvent) then) =
      _$MessageQueueEventCopyWithImpl<$Res, MessageQueueEvent>;
}

/// @nodoc
class _$MessageQueueEventCopyWithImpl<$Res, $Val extends MessageQueueEvent>
    implements $MessageQueueEventCopyWith<$Res> {
  _$MessageQueueEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$EnqueueMessageImplCopyWith<$Res> {
  factory _$$EnqueueMessageImplCopyWith(_$EnqueueMessageImpl value,
          $Res Function(_$EnqueueMessageImpl) then) =
      __$$EnqueueMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {String chatId,
      String content,
      ContentType contentType,
      List<Attachment> attachments});
}

/// @nodoc
class __$$EnqueueMessageImplCopyWithImpl<$Res>
    extends _$MessageQueueEventCopyWithImpl<$Res, _$EnqueueMessageImpl>
    implements _$$EnqueueMessageImplCopyWith<$Res> {
  __$$EnqueueMessageImplCopyWithImpl(
      _$EnqueueMessageImpl _value, $Res Function(_$EnqueueMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? content = null,
    Object? contentType = null,
    Object? attachments = null,
  }) {
    return _then(_$EnqueueMessageImpl(
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
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Attachment>,
    ));
  }
}

/// @nodoc

class _$EnqueueMessageImpl implements _EnqueueMessage {
  const _$EnqueueMessageImpl(
      {required this.chatId,
      required this.content,
      required this.contentType,
      final List<Attachment> attachments = const []})
      : _attachments = attachments;

  @override
  final String chatId;
  @override
  final String content;
  @override
  final ContentType contentType;
  final List<Attachment> _attachments;
  @override
  @JsonKey()
  List<Attachment> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  String toString() {
    return 'MessageQueueEvent.enqueueMessage(chatId: $chatId, content: $content, contentType: $contentType, attachments: $attachments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnqueueMessageImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId, content, contentType,
      const DeepCollectionEquality().hash(_attachments));

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnqueueMessageImplCopyWith<_$EnqueueMessageImpl> get copyWith =>
      __$$EnqueueMessageImplCopyWithImpl<_$EnqueueMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chatId, String content,
            ContentType contentType, List<Attachment> attachments)
        enqueueMessage,
    required TResult Function(String messageId) cancelMessage,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function() loadPendingMessages,
    required TResult Function() clearCompletedMessages,
  }) {
    return enqueueMessage(chatId, content, contentType, attachments);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult? Function(String messageId)? cancelMessage,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function()? loadPendingMessages,
    TResult? Function()? clearCompletedMessages,
  }) {
    return enqueueMessage?.call(chatId, content, contentType, attachments);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult Function(String messageId)? cancelMessage,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function()? loadPendingMessages,
    TResult Function()? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (enqueueMessage != null) {
      return enqueueMessage(chatId, content, contentType, attachments);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EnqueueMessage value) enqueueMessage,
    required TResult Function(_CancelMessage value) cancelMessage,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_LoadPendingMessages value) loadPendingMessages,
    required TResult Function(_ClearCompletedMessages value)
        clearCompletedMessages,
  }) {
    return enqueueMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EnqueueMessage value)? enqueueMessage,
    TResult? Function(_CancelMessage value)? cancelMessage,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult? Function(_ClearCompletedMessages value)? clearCompletedMessages,
  }) {
    return enqueueMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EnqueueMessage value)? enqueueMessage,
    TResult Function(_CancelMessage value)? cancelMessage,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult Function(_ClearCompletedMessages value)? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (enqueueMessage != null) {
      return enqueueMessage(this);
    }
    return orElse();
  }
}

abstract class _EnqueueMessage implements MessageQueueEvent {
  const factory _EnqueueMessage(
      {required final String chatId,
      required final String content,
      required final ContentType contentType,
      final List<Attachment> attachments}) = _$EnqueueMessageImpl;

  String get chatId;
  String get content;
  ContentType get contentType;
  List<Attachment> get attachments;

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnqueueMessageImplCopyWith<_$EnqueueMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CancelMessageImplCopyWith<$Res> {
  factory _$$CancelMessageImplCopyWith(
          _$CancelMessageImpl value, $Res Function(_$CancelMessageImpl) then) =
      __$$CancelMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String messageId});
}

/// @nodoc
class __$$CancelMessageImplCopyWithImpl<$Res>
    extends _$MessageQueueEventCopyWithImpl<$Res, _$CancelMessageImpl>
    implements _$$CancelMessageImplCopyWith<$Res> {
  __$$CancelMessageImplCopyWithImpl(
      _$CancelMessageImpl _value, $Res Function(_$CancelMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
  }) {
    return _then(_$CancelMessageImpl(
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$CancelMessageImpl implements _CancelMessage {
  const _$CancelMessageImpl({required this.messageId});

  @override
  final String messageId;

  @override
  String toString() {
    return 'MessageQueueEvent.cancelMessage(messageId: $messageId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CancelMessageImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, messageId);

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CancelMessageImplCopyWith<_$CancelMessageImpl> get copyWith =>
      __$$CancelMessageImplCopyWithImpl<_$CancelMessageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chatId, String content,
            ContentType contentType, List<Attachment> attachments)
        enqueueMessage,
    required TResult Function(String messageId) cancelMessage,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function() loadPendingMessages,
    required TResult Function() clearCompletedMessages,
  }) {
    return cancelMessage(messageId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult? Function(String messageId)? cancelMessage,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function()? loadPendingMessages,
    TResult? Function()? clearCompletedMessages,
  }) {
    return cancelMessage?.call(messageId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult Function(String messageId)? cancelMessage,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function()? loadPendingMessages,
    TResult Function()? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (cancelMessage != null) {
      return cancelMessage(messageId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EnqueueMessage value) enqueueMessage,
    required TResult Function(_CancelMessage value) cancelMessage,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_LoadPendingMessages value) loadPendingMessages,
    required TResult Function(_ClearCompletedMessages value)
        clearCompletedMessages,
  }) {
    return cancelMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EnqueueMessage value)? enqueueMessage,
    TResult? Function(_CancelMessage value)? cancelMessage,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult? Function(_ClearCompletedMessages value)? clearCompletedMessages,
  }) {
    return cancelMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EnqueueMessage value)? enqueueMessage,
    TResult Function(_CancelMessage value)? cancelMessage,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult Function(_ClearCompletedMessages value)? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (cancelMessage != null) {
      return cancelMessage(this);
    }
    return orElse();
  }
}

abstract class _CancelMessage implements MessageQueueEvent {
  const factory _CancelMessage({required final String messageId}) =
      _$CancelMessageImpl;

  String get messageId;

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CancelMessageImplCopyWith<_$CancelMessageImpl> get copyWith =>
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
    extends _$MessageQueueEventCopyWithImpl<$Res, _$MessageStatusUpdatedImpl>
    implements _$$MessageStatusUpdatedImplCopyWith<$Res> {
  __$$MessageStatusUpdatedImplCopyWithImpl(_$MessageStatusUpdatedImpl _value,
      $Res Function(_$MessageStatusUpdatedImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$MessageStatusUpdatedImpl(
      freezed == message
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
    return 'MessageQueueEvent.messageStatusUpdated(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageStatusUpdatedImpl &&
            const DeepCollectionEquality().equals(other.message, message));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(message));

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageStatusUpdatedImplCopyWith<_$MessageStatusUpdatedImpl>
      get copyWith =>
          __$$MessageStatusUpdatedImplCopyWithImpl<_$MessageStatusUpdatedImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chatId, String content,
            ContentType contentType, List<Attachment> attachments)
        enqueueMessage,
    required TResult Function(String messageId) cancelMessage,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function() loadPendingMessages,
    required TResult Function() clearCompletedMessages,
  }) {
    return messageStatusUpdated(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult? Function(String messageId)? cancelMessage,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function()? loadPendingMessages,
    TResult? Function()? clearCompletedMessages,
  }) {
    return messageStatusUpdated?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult Function(String messageId)? cancelMessage,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function()? loadPendingMessages,
    TResult Function()? clearCompletedMessages,
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
    required TResult Function(_EnqueueMessage value) enqueueMessage,
    required TResult Function(_CancelMessage value) cancelMessage,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_LoadPendingMessages value) loadPendingMessages,
    required TResult Function(_ClearCompletedMessages value)
        clearCompletedMessages,
  }) {
    return messageStatusUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EnqueueMessage value)? enqueueMessage,
    TResult? Function(_CancelMessage value)? cancelMessage,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult? Function(_ClearCompletedMessages value)? clearCompletedMessages,
  }) {
    return messageStatusUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EnqueueMessage value)? enqueueMessage,
    TResult Function(_CancelMessage value)? cancelMessage,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult Function(_ClearCompletedMessages value)? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (messageStatusUpdated != null) {
      return messageStatusUpdated(this);
    }
    return orElse();
  }
}

abstract class _MessageStatusUpdated implements MessageQueueEvent {
  const factory _MessageStatusUpdated(final QueuedMessage message) =
      _$MessageStatusUpdatedImpl;

  QueuedMessage get message;

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageStatusUpdatedImplCopyWith<_$MessageStatusUpdatedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadPendingMessagesImplCopyWith<$Res> {
  factory _$$LoadPendingMessagesImplCopyWith(_$LoadPendingMessagesImpl value,
          $Res Function(_$LoadPendingMessagesImpl) then) =
      __$$LoadPendingMessagesImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadPendingMessagesImplCopyWithImpl<$Res>
    extends _$MessageQueueEventCopyWithImpl<$Res, _$LoadPendingMessagesImpl>
    implements _$$LoadPendingMessagesImplCopyWith<$Res> {
  __$$LoadPendingMessagesImplCopyWithImpl(_$LoadPendingMessagesImpl _value,
      $Res Function(_$LoadPendingMessagesImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadPendingMessagesImpl implements _LoadPendingMessages {
  const _$LoadPendingMessagesImpl();

  @override
  String toString() {
    return 'MessageQueueEvent.loadPendingMessages()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadPendingMessagesImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chatId, String content,
            ContentType contentType, List<Attachment> attachments)
        enqueueMessage,
    required TResult Function(String messageId) cancelMessage,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function() loadPendingMessages,
    required TResult Function() clearCompletedMessages,
  }) {
    return loadPendingMessages();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult? Function(String messageId)? cancelMessage,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function()? loadPendingMessages,
    TResult? Function()? clearCompletedMessages,
  }) {
    return loadPendingMessages?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult Function(String messageId)? cancelMessage,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function()? loadPendingMessages,
    TResult Function()? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (loadPendingMessages != null) {
      return loadPendingMessages();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EnqueueMessage value) enqueueMessage,
    required TResult Function(_CancelMessage value) cancelMessage,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_LoadPendingMessages value) loadPendingMessages,
    required TResult Function(_ClearCompletedMessages value)
        clearCompletedMessages,
  }) {
    return loadPendingMessages(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EnqueueMessage value)? enqueueMessage,
    TResult? Function(_CancelMessage value)? cancelMessage,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult? Function(_ClearCompletedMessages value)? clearCompletedMessages,
  }) {
    return loadPendingMessages?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EnqueueMessage value)? enqueueMessage,
    TResult Function(_CancelMessage value)? cancelMessage,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult Function(_ClearCompletedMessages value)? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (loadPendingMessages != null) {
      return loadPendingMessages(this);
    }
    return orElse();
  }
}

abstract class _LoadPendingMessages implements MessageQueueEvent {
  const factory _LoadPendingMessages() = _$LoadPendingMessagesImpl;
}

/// @nodoc
abstract class _$$ClearCompletedMessagesImplCopyWith<$Res> {
  factory _$$ClearCompletedMessagesImplCopyWith(
          _$ClearCompletedMessagesImpl value,
          $Res Function(_$ClearCompletedMessagesImpl) then) =
      __$$ClearCompletedMessagesImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ClearCompletedMessagesImplCopyWithImpl<$Res>
    extends _$MessageQueueEventCopyWithImpl<$Res, _$ClearCompletedMessagesImpl>
    implements _$$ClearCompletedMessagesImplCopyWith<$Res> {
  __$$ClearCompletedMessagesImplCopyWithImpl(
      _$ClearCompletedMessagesImpl _value,
      $Res Function(_$ClearCompletedMessagesImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ClearCompletedMessagesImpl implements _ClearCompletedMessages {
  const _$ClearCompletedMessagesImpl();

  @override
  String toString() {
    return 'MessageQueueEvent.clearCompletedMessages()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClearCompletedMessagesImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chatId, String content,
            ContentType contentType, List<Attachment> attachments)
        enqueueMessage,
    required TResult Function(String messageId) cancelMessage,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function() loadPendingMessages,
    required TResult Function() clearCompletedMessages,
  }) {
    return clearCompletedMessages();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult? Function(String messageId)? cancelMessage,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function()? loadPendingMessages,
    TResult? Function()? clearCompletedMessages,
  }) {
    return clearCompletedMessages?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chatId, String content, ContentType contentType,
            List<Attachment> attachments)?
        enqueueMessage,
    TResult Function(String messageId)? cancelMessage,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function()? loadPendingMessages,
    TResult Function()? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (clearCompletedMessages != null) {
      return clearCompletedMessages();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EnqueueMessage value) enqueueMessage,
    required TResult Function(_CancelMessage value) cancelMessage,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_LoadPendingMessages value) loadPendingMessages,
    required TResult Function(_ClearCompletedMessages value)
        clearCompletedMessages,
  }) {
    return clearCompletedMessages(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EnqueueMessage value)? enqueueMessage,
    TResult? Function(_CancelMessage value)? cancelMessage,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult? Function(_ClearCompletedMessages value)? clearCompletedMessages,
  }) {
    return clearCompletedMessages?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EnqueueMessage value)? enqueueMessage,
    TResult Function(_CancelMessage value)? cancelMessage,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_LoadPendingMessages value)? loadPendingMessages,
    TResult Function(_ClearCompletedMessages value)? clearCompletedMessages,
    required TResult orElse(),
  }) {
    if (clearCompletedMessages != null) {
      return clearCompletedMessages(this);
    }
    return orElse();
  }
}

abstract class _ClearCompletedMessages implements MessageQueueEvent {
  const factory _ClearCompletedMessages() = _$ClearCompletedMessagesImpl;
}

/// @nodoc
mixin _$MessageQueueState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageQueueStateCopyWith<$Res> {
  factory $MessageQueueStateCopyWith(
          MessageQueueState value, $Res Function(MessageQueueState) then) =
      _$MessageQueueStateCopyWithImpl<$Res, MessageQueueState>;
}

/// @nodoc
class _$MessageQueueStateCopyWithImpl<$Res, $Val extends MessageQueueState>
    implements $MessageQueueStateCopyWith<$Res> {
  _$MessageQueueStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$MessageQueueStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'MessageQueueState.initial()';
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
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
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
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements MessageQueueState {
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
    extends _$MessageQueueStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
      _$LoadingImpl _value, $Res Function(_$LoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'MessageQueueState.loading()';
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
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
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
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements MessageQueueState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$MessageEnqueuedImplCopyWith<$Res> {
  factory _$$MessageEnqueuedImplCopyWith(_$MessageEnqueuedImpl value,
          $Res Function(_$MessageEnqueuedImpl) then) =
      __$$MessageEnqueuedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({QueuedMessage message});
}

/// @nodoc
class __$$MessageEnqueuedImplCopyWithImpl<$Res>
    extends _$MessageQueueStateCopyWithImpl<$Res, _$MessageEnqueuedImpl>
    implements _$$MessageEnqueuedImplCopyWith<$Res> {
  __$$MessageEnqueuedImplCopyWithImpl(
      _$MessageEnqueuedImpl _value, $Res Function(_$MessageEnqueuedImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$MessageEnqueuedImpl(
      freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as QueuedMessage,
    ));
  }
}

/// @nodoc

class _$MessageEnqueuedImpl implements _MessageEnqueued {
  const _$MessageEnqueuedImpl(this.message);

  @override
  final QueuedMessage message;

  @override
  String toString() {
    return 'MessageQueueState.messageEnqueued(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageEnqueuedImpl &&
            const DeepCollectionEquality().equals(other.message, message));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(message));

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageEnqueuedImplCopyWith<_$MessageEnqueuedImpl> get copyWith =>
      __$$MessageEnqueuedImplCopyWithImpl<_$MessageEnqueuedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return messageEnqueued(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return messageEnqueued?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (messageEnqueued != null) {
      return messageEnqueued(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return messageEnqueued(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return messageEnqueued?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (messageEnqueued != null) {
      return messageEnqueued(this);
    }
    return orElse();
  }
}

abstract class _MessageEnqueued implements MessageQueueState {
  const factory _MessageEnqueued(final QueuedMessage message) =
      _$MessageEnqueuedImpl;

  QueuedMessage get message;

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageEnqueuedImplCopyWith<_$MessageEnqueuedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessageCancelledImplCopyWith<$Res> {
  factory _$$MessageCancelledImplCopyWith(_$MessageCancelledImpl value,
          $Res Function(_$MessageCancelledImpl) then) =
      __$$MessageCancelledImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String messageId});
}

/// @nodoc
class __$$MessageCancelledImplCopyWithImpl<$Res>
    extends _$MessageQueueStateCopyWithImpl<$Res, _$MessageCancelledImpl>
    implements _$$MessageCancelledImplCopyWith<$Res> {
  __$$MessageCancelledImplCopyWithImpl(_$MessageCancelledImpl _value,
      $Res Function(_$MessageCancelledImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
  }) {
    return _then(_$MessageCancelledImpl(
      null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MessageCancelledImpl implements _MessageCancelled {
  const _$MessageCancelledImpl(this.messageId);

  @override
  final String messageId;

  @override
  String toString() {
    return 'MessageQueueState.messageCancelled(messageId: $messageId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageCancelledImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, messageId);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageCancelledImplCopyWith<_$MessageCancelledImpl> get copyWith =>
      __$$MessageCancelledImplCopyWithImpl<_$MessageCancelledImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return messageCancelled(messageId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return messageCancelled?.call(messageId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (messageCancelled != null) {
      return messageCancelled(messageId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return messageCancelled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return messageCancelled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (messageCancelled != null) {
      return messageCancelled(this);
    }
    return orElse();
  }
}

abstract class _MessageCancelled implements MessageQueueState {
  const factory _MessageCancelled(final String messageId) =
      _$MessageCancelledImpl;

  String get messageId;

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageCancelledImplCopyWith<_$MessageCancelledImpl> get copyWith =>
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
    extends _$MessageQueueStateCopyWithImpl<$Res, _$MessageStatusUpdatedImpl>
    implements _$$MessageStatusUpdatedImplCopyWith<$Res> {
  __$$MessageStatusUpdatedImplCopyWithImpl(_$MessageStatusUpdatedImpl _value,
      $Res Function(_$MessageStatusUpdatedImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$MessageStatusUpdatedImpl(
      freezed == message
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
    return 'MessageQueueState.messageStatusUpdated(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageStatusUpdatedImpl &&
            const DeepCollectionEquality().equals(other.message, message));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(message));

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageStatusUpdatedImplCopyWith<_$MessageStatusUpdatedImpl>
      get copyWith =>
          __$$MessageStatusUpdatedImplCopyWithImpl<_$MessageStatusUpdatedImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return messageStatusUpdated(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return messageStatusUpdated?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
    TResult Function(String message)? error,
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
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return messageStatusUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return messageStatusUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (messageStatusUpdated != null) {
      return messageStatusUpdated(this);
    }
    return orElse();
  }
}

abstract class _MessageStatusUpdated implements MessageQueueState {
  const factory _MessageStatusUpdated(final QueuedMessage message) =
      _$MessageStatusUpdatedImpl;

  QueuedMessage get message;

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageStatusUpdatedImplCopyWith<_$MessageStatusUpdatedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PendingMessagesLoadedImplCopyWith<$Res> {
  factory _$$PendingMessagesLoadedImplCopyWith(
          _$PendingMessagesLoadedImpl value,
          $Res Function(_$PendingMessagesLoadedImpl) then) =
      __$$PendingMessagesLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<QueuedMessage> messages});
}

/// @nodoc
class __$$PendingMessagesLoadedImplCopyWithImpl<$Res>
    extends _$MessageQueueStateCopyWithImpl<$Res, _$PendingMessagesLoadedImpl>
    implements _$$PendingMessagesLoadedImplCopyWith<$Res> {
  __$$PendingMessagesLoadedImplCopyWithImpl(_$PendingMessagesLoadedImpl _value,
      $Res Function(_$PendingMessagesLoadedImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
  }) {
    return _then(_$PendingMessagesLoadedImpl(
      null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<QueuedMessage>,
    ));
  }
}

/// @nodoc

class _$PendingMessagesLoadedImpl implements _PendingMessagesLoaded {
  const _$PendingMessagesLoadedImpl(final List<QueuedMessage> messages)
      : _messages = messages;

  final List<QueuedMessage> _messages;
  @override
  List<QueuedMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'MessageQueueState.pendingMessagesLoaded(messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PendingMessagesLoadedImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_messages));

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PendingMessagesLoadedImplCopyWith<_$PendingMessagesLoadedImpl>
      get copyWith => __$$PendingMessagesLoadedImplCopyWithImpl<
          _$PendingMessagesLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return pendingMessagesLoaded(messages);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return pendingMessagesLoaded?.call(messages);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (pendingMessagesLoaded != null) {
      return pendingMessagesLoaded(messages);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return pendingMessagesLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return pendingMessagesLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (pendingMessagesLoaded != null) {
      return pendingMessagesLoaded(this);
    }
    return orElse();
  }
}

abstract class _PendingMessagesLoaded implements MessageQueueState {
  const factory _PendingMessagesLoaded(final List<QueuedMessage> messages) =
      _$PendingMessagesLoadedImpl;

  List<QueuedMessage> get messages;

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PendingMessagesLoadedImplCopyWith<_$PendingMessagesLoadedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompletedMessagesClearedImplCopyWith<$Res> {
  factory _$$CompletedMessagesClearedImplCopyWith(
          _$CompletedMessagesClearedImpl value,
          $Res Function(_$CompletedMessagesClearedImpl) then) =
      __$$CompletedMessagesClearedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CompletedMessagesClearedImplCopyWithImpl<$Res>
    extends _$MessageQueueStateCopyWithImpl<$Res,
        _$CompletedMessagesClearedImpl>
    implements _$$CompletedMessagesClearedImplCopyWith<$Res> {
  __$$CompletedMessagesClearedImplCopyWithImpl(
      _$CompletedMessagesClearedImpl _value,
      $Res Function(_$CompletedMessagesClearedImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$CompletedMessagesClearedImpl implements _CompletedMessagesCleared {
  const _$CompletedMessagesClearedImpl();

  @override
  String toString() {
    return 'MessageQueueState.completedMessagesCleared()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletedMessagesClearedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return completedMessagesCleared();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return completedMessagesCleared?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completedMessagesCleared != null) {
      return completedMessagesCleared();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return completedMessagesCleared(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return completedMessagesCleared?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (completedMessagesCleared != null) {
      return completedMessagesCleared(this);
    }
    return orElse();
  }
}

abstract class _CompletedMessagesCleared implements MessageQueueState {
  const factory _CompletedMessagesCleared() = _$CompletedMessagesClearedImpl;
}

/// @nodoc
abstract class _$$NoChangeImplCopyWith<$Res> {
  factory _$$NoChangeImplCopyWith(
          _$NoChangeImpl value, $Res Function(_$NoChangeImpl) then) =
      __$$NoChangeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NoChangeImplCopyWithImpl<$Res>
    extends _$MessageQueueStateCopyWithImpl<$Res, _$NoChangeImpl>
    implements _$$NoChangeImplCopyWith<$Res> {
  __$$NoChangeImplCopyWithImpl(
      _$NoChangeImpl _value, $Res Function(_$NoChangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NoChangeImpl implements _NoChange {
  const _$NoChangeImpl();

  @override
  String toString() {
    return 'MessageQueueState.noChange()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NoChangeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return noChange();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return noChange?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (noChange != null) {
      return noChange();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return noChange(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return noChange?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (noChange != null) {
      return noChange(this);
    }
    return orElse();
  }
}

abstract class _NoChange implements MessageQueueState {
  const factory _NoChange() = _$NoChangeImpl;
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
    extends _$MessageQueueStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'MessageQueueState.error(message: $message)';
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

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(QueuedMessage message) messageEnqueued,
    required TResult Function(String messageId) messageCancelled,
    required TResult Function(QueuedMessage message) messageStatusUpdated,
    required TResult Function(List<QueuedMessage> messages)
        pendingMessagesLoaded,
    required TResult Function() completedMessagesCleared,
    required TResult Function() noChange,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(QueuedMessage message)? messageEnqueued,
    TResult? Function(String messageId)? messageCancelled,
    TResult? Function(QueuedMessage message)? messageStatusUpdated,
    TResult? Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult? Function()? completedMessagesCleared,
    TResult? Function()? noChange,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(QueuedMessage message)? messageEnqueued,
    TResult Function(String messageId)? messageCancelled,
    TResult Function(QueuedMessage message)? messageStatusUpdated,
    TResult Function(List<QueuedMessage> messages)? pendingMessagesLoaded,
    TResult Function()? completedMessagesCleared,
    TResult Function()? noChange,
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
    required TResult Function(_MessageEnqueued value) messageEnqueued,
    required TResult Function(_MessageCancelled value) messageCancelled,
    required TResult Function(_MessageStatusUpdated value) messageStatusUpdated,
    required TResult Function(_PendingMessagesLoaded value)
        pendingMessagesLoaded,
    required TResult Function(_CompletedMessagesCleared value)
        completedMessagesCleared,
    required TResult Function(_NoChange value) noChange,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_MessageEnqueued value)? messageEnqueued,
    TResult? Function(_MessageCancelled value)? messageCancelled,
    TResult? Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult? Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult? Function(_CompletedMessagesCleared value)?
        completedMessagesCleared,
    TResult? Function(_NoChange value)? noChange,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_MessageEnqueued value)? messageEnqueued,
    TResult Function(_MessageCancelled value)? messageCancelled,
    TResult Function(_MessageStatusUpdated value)? messageStatusUpdated,
    TResult Function(_PendingMessagesLoaded value)? pendingMessagesLoaded,
    TResult Function(_CompletedMessagesCleared value)? completedMessagesCleared,
    TResult Function(_NoChange value)? noChange,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements MessageQueueState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of MessageQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

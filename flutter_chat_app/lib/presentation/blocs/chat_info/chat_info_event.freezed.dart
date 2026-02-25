// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_info_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatInfoEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatInfoEventCopyWith<$Res> {
  factory $ChatInfoEventCopyWith(
          ChatInfoEvent value, $Res Function(ChatInfoEvent) then) =
      _$ChatInfoEventCopyWithImpl<$Res, ChatInfoEvent>;
}

/// @nodoc
class _$ChatInfoEventCopyWithImpl<$Res, $Val extends ChatInfoEvent>
    implements $ChatInfoEventCopyWith<$Res> {
  _$ChatInfoEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$ChatInfoLoadSharedMediaImplCopyWith<$Res> {
  factory _$$ChatInfoLoadSharedMediaImplCopyWith(
          _$ChatInfoLoadSharedMediaImpl value,
          $Res Function(_$ChatInfoLoadSharedMediaImpl) then) =
      __$$ChatInfoLoadSharedMediaImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, SharedMediaType type, int? limit, int? offset});
}

/// @nodoc
class __$$ChatInfoLoadSharedMediaImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res, _$ChatInfoLoadSharedMediaImpl>
    implements _$$ChatInfoLoadSharedMediaImplCopyWith<$Res> {
  __$$ChatInfoLoadSharedMediaImplCopyWithImpl(
      _$ChatInfoLoadSharedMediaImpl _value,
      $Res Function(_$ChatInfoLoadSharedMediaImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? type = null,
    Object? limit = freezed,
    Object? offset = freezed,
  }) {
    return _then(_$ChatInfoLoadSharedMediaImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SharedMediaType,
      limit: freezed == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
      offset: freezed == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$ChatInfoLoadSharedMediaImpl implements ChatInfoLoadSharedMedia {
  const _$ChatInfoLoadSharedMediaImpl(
      {required this.chatId, required this.type, this.limit, this.offset});

  @override
  final String chatId;
  @override
  final SharedMediaType type;
  @override
  final int? limit;
  @override
  final int? offset;

  @override
  String toString() {
    return 'ChatInfoEvent.loadSharedMedia(chatId: $chatId, type: $type, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoLoadSharedMediaImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId, type, limit, offset);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoLoadSharedMediaImplCopyWith<_$ChatInfoLoadSharedMediaImpl>
      get copyWith => __$$ChatInfoLoadSharedMediaImplCopyWithImpl<
          _$ChatInfoLoadSharedMediaImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return loadSharedMedia(chatId, type, limit, offset);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return loadSharedMedia?.call(chatId, type, limit, offset);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (loadSharedMedia != null) {
      return loadSharedMedia(chatId, type, limit, offset);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return loadSharedMedia(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return loadSharedMedia?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (loadSharedMedia != null) {
      return loadSharedMedia(this);
    }
    return orElse();
  }
}

abstract class ChatInfoLoadSharedMedia implements ChatInfoEvent {
  const factory ChatInfoLoadSharedMedia(
      {required final String chatId,
      required final SharedMediaType type,
      final int? limit,
      final int? offset}) = _$ChatInfoLoadSharedMediaImpl;

  String get chatId;
  SharedMediaType get type;
  int? get limit;
  int? get offset;
  @JsonKey(ignore: true)
  _$$ChatInfoLoadSharedMediaImplCopyWith<_$ChatInfoLoadSharedMediaImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatInfoLoadNotificationSettingsImplCopyWith<$Res> {
  factory _$$ChatInfoLoadNotificationSettingsImplCopyWith(
          _$ChatInfoLoadNotificationSettingsImpl value,
          $Res Function(_$ChatInfoLoadNotificationSettingsImpl) then) =
      __$$ChatInfoLoadNotificationSettingsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId});
}

/// @nodoc
class __$$ChatInfoLoadNotificationSettingsImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res,
        _$ChatInfoLoadNotificationSettingsImpl>
    implements _$$ChatInfoLoadNotificationSettingsImplCopyWith<$Res> {
  __$$ChatInfoLoadNotificationSettingsImplCopyWithImpl(
      _$ChatInfoLoadNotificationSettingsImpl _value,
      $Res Function(_$ChatInfoLoadNotificationSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
  }) {
    return _then(_$ChatInfoLoadNotificationSettingsImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatInfoLoadNotificationSettingsImpl
    implements ChatInfoLoadNotificationSettings {
  const _$ChatInfoLoadNotificationSettingsImpl({required this.chatId});

  @override
  final String chatId;

  @override
  String toString() {
    return 'ChatInfoEvent.loadNotificationSettings(chatId: $chatId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoLoadNotificationSettingsImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoLoadNotificationSettingsImplCopyWith<
          _$ChatInfoLoadNotificationSettingsImpl>
      get copyWith => __$$ChatInfoLoadNotificationSettingsImplCopyWithImpl<
          _$ChatInfoLoadNotificationSettingsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return loadNotificationSettings(chatId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return loadNotificationSettings?.call(chatId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (loadNotificationSettings != null) {
      return loadNotificationSettings(chatId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return loadNotificationSettings(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return loadNotificationSettings?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (loadNotificationSettings != null) {
      return loadNotificationSettings(this);
    }
    return orElse();
  }
}

abstract class ChatInfoLoadNotificationSettings implements ChatInfoEvent {
  const factory ChatInfoLoadNotificationSettings(
      {required final String chatId}) = _$ChatInfoLoadNotificationSettingsImpl;

  String get chatId;
  @JsonKey(ignore: true)
  _$$ChatInfoLoadNotificationSettingsImplCopyWith<
          _$ChatInfoLoadNotificationSettingsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatInfoUpdateNotificationSettingsImplCopyWith<$Res> {
  factory _$$ChatInfoUpdateNotificationSettingsImplCopyWith(
          _$ChatInfoUpdateNotificationSettingsImpl value,
          $Res Function(_$ChatInfoUpdateNotificationSettingsImpl) then) =
      __$$ChatInfoUpdateNotificationSettingsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({NotificationSettings settings});
}

/// @nodoc
class __$$ChatInfoUpdateNotificationSettingsImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res,
        _$ChatInfoUpdateNotificationSettingsImpl>
    implements _$$ChatInfoUpdateNotificationSettingsImplCopyWith<$Res> {
  __$$ChatInfoUpdateNotificationSettingsImplCopyWithImpl(
      _$ChatInfoUpdateNotificationSettingsImpl _value,
      $Res Function(_$ChatInfoUpdateNotificationSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? settings = null,
  }) {
    return _then(_$ChatInfoUpdateNotificationSettingsImpl(
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as NotificationSettings,
    ));
  }
}

/// @nodoc

class _$ChatInfoUpdateNotificationSettingsImpl
    implements ChatInfoUpdateNotificationSettings {
  const _$ChatInfoUpdateNotificationSettingsImpl({required this.settings});

  @override
  final NotificationSettings settings;

  @override
  String toString() {
    return 'ChatInfoEvent.updateNotificationSettings(settings: $settings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoUpdateNotificationSettingsImpl &&
            (identical(other.settings, settings) ||
                other.settings == settings));
  }

  @override
  int get hashCode => Object.hash(runtimeType, settings);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoUpdateNotificationSettingsImplCopyWith<
          _$ChatInfoUpdateNotificationSettingsImpl>
      get copyWith => __$$ChatInfoUpdateNotificationSettingsImplCopyWithImpl<
          _$ChatInfoUpdateNotificationSettingsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return updateNotificationSettings(settings);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return updateNotificationSettings?.call(settings);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (updateNotificationSettings != null) {
      return updateNotificationSettings(settings);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return updateNotificationSettings(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return updateNotificationSettings?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (updateNotificationSettings != null) {
      return updateNotificationSettings(this);
    }
    return orElse();
  }
}

abstract class ChatInfoUpdateNotificationSettings implements ChatInfoEvent {
  const factory ChatInfoUpdateNotificationSettings(
          {required final NotificationSettings settings}) =
      _$ChatInfoUpdateNotificationSettingsImpl;

  NotificationSettings get settings;
  @JsonKey(ignore: true)
  _$$ChatInfoUpdateNotificationSettingsImplCopyWith<
          _$ChatInfoUpdateNotificationSettingsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatInfoMuteNotificationsImplCopyWith<$Res> {
  factory _$$ChatInfoMuteNotificationsImplCopyWith(
          _$ChatInfoMuteNotificationsImpl value,
          $Res Function(_$ChatInfoMuteNotificationsImpl) then) =
      __$$ChatInfoMuteNotificationsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, MuteDuration duration});
}

/// @nodoc
class __$$ChatInfoMuteNotificationsImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res, _$ChatInfoMuteNotificationsImpl>
    implements _$$ChatInfoMuteNotificationsImplCopyWith<$Res> {
  __$$ChatInfoMuteNotificationsImplCopyWithImpl(
      _$ChatInfoMuteNotificationsImpl _value,
      $Res Function(_$ChatInfoMuteNotificationsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? duration = null,
  }) {
    return _then(_$ChatInfoMuteNotificationsImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as MuteDuration,
    ));
  }
}

/// @nodoc

class _$ChatInfoMuteNotificationsImpl implements ChatInfoMuteNotifications {
  const _$ChatInfoMuteNotificationsImpl(
      {required this.chatId, required this.duration});

  @override
  final String chatId;
  @override
  final MuteDuration duration;

  @override
  String toString() {
    return 'ChatInfoEvent.muteNotifications(chatId: $chatId, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoMuteNotificationsImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.duration, duration) ||
                other.duration == duration));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId, duration);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoMuteNotificationsImplCopyWith<_$ChatInfoMuteNotificationsImpl>
      get copyWith => __$$ChatInfoMuteNotificationsImplCopyWithImpl<
          _$ChatInfoMuteNotificationsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return muteNotifications(chatId, duration);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return muteNotifications?.call(chatId, duration);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (muteNotifications != null) {
      return muteNotifications(chatId, duration);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return muteNotifications(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return muteNotifications?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (muteNotifications != null) {
      return muteNotifications(this);
    }
    return orElse();
  }
}

abstract class ChatInfoMuteNotifications implements ChatInfoEvent {
  const factory ChatInfoMuteNotifications(
      {required final String chatId,
      required final MuteDuration duration}) = _$ChatInfoMuteNotificationsImpl;

  String get chatId;
  MuteDuration get duration;
  @JsonKey(ignore: true)
  _$$ChatInfoMuteNotificationsImplCopyWith<_$ChatInfoMuteNotificationsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatInfoUnmuteNotificationsImplCopyWith<$Res> {
  factory _$$ChatInfoUnmuteNotificationsImplCopyWith(
          _$ChatInfoUnmuteNotificationsImpl value,
          $Res Function(_$ChatInfoUnmuteNotificationsImpl) then) =
      __$$ChatInfoUnmuteNotificationsImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId});
}

/// @nodoc
class __$$ChatInfoUnmuteNotificationsImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res, _$ChatInfoUnmuteNotificationsImpl>
    implements _$$ChatInfoUnmuteNotificationsImplCopyWith<$Res> {
  __$$ChatInfoUnmuteNotificationsImplCopyWithImpl(
      _$ChatInfoUnmuteNotificationsImpl _value,
      $Res Function(_$ChatInfoUnmuteNotificationsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
  }) {
    return _then(_$ChatInfoUnmuteNotificationsImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatInfoUnmuteNotificationsImpl implements ChatInfoUnmuteNotifications {
  const _$ChatInfoUnmuteNotificationsImpl({required this.chatId});

  @override
  final String chatId;

  @override
  String toString() {
    return 'ChatInfoEvent.unmuteNotifications(chatId: $chatId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoUnmuteNotificationsImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoUnmuteNotificationsImplCopyWith<_$ChatInfoUnmuteNotificationsImpl>
      get copyWith => __$$ChatInfoUnmuteNotificationsImplCopyWithImpl<
          _$ChatInfoUnmuteNotificationsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return unmuteNotifications(chatId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return unmuteNotifications?.call(chatId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (unmuteNotifications != null) {
      return unmuteNotifications(chatId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return unmuteNotifications(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return unmuteNotifications?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (unmuteNotifications != null) {
      return unmuteNotifications(this);
    }
    return orElse();
  }
}

abstract class ChatInfoUnmuteNotifications implements ChatInfoEvent {
  const factory ChatInfoUnmuteNotifications({required final String chatId}) =
      _$ChatInfoUnmuteNotificationsImpl;

  String get chatId;
  @JsonKey(ignore: true)
  _$$ChatInfoUnmuteNotificationsImplCopyWith<_$ChatInfoUnmuteNotificationsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatInfoBlockUserImplCopyWith<$Res> {
  factory _$$ChatInfoBlockUserImplCopyWith(_$ChatInfoBlockUserImpl value,
          $Res Function(_$ChatInfoBlockUserImpl) then) =
      __$$ChatInfoBlockUserImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String userId});
}

/// @nodoc
class __$$ChatInfoBlockUserImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res, _$ChatInfoBlockUserImpl>
    implements _$$ChatInfoBlockUserImplCopyWith<$Res> {
  __$$ChatInfoBlockUserImplCopyWithImpl(_$ChatInfoBlockUserImpl _value,
      $Res Function(_$ChatInfoBlockUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
  }) {
    return _then(_$ChatInfoBlockUserImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatInfoBlockUserImpl implements ChatInfoBlockUser {
  const _$ChatInfoBlockUserImpl({required this.userId});

  @override
  final String userId;

  @override
  String toString() {
    return 'ChatInfoEvent.blockUser(userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoBlockUserImpl &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, userId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoBlockUserImplCopyWith<_$ChatInfoBlockUserImpl> get copyWith =>
      __$$ChatInfoBlockUserImplCopyWithImpl<_$ChatInfoBlockUserImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return blockUser(userId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return blockUser?.call(userId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (blockUser != null) {
      return blockUser(userId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return blockUser(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return blockUser?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (blockUser != null) {
      return blockUser(this);
    }
    return orElse();
  }
}

abstract class ChatInfoBlockUser implements ChatInfoEvent {
  const factory ChatInfoBlockUser({required final String userId}) =
      _$ChatInfoBlockUserImpl;

  String get userId;
  @JsonKey(ignore: true)
  _$$ChatInfoBlockUserImplCopyWith<_$ChatInfoBlockUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatInfoUnblockUserImplCopyWith<$Res> {
  factory _$$ChatInfoUnblockUserImplCopyWith(_$ChatInfoUnblockUserImpl value,
          $Res Function(_$ChatInfoUnblockUserImpl) then) =
      __$$ChatInfoUnblockUserImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String userId});
}

/// @nodoc
class __$$ChatInfoUnblockUserImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res, _$ChatInfoUnblockUserImpl>
    implements _$$ChatInfoUnblockUserImplCopyWith<$Res> {
  __$$ChatInfoUnblockUserImplCopyWithImpl(_$ChatInfoUnblockUserImpl _value,
      $Res Function(_$ChatInfoUnblockUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
  }) {
    return _then(_$ChatInfoUnblockUserImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatInfoUnblockUserImpl implements ChatInfoUnblockUser {
  const _$ChatInfoUnblockUserImpl({required this.userId});

  @override
  final String userId;

  @override
  String toString() {
    return 'ChatInfoEvent.unblockUser(userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoUnblockUserImpl &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, userId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoUnblockUserImplCopyWith<_$ChatInfoUnblockUserImpl> get copyWith =>
      __$$ChatInfoUnblockUserImplCopyWithImpl<_$ChatInfoUnblockUserImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return unblockUser(userId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return unblockUser?.call(userId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (unblockUser != null) {
      return unblockUser(userId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return unblockUser(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return unblockUser?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (unblockUser != null) {
      return unblockUser(this);
    }
    return orElse();
  }
}

abstract class ChatInfoUnblockUser implements ChatInfoEvent {
  const factory ChatInfoUnblockUser({required final String userId}) =
      _$ChatInfoUnblockUserImpl;

  String get userId;
  @JsonKey(ignore: true)
  _$$ChatInfoUnblockUserImplCopyWith<_$ChatInfoUnblockUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatInfoCheckUserBlockedImplCopyWith<$Res> {
  factory _$$ChatInfoCheckUserBlockedImplCopyWith(
          _$ChatInfoCheckUserBlockedImpl value,
          $Res Function(_$ChatInfoCheckUserBlockedImpl) then) =
      __$$ChatInfoCheckUserBlockedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String userId});
}

/// @nodoc
class __$$ChatInfoCheckUserBlockedImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res, _$ChatInfoCheckUserBlockedImpl>
    implements _$$ChatInfoCheckUserBlockedImplCopyWith<$Res> {
  __$$ChatInfoCheckUserBlockedImplCopyWithImpl(
      _$ChatInfoCheckUserBlockedImpl _value,
      $Res Function(_$ChatInfoCheckUserBlockedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
  }) {
    return _then(_$ChatInfoCheckUserBlockedImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatInfoCheckUserBlockedImpl implements ChatInfoCheckUserBlocked {
  const _$ChatInfoCheckUserBlockedImpl({required this.userId});

  @override
  final String userId;

  @override
  String toString() {
    return 'ChatInfoEvent.checkUserBlocked(userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoCheckUserBlockedImpl &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, userId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoCheckUserBlockedImplCopyWith<_$ChatInfoCheckUserBlockedImpl>
      get copyWith => __$$ChatInfoCheckUserBlockedImplCopyWithImpl<
          _$ChatInfoCheckUserBlockedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return checkUserBlocked(userId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return checkUserBlocked?.call(userId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (checkUserBlocked != null) {
      return checkUserBlocked(userId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return checkUserBlocked(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return checkUserBlocked?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (checkUserBlocked != null) {
      return checkUserBlocked(this);
    }
    return orElse();
  }
}

abstract class ChatInfoCheckUserBlocked implements ChatInfoEvent {
  const factory ChatInfoCheckUserBlocked({required final String userId}) =
      _$ChatInfoCheckUserBlockedImpl;

  String get userId;
  @JsonKey(ignore: true)
  _$$ChatInfoCheckUserBlockedImplCopyWith<_$ChatInfoCheckUserBlockedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatInfoReportChatImplCopyWith<$Res> {
  factory _$$ChatInfoReportChatImplCopyWith(_$ChatInfoReportChatImpl value,
          $Res Function(_$ChatInfoReportChatImpl) then) =
      __$$ChatInfoReportChatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chatId, String reason});
}

/// @nodoc
class __$$ChatInfoReportChatImplCopyWithImpl<$Res>
    extends _$ChatInfoEventCopyWithImpl<$Res, _$ChatInfoReportChatImpl>
    implements _$$ChatInfoReportChatImplCopyWith<$Res> {
  __$$ChatInfoReportChatImplCopyWithImpl(_$ChatInfoReportChatImpl _value,
      $Res Function(_$ChatInfoReportChatImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? reason = null,
  }) {
    return _then(_$ChatInfoReportChatImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatInfoReportChatImpl implements ChatInfoReportChat {
  const _$ChatInfoReportChatImpl({required this.chatId, required this.reason});

  @override
  final String chatId;
  @override
  final String reason;

  @override
  String toString() {
    return 'ChatInfoEvent.reportChat(chatId: $chatId, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInfoReportChatImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chatId, reason);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInfoReportChatImplCopyWith<_$ChatInfoReportChatImpl> get copyWith =>
      __$$ChatInfoReportChatImplCopyWithImpl<_$ChatInfoReportChatImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)
        loadSharedMedia,
    required TResult Function(String chatId) loadNotificationSettings,
    required TResult Function(NotificationSettings settings)
        updateNotificationSettings,
    required TResult Function(String chatId, MuteDuration duration)
        muteNotifications,
    required TResult Function(String chatId) unmuteNotifications,
    required TResult Function(String userId) blockUser,
    required TResult Function(String userId) unblockUser,
    required TResult Function(String userId) checkUserBlocked,
    required TResult Function(String chatId, String reason) reportChat,
  }) {
    return reportChat(chatId, reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult? Function(String chatId)? loadNotificationSettings,
    TResult? Function(NotificationSettings settings)?
        updateNotificationSettings,
    TResult? Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult? Function(String chatId)? unmuteNotifications,
    TResult? Function(String userId)? blockUser,
    TResult? Function(String userId)? unblockUser,
    TResult? Function(String userId)? checkUserBlocked,
    TResult? Function(String chatId, String reason)? reportChat,
  }) {
    return reportChat?.call(chatId, reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String chatId, SharedMediaType type, int? limit, int? offset)?
        loadSharedMedia,
    TResult Function(String chatId)? loadNotificationSettings,
    TResult Function(NotificationSettings settings)? updateNotificationSettings,
    TResult Function(String chatId, MuteDuration duration)? muteNotifications,
    TResult Function(String chatId)? unmuteNotifications,
    TResult Function(String userId)? blockUser,
    TResult Function(String userId)? unblockUser,
    TResult Function(String userId)? checkUserBlocked,
    TResult Function(String chatId, String reason)? reportChat,
    required TResult orElse(),
  }) {
    if (reportChat != null) {
      return reportChat(chatId, reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInfoLoadSharedMedia value) loadSharedMedia,
    required TResult Function(ChatInfoLoadNotificationSettings value)
        loadNotificationSettings,
    required TResult Function(ChatInfoUpdateNotificationSettings value)
        updateNotificationSettings,
    required TResult Function(ChatInfoMuteNotifications value)
        muteNotifications,
    required TResult Function(ChatInfoUnmuteNotifications value)
        unmuteNotifications,
    required TResult Function(ChatInfoBlockUser value) blockUser,
    required TResult Function(ChatInfoUnblockUser value) unblockUser,
    required TResult Function(ChatInfoCheckUserBlocked value) checkUserBlocked,
    required TResult Function(ChatInfoReportChat value) reportChat,
  }) {
    return reportChat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult? Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult? Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult? Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult? Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult? Function(ChatInfoBlockUser value)? blockUser,
    TResult? Function(ChatInfoUnblockUser value)? unblockUser,
    TResult? Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult? Function(ChatInfoReportChat value)? reportChat,
  }) {
    return reportChat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInfoLoadSharedMedia value)? loadSharedMedia,
    TResult Function(ChatInfoLoadNotificationSettings value)?
        loadNotificationSettings,
    TResult Function(ChatInfoUpdateNotificationSettings value)?
        updateNotificationSettings,
    TResult Function(ChatInfoMuteNotifications value)? muteNotifications,
    TResult Function(ChatInfoUnmuteNotifications value)? unmuteNotifications,
    TResult Function(ChatInfoBlockUser value)? blockUser,
    TResult Function(ChatInfoUnblockUser value)? unblockUser,
    TResult Function(ChatInfoCheckUserBlocked value)? checkUserBlocked,
    TResult Function(ChatInfoReportChat value)? reportChat,
    required TResult orElse(),
  }) {
    if (reportChat != null) {
      return reportChat(this);
    }
    return orElse();
  }
}

abstract class ChatInfoReportChat implements ChatInfoEvent {
  const factory ChatInfoReportChat(
      {required final String chatId,
      required final String reason}) = _$ChatInfoReportChatImpl;

  String get chatId;
  String get reason;
  @JsonKey(ignore: true)
  _$$ChatInfoReportChatImplCopyWith<_$ChatInfoReportChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NotificationSettingsModel _$NotificationSettingsModelFromJson(
    Map<String, dynamic> json) {
  return _NotificationSettingsModel.fromJson(json);
}

/// @nodoc
mixin _$NotificationSettingsModel {
  String get chatId => throw _privateConstructorUsedError;
  bool get isMuted => throw _privateConstructorUsedError;
  DateTime? get mutedUntil => throw _privateConstructorUsedError;
  bool get mentionOnly => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationSettingsModelCopyWith<NotificationSettingsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationSettingsModelCopyWith<$Res> {
  factory $NotificationSettingsModelCopyWith(NotificationSettingsModel value,
          $Res Function(NotificationSettingsModel) then) =
      _$NotificationSettingsModelCopyWithImpl<$Res, NotificationSettingsModel>;
  @useResult
  $Res call(
      {String chatId, bool isMuted, DateTime? mutedUntil, bool mentionOnly});
}

/// @nodoc
class _$NotificationSettingsModelCopyWithImpl<$Res,
        $Val extends NotificationSettingsModel>
    implements $NotificationSettingsModelCopyWith<$Res> {
  _$NotificationSettingsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? isMuted = null,
    Object? mutedUntil = freezed,
    Object? mentionOnly = null,
  }) {
    return _then(_value.copyWith(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      mutedUntil: freezed == mutedUntil
          ? _value.mutedUntil
          : mutedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      mentionOnly: null == mentionOnly
          ? _value.mentionOnly
          : mentionOnly // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationSettingsModelImplCopyWith<$Res>
    implements $NotificationSettingsModelCopyWith<$Res> {
  factory _$$NotificationSettingsModelImplCopyWith(
          _$NotificationSettingsModelImpl value,
          $Res Function(_$NotificationSettingsModelImpl) then) =
      __$$NotificationSettingsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String chatId, bool isMuted, DateTime? mutedUntil, bool mentionOnly});
}

/// @nodoc
class __$$NotificationSettingsModelImplCopyWithImpl<$Res>
    extends _$NotificationSettingsModelCopyWithImpl<$Res,
        _$NotificationSettingsModelImpl>
    implements _$$NotificationSettingsModelImplCopyWith<$Res> {
  __$$NotificationSettingsModelImplCopyWithImpl(
      _$NotificationSettingsModelImpl _value,
      $Res Function(_$NotificationSettingsModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatId = null,
    Object? isMuted = null,
    Object? mutedUntil = freezed,
    Object? mentionOnly = null,
  }) {
    return _then(_$NotificationSettingsModelImpl(
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      mutedUntil: freezed == mutedUntil
          ? _value.mutedUntil
          : mutedUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      mentionOnly: null == mentionOnly
          ? _value.mentionOnly
          : mentionOnly // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationSettingsModelImpl extends _NotificationSettingsModel {
  const _$NotificationSettingsModelImpl(
      {required this.chatId,
      required this.isMuted,
      this.mutedUntil,
      this.mentionOnly = false})
      : super._();

  factory _$NotificationSettingsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationSettingsModelImplFromJson(json);

  @override
  final String chatId;
  @override
  final bool isMuted;
  @override
  final DateTime? mutedUntil;
  @override
  @JsonKey()
  final bool mentionOnly;

  @override
  String toString() {
    return 'NotificationSettingsModel(chatId: $chatId, isMuted: $isMuted, mutedUntil: $mutedUntil, mentionOnly: $mentionOnly)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationSettingsModelImpl &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.mutedUntil, mutedUntil) ||
                other.mutedUntil == mutedUntil) &&
            (identical(other.mentionOnly, mentionOnly) ||
                other.mentionOnly == mentionOnly));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, chatId, isMuted, mutedUntil, mentionOnly);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationSettingsModelImplCopyWith<_$NotificationSettingsModelImpl>
      get copyWith => __$$NotificationSettingsModelImplCopyWithImpl<
          _$NotificationSettingsModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationSettingsModelImplToJson(
      this,
    );
  }
}

abstract class _NotificationSettingsModel extends NotificationSettingsModel {
  const factory _NotificationSettingsModel(
      {required final String chatId,
      required final bool isMuted,
      final DateTime? mutedUntil,
      final bool mentionOnly}) = _$NotificationSettingsModelImpl;
  const _NotificationSettingsModel._() : super._();

  factory _NotificationSettingsModel.fromJson(Map<String, dynamic> json) =
      _$NotificationSettingsModelImpl.fromJson;

  @override
  String get chatId;
  @override
  bool get isMuted;
  @override
  DateTime? get mutedUntil;
  @override
  bool get mentionOnly;
  @override
  @JsonKey(ignore: true)
  _$$NotificationSettingsModelImplCopyWith<_$NotificationSettingsModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

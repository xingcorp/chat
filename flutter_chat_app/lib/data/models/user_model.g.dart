// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetUserModelCollection on Isar {
  IsarCollection<int, UserModel> get userModels => this.collection();
}

const UserModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'UserModel',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'serverId',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'username',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'displayName',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'avatarUrl',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'email',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'isOnline',
      type: IsarType.bool,
    ),
      IsarPropertySchema(
        name: 'lastSeen',
      type: IsarType.dateTime,
    ),
      IsarPropertySchema(
        name: 'statusMessage',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'roles',
      type: IsarType.stringList,
    ),
      IsarPropertySchema(
        name: 'isAdmin',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'isModerator',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'fullName',
      type: IsarType.string,
    ),
      IsarPropertySchema(
        name: 'initials',
      type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'isRecentlyActive',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'hasEmail',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'hasAvatar',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'hasStatusMessage',
        type: IsarType.bool,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'serverId',
      properties: [
          "serverId",
        ],
        unique: true,
        hash: false,
      ),
      IsarIndexSchema(
        name: 'username',
      properties: [
          "username",
        ],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, UserModel>(
    serialize: serializeUserModel,
    deserialize: deserializeUserModel,
    deserializeProperty: deserializeUserModelProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeUserModel(IsarWriter writer, UserModel object) {
  IsarCore.writeString(writer, 1, object.serverId);
  IsarCore.writeString(writer, 2, object.username);
  IsarCore.writeString(writer, 3, object.displayName);
  {
    final value = object.avatarUrl;
    if (value == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      IsarCore.writeString(writer, 4, value);
    }
  }
  {
    final value = object.email;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  IsarCore.writeBool(writer, 6, object.isOnline);
  IsarCore.writeLong(writer, 7, object.lastSeen.toUtc().microsecondsSinceEpoch);
  {
    final value = object.statusMessage;
    if (value == null) {
      IsarCore.writeNull(writer, 8);
    } else {
      IsarCore.writeString(writer, 8, value);
    }
  }
  {
    final list = object.roles;
    final listWriter = IsarCore.beginList(writer, 9, list.length);
    for (var i = 0; i < list.length; i++) {
      IsarCore.writeString(listWriter, i, list[i]);
    }
    IsarCore.endList(writer, listWriter);
  }
  IsarCore.writeBool(writer, 10, object.isAdmin);
  IsarCore.writeBool(writer, 11, object.isModerator);
  IsarCore.writeString(writer, 12, object.fullName);
  IsarCore.writeString(writer, 13, object.initials);
  IsarCore.writeBool(writer, 14, object.isRecentlyActive);
  IsarCore.writeBool(writer, 15, object.hasEmail);
  IsarCore.writeBool(writer, 16, object.hasAvatar);
  IsarCore.writeBool(writer, 17, object.hasStatusMessage);
  return object.id;
}

@isarProtected
UserModel deserializeUserModel(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final String _serverId;
  _serverId = IsarCore.readString(reader, 1) ?? '';
  final String _username;
  _username = IsarCore.readString(reader, 2) ?? '';
  final String _displayName;
  _displayName = IsarCore.readString(reader, 3) ?? '';
  final String? _avatarUrl;
  _avatarUrl = IsarCore.readString(reader, 4);
  final String? _email;
  _email = IsarCore.readString(reader, 5);
  final bool _isOnline;
  _isOnline = IsarCore.readBool(reader, 6);
  final DateTime _lastSeen;
  {
    final value = IsarCore.readLong(reader, 7);
    if (value == -9223372036854775808) {
      _lastSeen = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
    } else {
      _lastSeen =
          DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal();
    }
  }
  final String? _statusMessage;
  _statusMessage = IsarCore.readString(reader, 8);
  final List<String> _roles;
  {
    final length = IsarCore.readList(reader, 9, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _roles = const [];
      } else {
        final list = List<String>.filled(length, '', growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readString(reader, i) ?? '';
        }
        IsarCore.freeReader(reader);
        _roles = list;
      }
    }
  }
  final object = UserModel(
    id: _id,
    serverId: _serverId,
    username: _username,
    displayName: _displayName,
    avatarUrl: _avatarUrl,
    email: _email,
    isOnline: _isOnline,
    lastSeen: _lastSeen,
    statusMessage: _statusMessage,
    roles: _roles,
  );
  return object;
}

@isarProtected
dynamic deserializeUserModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      return IsarCore.readString(reader, 4);
    case 5:
      return IsarCore.readString(reader, 5);
    case 6:
      return IsarCore.readBool(reader, 6);
    case 7:
      {
        final value = IsarCore.readLong(reader, 7);
        if (value == -9223372036854775808) {
          return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();
        } else {
          return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true)
              .toLocal();
        }
      }
    case 8:
      return IsarCore.readString(reader, 8);
    case 9:
      {
        final length = IsarCore.readList(reader, 9, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return const [];
          } else {
            final list = List<String>.filled(length, '', growable: true);
            for (var i = 0; i < length; i++) {
              list[i] = IsarCore.readString(reader, i) ?? '';
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    case 10:
      return IsarCore.readBool(reader, 10);
    case 11:
      return IsarCore.readBool(reader, 11);
    case 12:
      return IsarCore.readString(reader, 12) ?? '';
    case 13:
      return IsarCore.readString(reader, 13) ?? '';
    case 14:
      return IsarCore.readBool(reader, 14);
    case 15:
      return IsarCore.readBool(reader, 15);
    case 16:
      return IsarCore.readBool(reader, 16);
    case 17:
      return IsarCore.readBool(reader, 17);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _UserModelUpdate {
  bool call({
    required int id,
    String? serverId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? email,
    bool? isOnline,
    DateTime? lastSeen,
    String? statusMessage,
    bool? isAdmin,
    bool? isModerator,
    String? fullName,
    String? initials,
    bool? isRecentlyActive,
    bool? hasEmail,
    bool? hasAvatar,
    bool? hasStatusMessage,
  });
}

class _UserModelUpdateImpl implements _UserModelUpdate {
  const _UserModelUpdateImpl(this.collection);

  final IsarCollection<int, UserModel> collection;

  @override
  bool call({
    required int id,
    Object? serverId = ignore,
    Object? username = ignore,
    Object? displayName = ignore,
    Object? avatarUrl = ignore,
    Object? email = ignore,
    Object? isOnline = ignore,
    Object? lastSeen = ignore,
    Object? statusMessage = ignore,
    Object? isAdmin = ignore,
    Object? isModerator = ignore,
    Object? fullName = ignore,
    Object? initials = ignore,
    Object? isRecentlyActive = ignore,
    Object? hasEmail = ignore,
    Object? hasAvatar = ignore,
    Object? hasStatusMessage = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (serverId != ignore) 1: serverId as String?,
          if (username != ignore) 2: username as String?,
          if (displayName != ignore) 3: displayName as String?,
          if (avatarUrl != ignore) 4: avatarUrl as String?,
          if (email != ignore) 5: email as String?,
          if (isOnline != ignore) 6: isOnline as bool?,
          if (lastSeen != ignore) 7: lastSeen as DateTime?,
          if (statusMessage != ignore) 8: statusMessage as String?,
          if (isAdmin != ignore) 10: isAdmin as bool?,
          if (isModerator != ignore) 11: isModerator as bool?,
          if (fullName != ignore) 12: fullName as String?,
          if (initials != ignore) 13: initials as String?,
          if (isRecentlyActive != ignore) 14: isRecentlyActive as bool?,
          if (hasEmail != ignore) 15: hasEmail as bool?,
          if (hasAvatar != ignore) 16: hasAvatar as bool?,
          if (hasStatusMessage != ignore) 17: hasStatusMessage as bool?,
        }) >
        0;
  }
}

sealed class _UserModelUpdateAll {
  int call({
    required List<int> id,
    String? serverId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? email,
    bool? isOnline,
    DateTime? lastSeen,
    String? statusMessage,
    bool? isAdmin,
    bool? isModerator,
    String? fullName,
    String? initials,
    bool? isRecentlyActive,
    bool? hasEmail,
    bool? hasAvatar,
    bool? hasStatusMessage,
  });
}

class _UserModelUpdateAllImpl implements _UserModelUpdateAll {
  const _UserModelUpdateAllImpl(this.collection);

  final IsarCollection<int, UserModel> collection;

  @override
  int call({
    required List<int> id,
    Object? serverId = ignore,
    Object? username = ignore,
    Object? displayName = ignore,
    Object? avatarUrl = ignore,
    Object? email = ignore,
    Object? isOnline = ignore,
    Object? lastSeen = ignore,
    Object? statusMessage = ignore,
    Object? isAdmin = ignore,
    Object? isModerator = ignore,
    Object? fullName = ignore,
    Object? initials = ignore,
    Object? isRecentlyActive = ignore,
    Object? hasEmail = ignore,
    Object? hasAvatar = ignore,
    Object? hasStatusMessage = ignore,
  }) {
    return collection.updateProperties(id, {
      if (serverId != ignore) 1: serverId as String?,
      if (username != ignore) 2: username as String?,
      if (displayName != ignore) 3: displayName as String?,
      if (avatarUrl != ignore) 4: avatarUrl as String?,
      if (email != ignore) 5: email as String?,
      if (isOnline != ignore) 6: isOnline as bool?,
      if (lastSeen != ignore) 7: lastSeen as DateTime?,
      if (statusMessage != ignore) 8: statusMessage as String?,
      if (isAdmin != ignore) 10: isAdmin as bool?,
      if (isModerator != ignore) 11: isModerator as bool?,
      if (fullName != ignore) 12: fullName as String?,
      if (initials != ignore) 13: initials as String?,
      if (isRecentlyActive != ignore) 14: isRecentlyActive as bool?,
      if (hasEmail != ignore) 15: hasEmail as bool?,
      if (hasAvatar != ignore) 16: hasAvatar as bool?,
      if (hasStatusMessage != ignore) 17: hasStatusMessage as bool?,
    });
  }
}

extension UserModelUpdate on IsarCollection<int, UserModel> {
  _UserModelUpdate get update => _UserModelUpdateImpl(this);

  _UserModelUpdateAll get updateAll => _UserModelUpdateAllImpl(this);
}

sealed class _UserModelQueryUpdate {
  int call({
    String? serverId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? email,
    bool? isOnline,
    DateTime? lastSeen,
    String? statusMessage,
    bool? isAdmin,
    bool? isModerator,
    String? fullName,
    String? initials,
    bool? isRecentlyActive,
    bool? hasEmail,
    bool? hasAvatar,
    bool? hasStatusMessage,
  });
}

class _UserModelQueryUpdateImpl implements _UserModelQueryUpdate {
  const _UserModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<UserModel> query;
  final int? limit;

  @override
  int call({
    Object? serverId = ignore,
    Object? username = ignore,
    Object? displayName = ignore,
    Object? avatarUrl = ignore,
    Object? email = ignore,
    Object? isOnline = ignore,
    Object? lastSeen = ignore,
    Object? statusMessage = ignore,
    Object? isAdmin = ignore,
    Object? isModerator = ignore,
    Object? fullName = ignore,
    Object? initials = ignore,
    Object? isRecentlyActive = ignore,
    Object? hasEmail = ignore,
    Object? hasAvatar = ignore,
    Object? hasStatusMessage = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (serverId != ignore) 1: serverId as String?,
      if (username != ignore) 2: username as String?,
      if (displayName != ignore) 3: displayName as String?,
      if (avatarUrl != ignore) 4: avatarUrl as String?,
      if (email != ignore) 5: email as String?,
      if (isOnline != ignore) 6: isOnline as bool?,
      if (lastSeen != ignore) 7: lastSeen as DateTime?,
      if (statusMessage != ignore) 8: statusMessage as String?,
      if (isAdmin != ignore) 10: isAdmin as bool?,
      if (isModerator != ignore) 11: isModerator as bool?,
      if (fullName != ignore) 12: fullName as String?,
      if (initials != ignore) 13: initials as String?,
      if (isRecentlyActive != ignore) 14: isRecentlyActive as bool?,
      if (hasEmail != ignore) 15: hasEmail as bool?,
      if (hasAvatar != ignore) 16: hasAvatar as bool?,
      if (hasStatusMessage != ignore) 17: hasStatusMessage as bool?,
    });
  }
}

extension UserModelQueryUpdate on IsarQuery<UserModel> {
  _UserModelQueryUpdate get updateFirst =>
      _UserModelQueryUpdateImpl(this, limit: 1);

  _UserModelQueryUpdate get updateAll => _UserModelQueryUpdateImpl(this);
}

class _UserModelQueryBuilderUpdateImpl implements _UserModelQueryUpdate {
  const _UserModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<UserModel, UserModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? serverId = ignore,
    Object? username = ignore,
    Object? displayName = ignore,
    Object? avatarUrl = ignore,
    Object? email = ignore,
    Object? isOnline = ignore,
    Object? lastSeen = ignore,
    Object? statusMessage = ignore,
    Object? isAdmin = ignore,
    Object? isModerator = ignore,
    Object? fullName = ignore,
    Object? initials = ignore,
    Object? isRecentlyActive = ignore,
    Object? hasEmail = ignore,
    Object? hasAvatar = ignore,
    Object? hasStatusMessage = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (serverId != ignore) 1: serverId as String?,
        if (username != ignore) 2: username as String?,
        if (displayName != ignore) 3: displayName as String?,
        if (avatarUrl != ignore) 4: avatarUrl as String?,
        if (email != ignore) 5: email as String?,
        if (isOnline != ignore) 6: isOnline as bool?,
        if (lastSeen != ignore) 7: lastSeen as DateTime?,
        if (statusMessage != ignore) 8: statusMessage as String?,
        if (isAdmin != ignore) 10: isAdmin as bool?,
        if (isModerator != ignore) 11: isModerator as bool?,
        if (fullName != ignore) 12: fullName as String?,
        if (initials != ignore) 13: initials as String?,
        if (isRecentlyActive != ignore) 14: isRecentlyActive as bool?,
        if (hasEmail != ignore) 15: hasEmail as bool?,
        if (hasAvatar != ignore) 16: hasAvatar as bool?,
        if (hasStatusMessage != ignore) 17: hasStatusMessage as bool?,
      });
    } finally {
      q.close();
    }
  }
}

extension UserModelQueryBuilderUpdate
    on QueryBuilder<UserModel, UserModel, QOperations> {
  _UserModelQueryUpdate get updateFirst =>
      _UserModelQueryBuilderUpdateImpl(this, limit: 1);

  _UserModelQueryUpdate get updateAll => _UserModelQueryBuilderUpdateImpl(this);
}

extension UserModelQueryFilter
    on QueryBuilder<UserModel, UserModel, QFilterCondition> {
  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      serverIdGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      serverIdLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      usernameGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      usernameLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> displayNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 3,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 3,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarUrlIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarUrlGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarUrlGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarUrlLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 4,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 4,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 4,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 4,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> avatarUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 4,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      avatarUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 4,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 5,
        value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
        value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      emailGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
        value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      emailLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
        lower: lower,
        upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> isOnlineEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 6,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> lastSeenEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 7,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> lastSeenGreaterThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 7,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      lastSeenGreaterThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 7,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> lastSeenLessThan(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 7,
        value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      lastSeenLessThanOrEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 7,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> lastSeenBetween(
    DateTime lower,
    DateTime upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 7,
        lower: lower,
        upper: upper,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 8));
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 8,
          value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 8,
          lower: lower,
          upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 8,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 8,
          value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 8,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 8,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 8,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      statusMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 8,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> rolesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 9,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 9,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> rolesElementBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 9,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 9,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> rolesElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 9,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 9,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      rolesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 9,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> rolesIsEmpty() {
    return not().rolesIsNotEmpty();
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> rolesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 9, value: null),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> isAdminEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 10,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> isModeratorEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 11,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 12,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 12,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      fullNameGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 12,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      fullNameLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 12,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 12,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 12,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 12,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 12,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 12,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> fullNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 12,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      fullNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 12,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 13,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 13,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      initialsGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 13,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      initialsLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 13,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 13,
        lower: lower,
        upper: upper,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 13,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 13,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 13,
        value: value,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 13,
        wildcard: pattern,
        caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> initialsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 13,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      initialsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 13,
        value: '',
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      isRecentlyActiveEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 14,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> hasEmailEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 15,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> hasAvatarEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 16,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterFilterCondition>
      hasStatusMessageEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 17,
          value: value,
        ),
      );
    });
  }
}

extension UserModelQueryObject
    on QueryBuilder<UserModel, UserModel, QFilterCondition> {}

extension UserModelQuerySortBy on QueryBuilder<UserModel, UserModel, QSortBy> {
  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByServerIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByUsernameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByDisplayNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByAvatarUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByAvatarUrlDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        4,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByEmailDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByIsOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByIsOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByStatusMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        8,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByStatusMessageDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        8,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByIsAdminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByIsModerator() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByIsModeratorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByFullName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        12,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByFullNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        12,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByInitials(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        13,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByInitialsDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        13,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByIsRecentlyActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByIsRecentlyActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByHasEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByHasEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByHasAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByHasAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> sortByHasStatusMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      sortByHasStatusMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17, sort: Sort.desc);
    });
  }
}

extension UserModelQuerySortThenBy
    on QueryBuilder<UserModel, UserModel, QSortThenBy> {
  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByServerIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByUsernameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByDisplayNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByAvatarUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByAvatarUrlDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByEmailDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIsOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIsOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(6, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByLastSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(7, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByStatusMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByStatusMessageDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(8, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIsAdminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(10, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIsModerator() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIsModeratorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(11, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByFullName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByFullNameDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(12, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByInitials(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByInitialsDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(13, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByIsRecentlyActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByIsRecentlyActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(14, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByHasEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByHasEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(15, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByHasAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByHasAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(16, sort: Sort.desc);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy> thenByHasStatusMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterSortBy>
      thenByHasStatusMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(17, sort: Sort.desc);
    });
  }
}

extension UserModelQueryWhereDistinct
    on QueryBuilder<UserModel, UserModel, QDistinct> {
  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByAvatarUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByIsOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(6);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByLastSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(7);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByStatusMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(8, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByRoles() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(9);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(10);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByIsModerator() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(11);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByFullName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(12, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByInitials(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(13, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct>
      distinctByIsRecentlyActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(14);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByHasEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(15);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct> distinctByHasAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(16);
    });
  }

  QueryBuilder<UserModel, UserModel, QAfterDistinct>
      distinctByHasStatusMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(17);
    });
  }
  }

extension UserModelQueryProperty1
    on QueryBuilder<UserModel, UserModel, QProperty> {
  QueryBuilder<UserModel, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<UserModel, String, QAfterProperty> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserModel, String, QAfterProperty> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserModel, String, QAfterProperty> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserModel, String?, QAfterProperty> avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<UserModel, String?, QAfterProperty> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<UserModel, bool, QAfterProperty> isOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<UserModel, DateTime, QAfterProperty> lastSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<UserModel, String?, QAfterProperty> statusMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<UserModel, List<String>, QAfterProperty> rolesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<UserModel, bool, QAfterProperty> isAdminProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<UserModel, bool, QAfterProperty> isModeratorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<UserModel, String, QAfterProperty> fullNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<UserModel, String, QAfterProperty> initialsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<UserModel, bool, QAfterProperty> isRecentlyActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<UserModel, bool, QAfterProperty> hasEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<UserModel, bool, QAfterProperty> hasAvatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<UserModel, bool, QAfterProperty> hasStatusMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }
}

extension UserModelQueryProperty2<R>
    on QueryBuilder<UserModel, R, QAfterProperty> {
  QueryBuilder<UserModel, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<UserModel, (R, String), QAfterProperty> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserModel, (R, String), QAfterProperty> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserModel, (R, String), QAfterProperty> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserModel, (R, String?), QAfterProperty> avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<UserModel, (R, String?), QAfterProperty> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<UserModel, (R, bool), QAfterProperty> isOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<UserModel, (R, DateTime), QAfterProperty> lastSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<UserModel, (R, String?), QAfterProperty>
      statusMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<UserModel, (R, List<String>), QAfterProperty> rolesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<UserModel, (R, bool), QAfterProperty> isAdminProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<UserModel, (R, bool), QAfterProperty> isModeratorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<UserModel, (R, String), QAfterProperty> fullNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<UserModel, (R, String), QAfterProperty> initialsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<UserModel, (R, bool), QAfterProperty>
      isRecentlyActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<UserModel, (R, bool), QAfterProperty> hasEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<UserModel, (R, bool), QAfterProperty> hasAvatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<UserModel, (R, bool), QAfterProperty>
      hasStatusMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }
}

extension UserModelQueryProperty3<R1, R2>
    on QueryBuilder<UserModel, (R1, R2), QAfterProperty> {
  QueryBuilder<UserModel, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<UserModel, (R1, R2, String), QOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<UserModel, (R1, R2, String), QOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<UserModel, (R1, R2, String), QOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<UserModel, (R1, R2, String?), QOperations> avatarUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<UserModel, (R1, R2, String?), QOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }

  QueryBuilder<UserModel, (R1, R2, bool), QOperations> isOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(6);
    });
  }

  QueryBuilder<UserModel, (R1, R2, DateTime), QOperations> lastSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(7);
    });
  }

  QueryBuilder<UserModel, (R1, R2, String?), QOperations>
      statusMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(8);
    });
  }

  QueryBuilder<UserModel, (R1, R2, List<String>), QOperations> rolesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(9);
    });
  }

  QueryBuilder<UserModel, (R1, R2, bool), QOperations> isAdminProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(10);
    });
  }

  QueryBuilder<UserModel, (R1, R2, bool), QOperations> isModeratorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(11);
    });
  }

  QueryBuilder<UserModel, (R1, R2, String), QOperations> fullNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(12);
    });
  }

  QueryBuilder<UserModel, (R1, R2, String), QOperations> initialsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(13);
    });
  }

  QueryBuilder<UserModel, (R1, R2, bool), QOperations>
      isRecentlyActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(14);
    });
  }

  QueryBuilder<UserModel, (R1, R2, bool), QOperations> hasEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(15);
    });
  }

  QueryBuilder<UserModel, (R1, R2, bool), QOperations> hasAvatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(16);
    });
  }

  QueryBuilder<UserModel, (R1, R2, bool), QOperations>
      hasStatusMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(17);
    });
  }
}

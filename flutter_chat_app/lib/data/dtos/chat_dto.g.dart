// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatDtoImpl _$$ChatDtoImplFromJson(Map<String, dynamic> json) =>
    _$ChatDtoImpl(
      id: json['id'] as String,
      name: json['name'] as String?,
      type: json['type'] as String,
      description: json['description'] as String?,
      imageUrl: json['imgUrl'] as String?,
      groupType: json['groupType'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      lastMessageAt: (json['lastMessageAt'] as num?)?.toInt(),
      lastMessageId: json['lastMessageId'] as String?,
      lastMessage: _lastMessageFromJson(json['lastMessage']),
      personalConversation:
          _personalConversationFromJson(json['personalConversation']),
      creator: json['creator'] == null
          ? null
          : CreatorDto.fromJson(json['creator'] as Map<String, dynamic>),
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => MemberDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ChatDtoImplToJson(_$ChatDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'description': instance.description,
      'imgUrl': instance.imageUrl,
      'groupType': instance.groupType,
      'createdAt': instance.createdAt,
      'lastMessageAt': instance.lastMessageAt,
      'lastMessageId': instance.lastMessageId,
      'lastMessage': instance.lastMessage,
      'personalConversation': instance.personalConversation,
      'creator': instance.creator,
      'members': instance.members,
    };

_$LastMessageDtoImpl _$$LastMessageDtoImplFromJson(Map<String, dynamic> json) =>
    _$LastMessageDtoImpl(
      id: json['id'] as String,
      message: json['message'] as String?,
      fileName: json['fileName'] as String?,
      type: json['type'] as String?,
      sender: _userBriefFromJson(json['sender']),
      mentionTo: _mentionToFromJson(json['mentionTo']),
    );

Map<String, dynamic> _$$LastMessageDtoImplToJson(
        _$LastMessageDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'fileName': instance.fileName,
      'type': instance.type,
      'sender': instance.sender,
      'mentionTo': instance.mentionTo,
    };

_$UserBriefDtoImpl _$$UserBriefDtoImplFromJson(Map<String, dynamic> json) =>
    _$UserBriefDtoImpl(
      id: json['id'] as String,
      fullName: json['fullname'] as String,
    );

Map<String, dynamic> _$$UserBriefDtoImplToJson(_$UserBriefDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullname': instance.fullName,
    };

_$MentionToDtoImpl _$$MentionToDtoImplFromJson(Map<String, dynamic> json) =>
    _$MentionToDtoImpl(
      id: json['id'] as String,
      fullName: json['fullname'] as String,
    );

Map<String, dynamic> _$$MentionToDtoImplToJson(_$MentionToDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullname': instance.fullName,
    };

_$PersonalConversationDtoImpl _$$PersonalConversationDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$PersonalConversationDtoImpl(
      lastMessageReadId: json['lastMessageReadId'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PersonalConversationDtoImplToJson(
        _$PersonalConversationDtoImpl instance) =>
    <String, dynamic>{
      'lastMessageReadId': instance.lastMessageReadId,
      'unreadCount': instance.unreadCount,
    };

_$CreatorDtoImpl _$$CreatorDtoImplFromJson(Map<String, dynamic> json) =>
    _$CreatorDtoImpl(
      id: json['id'] as String,
      fullName: json['fullname'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CreatorDtoImplToJson(_$CreatorDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullname': instance.fullName,
      'imageUrls': instance.imageUrls,
    };

_$MemberDtoImpl _$$MemberDtoImplFromJson(Map<String, dynamic> json) =>
    _$MemberDtoImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      admin: json['admin'] as bool? ?? false,
      connected: json['connected'] as bool? ?? false,
      hide: json['hide'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastMessageReadId: json['lastMessageReadId'] as String?,
      user: json['user'] == null
          ? null
          : UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MemberDtoImplToJson(_$MemberDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'admin': instance.admin,
      'connected': instance.connected,
      'hide': instance.hide,
      'unreadCount': instance.unreadCount,
      'lastMessageReadId': instance.lastMessageReadId,
      'user': instance.user,
    };

_$UserDtoImpl _$$UserDtoImplFromJson(Map<String, dynamic> json) =>
    _$UserDtoImpl(
      id: json['id'] as String,
      fullName: json['fullname'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      email: json['email'] as String?,
    );

Map<String, dynamic> _$$UserDtoImplToJson(_$UserDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullname': instance.fullName,
      'imageUrls': instance.imageUrls,
      'email': instance.email,
    };

_$ChatListResponseDtoImpl _$$ChatListResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatListResponseDtoImpl(
      total: (json['total'] as num).toInt(),
      conversations: (json['conversations'] as List<dynamic>?)
              ?.map((e) => ChatDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ChatListResponseDtoImplToJson(
        _$ChatListResponseDtoImpl instance) =>
    <String, dynamic>{
      'total': instance.total,
      'conversations': instance.conversations,
    };

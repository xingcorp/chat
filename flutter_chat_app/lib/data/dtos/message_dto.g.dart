// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageDtoImpl _$$MessageDtoImplFromJson(Map<String, dynamic> json) =>
    _$MessageDtoImpl(
      id: json['id'] as String,
      content: json['message'] as String,
      urls:
          (json['urls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      type: json['type'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      editAt: (json['editAt'] as num?)?.toInt(),
      deletedAt: (json['deletedAt'] as num?)?.toInt(),
      replyMessageId: json['replyMessageId'] as String?,
      replyMessage: json['replyMessage'] == null
          ? null
          : ReplyMessageDto.fromJson(
              json['replyMessage'] as Map<String, dynamic>),
      forwardedFromMessageId: json['forwardedFromMessageId'] as String?,
      forwardedFromMessage: json['forwardedFromMessage'] == null
          ? null
          : MessageDto.fromJson(
              json['forwardedFromMessage'] as Map<String, dynamic>),
      fileName: json['fileName'] as String?,
      senderId: json['senderId'] as String,
      sender: json['sender'] == null
          ? null
          : SenderDto.fromJson(json['sender'] as Map<String, dynamic>),
      chatId: json['conversationId'] as String,
      readerIds: (json['readerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((e) => ReactionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mentionTo: (json['mentionTo'] as List<dynamic>?)
              ?.map((e) => MentionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      actionType: json['actionType'] as String?,
      actorId: json['actorId'] as String?,
      actor: json['actor'] == null
          ? null
          : SenderDto.fromJson(json['actor'] as Map<String, dynamic>),
      targetUserIds: (json['targetUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      targetUsers: (json['targetUsers'] as List<dynamic>?)
              ?.map((e) => SenderDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      newValue: json['newValue'] as String?,
      oldValue: json['oldValue'] as String?,
    );

Map<String, dynamic> _$$MessageDtoImplToJson(_$MessageDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.content,
      'urls': instance.urls,
      'type': instance.type,
      'createdAt': instance.createdAt,
      'editAt': instance.editAt,
      'deletedAt': instance.deletedAt,
      'replyMessageId': instance.replyMessageId,
      'replyMessage': instance.replyMessage,
      'forwardedFromMessageId': instance.forwardedFromMessageId,
      'forwardedFromMessage': instance.forwardedFromMessage,
      'fileName': instance.fileName,
      'senderId': instance.senderId,
      'sender': instance.sender,
      'conversationId': instance.chatId,
      'readerIds': instance.readerIds,
      'reactions': instance.reactions,
      'mentionTo': instance.mentionTo,
      'actionType': instance.actionType,
      'actorId': instance.actorId,
      'actor': instance.actor,
      'targetUserIds': instance.targetUserIds,
      'targetUsers': instance.targetUsers,
      'newValue': instance.newValue,
      'oldValue': instance.oldValue,
    };

_$SenderDtoImpl _$$SenderDtoImplFromJson(Map<String, dynamic> json) =>
    _$SenderDtoImpl(
      id: json['id'] as String,
      fullName: json['fullname'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SenderDtoImplToJson(_$SenderDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullname': instance.fullName,
      'imageUrls': instance.imageUrls,
    };

_$ReplyMessageDtoImpl _$$ReplyMessageDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$ReplyMessageDtoImpl(
      id: json['id'] as String,
      content: json['message'] as String,
      type: json['type'] as String?,
      urls:
          (json['urls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      fileName: json['fileName'] as String?,
      mentionTo: (json['mentionTo'] as List<dynamic>?)
              ?.map((e) => MentionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sender: json['sender'] == null
          ? null
          : SenderDto.fromJson(json['sender'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ReplyMessageDtoImplToJson(
        _$ReplyMessageDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.content,
      'type': instance.type,
      'urls': instance.urls,
      'fileName': instance.fileName,
      'mentionTo': instance.mentionTo,
      'sender': instance.sender,
    };

_$ReactionDtoImpl _$$ReactionDtoImplFromJson(Map<String, dynamic> json) =>
    _$ReactionDtoImpl(
      code: json['code'] as String,
      reactorIds: (json['reactorIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      reactors: (json['reactors'] as List<dynamic>?)
              ?.map((e) => UserReactionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ReactionDtoImplToJson(_$ReactionDtoImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'reactorIds': instance.reactorIds,
      'reactors': instance.reactors,
    };

_$UserReactionDtoImpl _$$UserReactionDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$UserReactionDtoImpl(
      fullName: json['fullname'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$UserReactionDtoImplToJson(
        _$UserReactionDtoImpl instance) =>
    <String, dynamic>{
      'fullname': instance.fullName,
      'imageUrls': instance.imageUrls,
    };

_$MentionDtoImpl _$$MentionDtoImplFromJson(Map<String, dynamic> json) =>
    _$MentionDtoImpl(
      id: json['id'] as String,
      fullName: json['fullname'] as String,
    );

Map<String, dynamic> _$$MentionDtoImplToJson(_$MentionDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullname': instance.fullName,
    };

_$MessageListResponseDtoImpl _$$MessageListResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$MessageListResponseDtoImpl(
      lastKey: json['lastKey'] == null
          ? null
          : LastKeyDto.fromJson(json['lastKey'] as Map<String, dynamic>),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => MessageDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MessageListResponseDtoImplToJson(
        _$MessageListResponseDtoImpl instance) =>
    <String, dynamic>{
      'lastKey': instance.lastKey,
      'messages': instance.messages,
    };

_$LastKeyDtoImpl _$$LastKeyDtoImplFromJson(Map<String, dynamic> json) =>
    _$LastKeyDtoImpl(
      chatId: json['conversationId'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$$LastKeyDtoImplToJson(_$LastKeyDtoImpl instance) =>
    <String, dynamic>{
      'conversationId': instance.chatId,
      'createdAt': instance.createdAt,
    };

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';

/// Collection IDs that are safe for JavaScript
class SafeIsarIds {
  // Chat model safe IDs
  static const int chatModelId = 1000001;
  static const int chatModelServerIdIndex = 1000002;
  static const int chatModelCreatedAtIndex = 1000003;
  
  // Message model safe IDs
  static const int messageModelId = 2000001;
  static const int messageModelLocalIdIndex = 2000002;
  static const int messageModelServerIdIndex = 2000003;
  static const int messageModelChatIdIndex = 2000004;
  static const int messageModelCreatedAtIndex = 2000005;
  
  // User model safe IDs
  static const int userModelId = 3000001;
  static const int userModelServerIdIndex = 3000002;
  static const int userModelUsernameIndex = 3000003;
}

/// Creates a collection schema with web-safe IDs
CollectionSchema createWebSafeSchema({
  required String name,
  required int id,
  required int webSafeId,
  required Map<String, PropertySchema> properties,
  required Map<String, IndexSchema> indexes,
  required Map<String, LinkSchema> links,
  required Map<Type, List<int>> allOffsets,
  required CreateObj createObj,
  required SizeObj sizeObj,
  required SerializeObj serializeObj,
  required DeserializeObj deserializeObj,
  required DeserializePropObj deserializePropObj,
  required GetId getId,
  required GetLinks getLinks,
  required AttachObj attach,
}) {
  // Use web-safe ID if running on web platform
  final finalId = kIsWeb ? webSafeId : id;
  
  // Create web-safe index schemas
  final webSafeIndexes = <String, IndexSchema>{};
  indexes.forEach((name, schema) {
    if (kIsWeb) {
      // Replace index IDs with web-safe alternatives based on schema name
      int webSafeIndexId;
      switch (name) {
        case 'serverId':
          switch (finalId) {
            case SafeIsarIds.chatModelId:
              webSafeIndexId = SafeIsarIds.chatModelServerIdIndex;
              break;
            case SafeIsarIds.messageModelId:
              webSafeIndexId = SafeIsarIds.messageModelServerIdIndex;
              break;
            case SafeIsarIds.userModelId:
              webSafeIndexId = SafeIsarIds.userModelServerIdIndex;
              break;
            default:
              webSafeIndexId = 4000001; // Default safe ID
          }
          break;
        case 'localId':
          webSafeIndexId = SafeIsarIds.messageModelLocalIdIndex;
          break;
        case 'chatId':
          webSafeIndexId = SafeIsarIds.messageModelChatIdIndex;
          break;
        case 'createdAt':
          switch (finalId) {
            case SafeIsarIds.chatModelId:
              webSafeIndexId = SafeIsarIds.chatModelCreatedAtIndex;
              break;
            case SafeIsarIds.messageModelId:
              webSafeIndexId = SafeIsarIds.messageModelCreatedAtIndex;
              break;
            default:
              webSafeIndexId = 4000002; // Default safe ID
          }
          break;
        case 'username':
          webSafeIndexId = SafeIsarIds.userModelUsernameIndex;
          break;
        default:
          webSafeIndexId = 4000003 + webSafeIndexes.length; // Generate a unique safe ID
      }
      
      webSafeIndexes[name] = IndexSchema(
        id: webSafeIndexId,
        name: schema.name,
        unique: schema.unique,
        replace: schema.replace,
        properties: schema.properties,
      );
    } else {
      webSafeIndexes[name] = schema;
    }
  });
  
  return CollectionSchema(
    name: name,
    id: finalId,
    properties: properties,
    estimateSize: sizeObj,
    serialize: serializeObj,
    deserialize: deserializeObj,
    deserializeProp: deserializePropObj,
    idName: 'id',
    indexes: webSafeIndexes,
    links: links,
    embeddedSchemas: {},
    getId: getId,
    getLinks: getLinks,
    attach: attach,
    version: '3.1.0+1',
  );
}

typedef CreateObj<T> = T Function(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets);
typedef SizeObj<T> = int Function(T object, List<int> offsets, Map<Type, List<int>> allOffsets);
typedef SerializeObj<T> = void Function(T object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets);
typedef DeserializeObj<T> = T Function(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets);
typedef DeserializePropObj<T> = T Function(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets);
typedef GetId<T> = Id Function(T object);
typedef GetLinks<T> = Map<String, List<int>> Function(T object);
typedef AttachObj<T> = void Function(IsarCollection<dynamic> col, Id id, T object); 
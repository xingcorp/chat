import 'package:flutter_chat_app/data/models/isar/chat_isar_model.dart';
import 'package:flutter_chat_app/data/models/isar/chat_message_isar_model.dart';

/// **ISAR V4 CODE GENERATION TEST**
/// 
/// This file is used to trigger Isar v4 built-in code generation.
/// Import all Isar models here to ensure schemas are generated.

void testIsarGeneration() {
  // Reference models to trigger generation
  final chatModel = ChatIsarModel();
  final messageModel = ChatMessageIsarModel();
  
  print('Isar models referenced: ${chatModel.runtimeType}, ${messageModel.runtimeType}');
}

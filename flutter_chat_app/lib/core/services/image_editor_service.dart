import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Callback khi hoàn thành chỉnh sửa ảnh
typedef OnImageEdited = void Function(Uint8List editedBytes);

/// Service wrapper cho pro_image_editor
/// Cung cấp interface thống nhất để chỉnh sửa ảnh trong app
/// Hỗ trợ: Android, iOS, Web
@lazySingleton
class ImageEditorService {
  /// Mở editor để chỉnh sửa ảnh từ network URL
  /// [context] - BuildContext để điều hướng
  /// [imageUrl] - URL của ảnh cần chỉnh sửa
  /// [onComplete] - Callback khi hoàn thành chỉnh sửa
  void editNetworkImage(
    BuildContext context, {
    required String imageUrl,
    OnImageEdited? onComplete,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => kIsWeb
            ? _buildWebNetworkEditor(imageUrl, onComplete)
            : _buildMobileNetworkEditor(imageUrl, onComplete),
      ),
    );
  }

  /// Mở editor để chỉnh sửa ảnh từ local file
  /// Chỉ hoạt động trên mobile (Android/iOS)
  void editLocalFile(
    BuildContext context, {
    required File file,
    OnImageEdited? onComplete,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;

    if (kIsWeb) {
      // Web không hỗ trợ File API trực tiếp
      debugPrint('editLocalFile: Not supported on web, use editFromBytes instead');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ProImageEditor.file(
          file,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              onComplete?.call(bytes);
            },
          ),
        ),
      ),
    );
  }

  /// Mở editor để chỉnh sửa ảnh từ bytes
  /// Hỗ trợ cả mobile và web
  void editFromBytes(
    BuildContext context, {
    required Uint8List bytes,
    OnImageEdited? onComplete,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ProImageEditor.memory(
          bytes,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List editedBytes) async {
              onComplete?.call(editedBytes);
            },
          ),
        ),
      ),
    );
  }

  /// Build editor cho web (network URL)
  Widget _buildWebNetworkEditor(String imageUrl, OnImageEdited? onComplete) {
    return ProImageEditor.network(
      imageUrl,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          onComplete?.call(bytes);
        },
      ),
    );
  }

  /// Build editor cho mobile (network URL)
  Widget _buildMobileNetworkEditor(String imageUrl, OnImageEdited? onComplete) {
    return ProImageEditor.network(
      imageUrl,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          onComplete?.call(bytes);
        },
      ),
    );
  }
}

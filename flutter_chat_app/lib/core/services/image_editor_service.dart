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
  /// Tạo cấu hình I18n cho pro_image_editor
  /// pro_image_editor 11.3.0 hỗ trợ custom I18n
  I18n _createI18n(BuildContext context) {
    final locale = Localizations.localeOf(context);

    // Nếu là tiếng Việt, sử dụng Vietnamese I18n
    if (locale.languageCode == 'vi') {
      return const I18n(
        cancel: 'Hủy',
        undo: 'Hoàn tác',
        redo: 'Làm lại',
        done: 'Xong',
        remove: 'Xóa',
        doneLoadingMsg: 'Đang xử lý...',
        importStateHistoryMsg: 'Khởi tạo Editor',
        various: I18nVarious(
          loadingDialogMsg: 'Đang tải...',
          closeEditorWarningTitle: 'Đóng Editor?',
          closeEditorWarningMessage:
              'Bạn có chắc muốn đóng Editor? Các thay đổi sẽ không được lưu.',
          closeEditorWarningConfirmBtn: 'OK',
          closeEditorWarningCancelBtn: 'Hủy',
        ),
      );
    }

    // Ngôn ngữ khác dùng mặc định (tiếng Anh)
    return const I18n();
  }

  /// Mở editor để chỉnh sửa ảnh từ network URL
  void editNetworkImage(
    BuildContext context, {
    required String imageUrl,
    OnImageEdited? onComplete,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;

    final configs = ProImageEditorConfigs(
      i18n: _createI18n(context),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => kIsWeb
            ? _buildWebNetworkEditor(imageUrl, onComplete, configs)
            : _buildMobileNetworkEditor(imageUrl, onComplete, configs),
      ),
    );
  }

  /// Mở editor để chỉnh sửa ảnh từ local file
  void editLocalFile(
    BuildContext context, {
    required File file,
    OnImageEdited? onComplete,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;

    if (kIsWeb) {
      debugPrint('editLocalFile: Not supported on web, use editFromBytes instead');
      return;
    }

    final configs = ProImageEditorConfigs(
      i18n: _createI18n(context),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ProImageEditor.file(
          file,
          configs: configs,
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
  void editFromBytes(
    BuildContext context, {
    required Uint8List bytes,
    OnImageEdited? onComplete,
    VoidCallback? onCancel,
  }) {
    if (!context.mounted) return;

    final configs = ProImageEditorConfigs(
      i18n: _createI18n(context),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ProImageEditor.memory(
          bytes,
          configs: configs,
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
  Widget _buildWebNetworkEditor(
    String imageUrl,
    OnImageEdited? onComplete,
    ProImageEditorConfigs configs,
  ) {
    return ProImageEditor.network(
      imageUrl,
      configs: configs,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          onComplete?.call(bytes);
        },
      ),
    );
  }

  /// Build editor cho mobile (network URL)
  Widget _buildMobileNetworkEditor(
    String imageUrl,
    OnImageEdited? onComplete,
    ProImageEditorConfigs configs,
  ) {
    return ProImageEditor.network(
      imageUrl,
      configs: configs,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (Uint8List bytes) async {
          onComplete?.call(bytes);
        },
      ),
    );
  }
}

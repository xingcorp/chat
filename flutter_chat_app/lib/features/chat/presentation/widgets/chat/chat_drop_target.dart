import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/drop_zone_overlay.dart';
import 'package:flutter_chat_app/presentation/blocs/file_attachment/drag_over_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/file_attachment/file_attachment_bloc.dart';

/// Wraps the chat area with an OS-level drag & drop target.
///
/// On web and desktop platforms, this wraps its [child] with a [DropTarget]
/// from the `desktop_drop` package and shows a [DropZoneOverlay] when files
/// are dragged over the area.
///
/// On mobile platforms, this is a no-op passthrough.
class ChatDropTarget extends BaseStatefulWidget {
  /// The child widget (typically the chat body)
  final Widget child;

  /// BLoC for managing file attachment state
  final FileAttachmentBloc fileAttachmentBloc;

  /// Cubit for tracking drag hover state
  final DragOverCubit dragOverCubit;

  const ChatDropTarget({
    super.key,
    required this.child,
    required this.fileAttachmentBloc,
    required this.dragOverCubit,
  });

  @override
  State<ChatDropTarget> createState() => _ChatDropTargetState();
}

class _ChatDropTargetState extends BaseState<ChatDropTarget> {
  /// Whether drag & drop is supported on the current platform
  bool get _isSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (_) {
        widget.dragOverCubit.setDragOver(true);
      },
      onDragExited: (_) {
        widget.dragOverCubit.setDragOver(false);
      },
      onDragDone: (details) {
        widget.dragOverCubit.setDragOver(false);
        if (details.files.isNotEmpty) {
          widget.fileAttachmentBloc.add(
            FilesDropped(files: details.files),
          );
        }
      },
      child: Stack(
        children: [
          widget.child,

          // Drop zone overlay
          BlocBuilder<DragOverCubit, bool>(
            bloc: widget.dragOverCubit,
            builder: (context, isDragOver) {
              if (!isDragOver) return const SizedBox.shrink();
              return const Positioned.fill(
                child: DropZoneOverlay(),
              );
            },
          ),
        ],
      ),
    );
  }
}

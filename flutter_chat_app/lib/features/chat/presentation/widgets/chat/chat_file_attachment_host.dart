import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/data/services/file_validation_service.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/chat_drop_target.dart';
import 'package:flutter_chat_app/features/chat/presentation/widgets/chat/file_preview_bar.dart';
import 'package:flutter_chat_app/presentation/blocs/file_attachment/drag_over_cubit.dart';
import 'package:flutter_chat_app/presentation/blocs/file_attachment/file_attachment_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/app_snack_bar.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/feedback/feedback_type.dart';
import 'package:get_it/get_it.dart';

/// Self-contained widget that provides file attachment functionality
/// to the chat details page via drag & drop, paste, and file picker.
///
/// Wraps the chat body in a [ChatDropTarget] and provides a [FilePreviewBar]
/// that appears when files are queued for sending.
///
/// Usage in ChatDetailsPage:
/// ```dart
/// ChatFileAttachmentHost(
///   fileAttachmentBloc: _fileAttachmentBloc,
///   chatBody: yourExistingChatBody,   // the Expanded(Stack(...))
///   chatInput: yourExistingChatInput,  // the _buildMessageInputArea()
///   betweenWidgets: [typingIndicator, replyBar, editBar],
/// )
/// ```
class ChatFileAttachmentHost extends BaseStatefulWidget {
  /// The file attachment BLoC managing upload state
  final FileAttachmentBloc fileAttachmentBloc;

  /// The main chat body (message timeline with FAB)
  final Widget chatBody;

  /// The chat input area
  final Widget chatInput;

  /// Widgets between the chat body and input (typing indicator, reply bar, etc)
  final List<Widget> betweenWidgets;

  const ChatFileAttachmentHost({
    super.key,
    required this.fileAttachmentBloc,
    required this.chatBody,
    required this.chatInput,
    this.betweenWidgets = const [],
  });

  @override
  State<ChatFileAttachmentHost> createState() =>
      _ChatFileAttachmentHostState();
}

class _ChatFileAttachmentHostState
    extends BaseState<ChatFileAttachmentHost> {
  late final DragOverCubit _dragOverCubit;
  late final FileValidationService _fileValidationService;

  @override
  void initState() {
    super.initState();
    _dragOverCubit = DragOverCubit();

    final getIt = GetIt.instance;
    _fileValidationService = getIt.isRegistered<FileValidationService>()
        ? getIt<FileValidationService>()
        : FileValidationService();
  }

  @override
  void dispose() {
    _dragOverCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FileAttachmentBloc, FileAttachmentState>(
      bloc: widget.fileAttachmentBloc,
      listenWhen: (prev, curr) => prev.lastError != curr.lastError,
      listener: (context, state) {
        // Show error snackbar when validation/upload fails
        if (state.lastError != null) {
          AppSnackBar.show(
            context: context,
            message: state.lastError!,
            type: FeedbackType.error,
          );
        }
      },
      child: Column(
        children: [
          // Chat body wrapped with drop target
          Expanded(
            child: ChatDropTarget(
              fileAttachmentBloc: widget.fileAttachmentBloc,
              dragOverCubit: _dragOverCubit,
              child: widget.chatBody,
            ),
          ),

          // Between widgets (typing indicator, reply bar, edit bar)
          ...widget.betweenWidgets,

          // File preview bar (only shown when files are pending)
          BlocBuilder<FileAttachmentBloc, FileAttachmentState>(
            bloc: widget.fileAttachmentBloc,
            buildWhen: (prev, curr) =>
                prev.pendingFiles != curr.pendingFiles,
            builder: (context, state) {
              if (!state.hasFiles) return const SizedBox.shrink();

              return FilePreviewBar(
                files: state.pendingFiles,
                fileValidationService: _fileValidationService,
                remainingSlots: state.remainingSlots,
                onRemove: (localId) {
                  widget.fileAttachmentBloc.add(
                    FileRemoved(localId: localId),
                  );
                },
                onRetry: (localId) {
                  widget.fileAttachmentBloc.add(
                    UploadRetried(localId: localId),
                  );
                },
              );
            },
          ),

          // Chat input
          widget.chatInput,
        ],
      ),
    );
  }
}

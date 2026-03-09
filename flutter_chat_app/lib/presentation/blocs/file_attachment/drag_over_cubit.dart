import 'package:flutter_bloc/flutter_bloc.dart';

/// Lightweight cubit for tracking drag hover state.
///
/// Separated from [FileAttachmentBloc] so that the drag overlay
/// animation can respond instantly without rebuilding the full
/// file list on every drag-enter/exit.
class DragOverCubit extends Cubit<bool> {
  DragOverCubit() : super(false);

  /// Update the drag hover state
  void setDragOver(bool value) {
    if (state != value) {
      emit(value);
    }
  }
}

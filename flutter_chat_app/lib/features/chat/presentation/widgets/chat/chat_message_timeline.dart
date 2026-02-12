import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ChatMessageTimeline extends StatelessWidget {
  final AutoScrollController scrollController;
  final List<MessageUIState> uiMessages;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function()? onRefresh;
  final Widget Function(
    BuildContext context,
    MessageUIState uiState,
    List<MessageUIState> uiMessages,
  ) itemBuilder;

  const ChatMessageTimeline({
    super.key,
    required this.scrollController,
    required this.uiMessages,
    required this.hasMore,
    required this.isLoadingMore,
    required this.itemBuilder,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget list = LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppDimens.breakpointDesktop;

        Widget child = ListView.builder(
          controller: scrollController,
          reverse: true,
          padding: const EdgeInsets.all(AppDimens.paddingSmall),
          itemCount: uiMessages.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (hasMore && index == uiMessages.length) {
              if (!isLoadingMore) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final uiState = uiMessages[index];
            return AutoScrollTag(
              key: ValueKey(uiState.id.isNotEmpty ? uiState.id : 'item_$index'),
              controller: scrollController,
              index: index,
              child: itemBuilder(context, uiState, uiMessages),
            );
          },
        );

        if (isDesktop) {
          child = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: child,
            ),
          );
        }

        return child;
      },
    );

    if (onRefresh != null) {
      list = RefreshIndicator(
        onRefresh: onRefresh!,
        child: list,
      );
    }

    return list;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/message_ui_state.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Timeline widget that renders chat messages using [ScrollablePositionedList].
///
/// Supports programmatic scroll-to-index via [ItemScrollController],
/// visible item tracking via [ItemPositionsListener], and reverse mode
/// for chat-style bottom-to-top rendering.
class ChatMessageTimeline extends StatelessWidget {
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final ScrollOffsetController? scrollOffsetController;
  final ScrollOffsetListener? scrollOffsetListener;
  final List<MessageUIState> uiMessages;
  final bool hasMore;
  final bool isLoadingMore;
  final Widget Function(
    BuildContext context,
    MessageUIState uiState,
    List<MessageUIState> uiMessages,
  ) itemBuilder;

  const ChatMessageTimeline({
    super.key,
    required this.itemScrollController,
    required this.itemPositionsListener,
    this.scrollOffsetController,
    this.scrollOffsetListener,
    required this.uiMessages,
    required this.hasMore,
    required this.isLoadingMore,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    Widget list = LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppDimens.breakpointDesktop;
        final itemCount = uiMessages.length + (hasMore ? 1 : 0);

        Widget child = ScrollablePositionedList.separated(
          itemCount: itemCount,
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          scrollOffsetController: scrollOffsetController,
          scrollOffsetListener: scrollOffsetListener,
          reverse: true,
          padding: const EdgeInsets.all(AppDimens.paddingSmall),
          separatorBuilder: (context, index) => const SizedBox.shrink(),
          itemBuilder: (context, index) {
            // Loading indicator at the end (oldest messages edge)
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
            return itemBuilder(context, uiState, uiMessages);
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

    return list;
  }
}

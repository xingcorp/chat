import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/constants/app_icons.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:flutter_chat_app/features/chat/presentation/blocs/message_search/message_search_bloc.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_icon.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_html_content.dart';

/// Panel for searching messages within a conversation.
///
/// Uses [MessageSearchBloc] for state management with proper
/// error handling, pagination, and offline-aware messaging.
class MessageSearchPanel extends BaseStatefulWidget {
  /// Conversation ID to search in
  final String conversationId;

  /// Callback when a search result is selected
  final void Function(MessageSearchResult result)? onResultSelected;

  const MessageSearchPanel({
    super.key,
    required this.conversationId,
    this.onResultSelected,
  });

  @override
  State<MessageSearchPanel> createState() => _MessageSearchPanelState();
}

class _MessageSearchPanelState extends BaseState<MessageSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    final keyword = value.trim();

    if (keyword.length <= 1) {
      if (keyword.isEmpty) {
        context.read<MessageSearchBloc>().add(const MessageSearchEvent.clear());
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      context.read<MessageSearchBloc>().add(
            MessageSearchEvent.search(
              keyword: keyword,
              conversationId: widget.conversationId,
            ),
          );
    });
  }

  void _onSubmitted(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) return;

    _debounceTimer?.cancel();
    context.read<MessageSearchBloc>().add(
          MessageSearchEvent.search(
            keyword: keyword,
            conversationId: widget.conversationId,
          ),
        );
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<MessageSearchBloc>().add(const MessageSearchEvent.clear());
    _focusNode.requestFocus();
  }

  void _onResultTap(MessageSearchResult result) {
    widget.onResultSelected?.call(result);
    Navigator.of(context).pop();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDarkMode
                : AppColors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.radiusLarge),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(isDark),
              _buildHeader(l10n, isDark),
              _buildSearchInput(l10n, isDark),
              const SizedBox(height: AppDimens.spaceSmall),
              Expanded(
                child: GestureDetector(
                  onTap: _dismissKeyboard,
                  child: _buildBody(l10n, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: AppDimens.spaceSmall),
      width: AppDimens.spaceLarge,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDarkMode : AppColors.border,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.searchMessagesTitle,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDarkMode
                    : AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: AppIcon.svg(
              AppIcons.close,
              color: isDark
                  ? AppColors.iconDarkMode
                  : AppColors.icon,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: l10n.searchMessages,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingSmall),
            child: AppIcon.svg(
              AppIcons.search,
              color: isDark ? AppColors.iconDarkMode : AppColors.icon,
              size: 20,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: AppIcon.svg(
                    AppIcons.close,
                    color: isDark ? AppColors.iconDarkMode : AppColors.icon,
                  ),
                  onPressed: _onClearSearch,
                  tooltip: l10n.clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _onSubmitted,
        onChanged: (value) {
          safeSetState(() {});
          _onSearchChanged(value);
        },
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isDark) {
    return BlocBuilder<MessageSearchBloc, MessageSearchState>(
      builder: (context, state) {
        return state.when(
          initial: () => _buildInitialState(l10n, isDark),
          loading: (previousResults, isLoadingMore) {
            if (isLoadingMore && previousResults.isNotEmpty) {
              return _buildResultsList(
                previousResults,
                l10n,
                isDark,
                isLoadingMore: true,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
          loaded: (results, keyword, page, hasMore) {
            return _buildResultsList(
              results,
              l10n,
              isDark,
              hasMore: hasMore,
              keyword: keyword,
            );
          },
          empty: (keyword) => _buildEmptyState(l10n, isDark, keyword),
          error: (message, failure, keyword) =>
              _buildErrorState(l10n, isDark, message, failure, keyword),
        );
      },
    );
  }

  Widget _buildInitialState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.svg(
            AppIcons.search,
            size: 48,
            color: isDark ? AppColors.iconDarkMode : AppColors.icon,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          Text(
            l10n.typeToSearchMessages,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark, String keyword) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.svg(
            AppIcons.search,
            size: 48,
            color: isDark ? AppColors.iconDarkMode : AppColors.icon,
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          Text(
            l10n.noSearchResults,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    AppLocalizations l10n,
    bool isDark,
    String message,
    Failure failure,
    String? keyword,
  ) {
    final isOffline = failure is NetworkFailure || failure is ConnectionFailure;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.svg(
              isOffline ? AppIcons.wifiOff : AppIcons.errorOutline,
              size: 48,
              color: isDark ? AppColors.iconDarkMode : AppColors.icon,
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            Text(
              isOffline ? l10n.searchErrorOffline : l10n.searchErrorGeneric,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDarkMode
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            TextButton.icon(
              onPressed: () {
                if (keyword != null && keyword.isNotEmpty) {
                  context.read<MessageSearchBloc>().add(
                        MessageSearchEvent.search(
                          keyword: keyword,
                          conversationId: widget.conversationId,
                        ),
                      );
                }
              },
              icon: AppIcon.svg(AppIcons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(
    List<MessageSearchResult> results,
    AppLocalizations l10n,
    bool isDark, {
    bool hasMore = false,
    bool isLoadingMore = false,
    String? keyword,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceSmall),
      itemCount: results.length + (hasMore || isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= results.length) {
          if (isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          // Load more trigger
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context
                .read<MessageSearchBloc>()
                .add(const MessageSearchEvent.loadMore());
          });
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final result = results[index];
        return _buildResultItem(result, isDark, keyword);
      },
    );
  }

  Widget _buildResultItem(
    MessageSearchResult result,
    bool isDark,
    String? keyword,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDark
            ? AppColors.surfaceDarkMode
            : AppColors.surface,
        child: Text(
          result.senderName?.isNotEmpty == true
              ? result.senderName![0].toUpperCase()
              : '?',
          style: AppTextStyles.titleSmall.copyWith(
            color: isDark
                ? AppColors.textPrimaryDarkMode
                : AppColors.textPrimary,
          ),
        ),
      ),
      title: AppHtmlContent(
        data: result.message,
        baseStyle: AppTextStyles.bodyMedium,
        maxLines: 2,
      ),
      subtitle: Text(
        '${result.senderName ?? ''} • ${_formatDate(result.createdAt)}',
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark
              ? AppColors.textSecondaryDarkMode
              : AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _onResultTap(result),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return context.l10n.yesterday;
    } else if (diff.inDays < 7) {
      return context.l10n.daysAgo(diff.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

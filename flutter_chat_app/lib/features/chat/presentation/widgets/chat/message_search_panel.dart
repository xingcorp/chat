import 'package:flutter/material.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// Result item from message search
class MessageSearchResult {
  final String id;
  final String message;
  final String type;
  final DateTime createdAt;
  final String conversationId;
  final String? senderId;
  final String? senderName;

  const MessageSearchResult({
    required this.id,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.conversationId,
    this.senderId,
    this.senderName,
  });
}

/// Panel for searching messages within a conversation
class MessageSearchPanel extends StatefulWidget {
  /// Conversation ID to search in
  final String conversationId;
  
  /// Callback when a search result is selected
  final void Function(MessageSearchResult result)? onResultSelected;
  
  /// Callback to perform the actual search (calls backend)
  final Future<List<MessageSearchResult>> Function(String keyword)? onSearch;

  const MessageSearchPanel({
    Key? key,
    required this.conversationId,
    this.onResultSelected,
    this.onSearch,
  }) : super(key: key);

  @override
  State<MessageSearchPanel> createState() => _MessageSearchPanelState();
}

class _MessageSearchPanelState extends State<MessageSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<MessageSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _keyword = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _keyword = keyword;
    });

    try {
      if (widget.onSearch != null) {
        final results = await widget.onSearch!(keyword);
        if (mounted) {
          setState(() {
            _results = results;
            _isLoading = false;
            _hasSearched = true;
          });
        }
      } else {
        // Placeholder: no search callback provided
        if (mounted) {
          setState(() {
            _results = [];
            _isLoading = false;
            _hasSearched = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
        });
      }
    }
  }

  void _onResultTap(MessageSearchResult result) {
    if (widget.onResultSelected != null) {
      widget.onResultSelected!(result);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.searchMessages,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: l10n.searchMessages,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                            _keyword = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) {
                // Debounce search would be ideal, but for simplicity we just update UI
                setState(() {});
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Results
          Expanded(
            child: _buildResults(theme, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchMessages,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noResults,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultItem(result, theme);
      },
    );
  }

  Widget _buildResultItem(MessageSearchResult result, ThemeData theme) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          result.senderName?.isNotEmpty == true
              ? result.senderName![0].toUpperCase()
              : '?',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: _buildHighlightedText(result.message, theme),
      subtitle: Text(
        '${result.senderName ?? ''} • ${_formatDate(result.createdAt)}',
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _onResultTap(result),
    );
  }

  Widget _buildHighlightedText(String text, ThemeData theme) {
    if (_keyword.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = _keyword.toLowerCase();
    final index = lowerText.indexOf(lowerKeyword);

    if (index == -1) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (index > 0)
            TextSpan(
              text: text.substring(0, index),
              style: theme.textTheme.bodyMedium,
            ),
          TextSpan(
            text: text.substring(index, index + _keyword.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              backgroundColor: theme.colorScheme.primary.withAlpha(51),
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (index + _keyword.length < text.length)
            TextSpan(
              text: text.substring(index + _keyword.length),
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
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
      return '${diff.inDays} ${context.l10n.daysAgo(diff.inDays)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

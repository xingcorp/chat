import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';

/// User item for selection in add member panel
class SelectableUser {
  final String id;
  final String name;
  final String? avatarUrl;

  const SelectableUser({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}

/// Panel for adding members to a group chat
class AddMemberPanel extends StatefulWidget {
  /// Conversation ID to add members to
  final String conversationId;
  
  /// List of current member IDs to exclude from selection
  final List<String> currentMemberIds;
  
  /// Callback to search for users
  final Future<List<SelectableUser>> Function(String query)? onSearchUsers;
  
  /// Callback when members are selected and submitted
  final Future<bool> Function(List<String> userIds)? onAddMembers;

  const AddMemberPanel({
    Key? key,
    required this.conversationId,
    required this.currentMemberIds,
    this.onSearchUsers,
    this.onAddMembers,
  }) : super(key: key);

  @override
  State<AddMemberPanel> createState() => _AddMemberPanelState();
}

class _AddMemberPanelState extends State<AddMemberPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Set<String> _selectedUserIds = {};
  Timer? _debounceTimer;
  
  List<SelectableUser> _searchResults = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _searchQuery = '';

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

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      if (widget.onSearchUsers != null) {
        final results = await widget.onSearchUsers!(query);
        // Filter out current members
        final filteredResults = results
            .where((user) => !widget.currentMemberIds.contains(user.id))
            .toList();
        if (mounted) {
          setState(() {
            _searchResults = filteredResults;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _submitAddMembers() async {
    if (_selectedUserIds.isEmpty) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.onAddMembers != null) {
        final success = await widget.onAddMembers!(_selectedUserIds.toList());
        if (mounted) {
          if (success) {
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.errorOccurred),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
                    l10n.addMembers,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
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
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _searchQuery = '';
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
                // Debounce search - trigger after 300ms delay
                _debounceTimer?.cancel();
                setState(() {});
                if (value.trim().length > 1) {
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    _performSearch();
                  });
                }
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Selected users count
          if (_selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    l10n.selectedCount(_selectedUserIds.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Results
          Expanded(
            child: _buildResults(theme, l10n),
          ),
          
          // Submit button
          if (_selectedUserIds.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAddMembers,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(l10n.addMembers),
                  ),
                ),
              ),
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

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.search,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off,
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
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isSelected = _selectedUserIds.contains(user.id);
        return _buildUserItem(user, isSelected, theme);
      },
    );
  }

  Widget _buildUserItem(SelectableUser user, bool isSelected, ThemeData theme) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: user.avatarUrl != null 
            ? NetworkImage(user.avatarUrl!) 
            : null,
        child: user.avatarUrl == null
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
      title: Text(
        user.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) => _toggleSelection(user.id),
      ),
      onTap: () => _toggleSelection(user.id),
    );
  }
}

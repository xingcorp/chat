import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/services/emoji_shortcode_service.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/chat_slash_command_engine.dart';
import 'package:flutter_chat_app/features/chat/presentation/models/suggestion_trigger_detector.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_avatar.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';

/// Special member class for "@all" mention — mentions everyone in the group.
class AllConversationMember extends ConversationMember {
  AllConversationMember()
      : super(
          id: 'all',
          userId: 'all',
          fullName: 'All',
        );
}

/// Reusable autocomplete suggestion overlay panel.
///
/// Renders a material popup with mention/slash/shortcode suggestion tiles.
/// Used by both `MentionTextField` and `QuillMentionComposer`.
class SuggestionOverlayPanel extends StatelessWidget {
  const SuggestionOverlayPanel({
    required this.mode,
    required this.query,
    required this.filteredMembers,
    required this.filteredSlashCommands,
    required this.filteredShortcodes,
    required this.selectedIndex,
    required this.onMentionSelected,
    required this.onSlashCommandSelected,
    required this.onShortcodeSelected,
    super.key,
  });

  /// Which type of suggestion to show.
  final SuggestionMode mode;

  /// The current search query (for highlighting).
  final String query;

  /// Filtered member list (for mention mode).
  final List<ConversationMember> filteredMembers;

  /// Filtered slash command list (for slash command mode).
  final List<SlashCommandOption> filteredSlashCommands;

  /// Filtered emoji shortcode list (for shortcode mode).
  final List<EmojiShortcodeMatch> filteredShortcodes;

  /// Index of the currently keyboard-selected suggestion.
  final int selectedIndex;

  /// Called when a mention member is selected.
  final ValueChanged<ConversationMember> onMentionSelected;

  /// Called when a slash command is selected.
  final ValueChanged<SlashCommandOption> onSlashCommandSelected;

  /// Called when an emoji shortcode is selected.
  final ValueChanged<EmojiShortcodeMatch> onShortcodeSelected;

  static const double _kOverlayMaxHeight = 200;
  static const double _kTileHeight = 62;
  static const double _kShortcodeTileHeight = 48;

  int get _itemCount => switch (mode) {
        SuggestionMode.mention => filteredMembers.length,
        SuggestionMode.slashCommand => filteredSlashCommands.length,
        SuggestionMode.shortcode => filteredShortcodes.length,
      };

  @override
  Widget build(BuildContext context) {
    final isShortcodeMode = mode == SuggestionMode.shortcode;
    final tileHeight = isShortcodeMode ? _kShortcodeTileHeight : _kTileHeight;
    final double preferredHeight = math.min(
      _kOverlayMaxHeight,
      _itemCount * tileHeight,
    );

    return TextFieldTapRegion(
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).cardColor,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: preferredHeight,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemExtent: tileHeight,
            itemCount: _itemCount,
            itemBuilder: (context, index) => switch (mode) {
              SuggestionMode.mention =>
                _MentionSuggestionTile(
                  member: filteredMembers[index],
                  isSelected: index == selectedIndex,
                  query: query,
                  onTap: () => onMentionSelected(filteredMembers[index]),
                ),
              SuggestionMode.slashCommand =>
                _SlashCommandSuggestionTile(
                  command: filteredSlashCommands[index],
                  isSelected: index == selectedIndex,
                  query: query,
                  onTap: () =>
                      onSlashCommandSelected(filteredSlashCommands[index]),
                ),
              SuggestionMode.shortcode =>
                _ShortcodeSuggestionTile(
                  match: filteredShortcodes[index],
                  isSelected: index == selectedIndex,
                  onTap: () =>
                      onShortcodeSelected(filteredShortcodes[index]),
                ),
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Suggestion Tiles
// ─────────────────────────────────────────────────────────────────

class _MentionSuggestionTile extends StatelessWidget {
  const _MentionSuggestionTile({
    required this.member,
    required this.isSelected,
    required this.query,
    required this.onTap,
  });

  final ConversationMember member;
  final bool isSelected;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAllMention = member is AllConversationMember;
    final displayName = isAllMention
        ? context.l10n.mentionAllDisplayName
        : (member.fullName ?? context.l10n.unknownUser);
    final avatarUrl = member.avatarUrl?.trim();
    final department = member.departmentName?.trim() ?? '';
    final title = member.titleName?.trim() ?? '';
    final subtitle = isAllMention
        ? context.l10n.mentionEveryone
        : [
            if (department.isNotEmpty) department,
            if (title.isNotEmpty) title,
          ].join(' - ');
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        );

    return ListTile(
      dense: false,
      selected: isSelected,
      leading: isAllMention
          ? Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                color: Colors.white,
                size: 18,
              ),
            )
          : ((avatarUrl?.isNotEmpty ?? false)
              ? AppAvatar.network(
                  imageUrl: avatarUrl!,
                  size: AvatarSize.small,
                )
              : AppAvatar.initials(
                  name: displayName,
                  size: AvatarSize.small,
                )),
      title: _buildHighlightedName(
        displayName,
        query,
        titleStyle,
        Theme.of(context).colorScheme.primary,
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
            )
          : null,
      trailing: Icon(
        isAllMention ? Icons.people_outline : Icons.alternate_email,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap,
    );
  }
}

class _SlashCommandSuggestionTile extends StatelessWidget {
  const _SlashCommandSuggestionTile({
    required this.command,
    required this.isSelected,
    required this.query,
    required this.onTap,
  });

  final SlashCommandOption command;
  final bool isSelected;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        );

    return ListTile(
      dense: false,
      selected: isSelected,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        child: Icon(
          _commandIconFor(command.name),
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: _buildHighlightedName(
        '/${command.name}',
        query,
        titleStyle,
        Theme.of(context).colorScheme.primary,
      ),
      subtitle: Text(
        command.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.7),
            ),
      ),
      trailing: Text(
        command.usage,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
      onTap: onTap,
    );
  }

  IconData _commandIconFor(String commandName) {
    switch (commandName.trim().toLowerCase()) {
      case ChatSlashCommandEngine.shrugCommand:
        return Icons.sentiment_satisfied_alt_rounded;
      case ChatSlashCommandEngine.tableflipCommand:
        return Icons.flip;
      case ChatSlashCommandEngine.meCommand:
        return Icons.person_outline_rounded;
      case ChatSlashCommandEngine.muteCommand:
        return Icons.notifications_off_outlined;
      default:
        return Icons.bolt_rounded;
    }
  }
}

class _ShortcodeSuggestionTile extends StatelessWidget {
  const _ShortcodeSuggestionTile({
    required this.match,
    required this.isSelected,
    required this.onTap,
  });

  final EmojiShortcodeMatch match;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Text(
              match.emoji,
              style: const TextStyle(fontSize: 24.0),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                ':${match.shortcode}:',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────

/// Builds a [RichText] with the query substring highlighted.
Widget _buildHighlightedName(
  String fullName,
  String query,
  TextStyle? baseStyle,
  Color highlightColor,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return Text(
      fullName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }

  final lowerName = fullName.toLowerCase();
  final matchIndex = lowerName.indexOf(normalizedQuery);
  if (matchIndex < 0) {
    return Text(
      fullName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }

  final before = fullName.substring(0, matchIndex);
  final match = fullName.substring(
    matchIndex,
    matchIndex + normalizedQuery.length,
  );
  final after = fullName.substring(matchIndex + normalizedQuery.length);

  return RichText(
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    text: TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: before),
        TextSpan(
          text: match,
          style: baseStyle?.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextSpan(text: after),
      ],
    ),
  );
}

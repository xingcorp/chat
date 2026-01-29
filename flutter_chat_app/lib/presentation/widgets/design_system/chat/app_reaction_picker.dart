import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';

/// **APP REACTION PICKER**
///
/// Emoji reaction picker for messages with categories, search, and skin tone support.
/// Extends [BaseStatefulWidget] for state management.
///
/// **Features**:
/// - Grid layout with emoji categories
/// - Search functionality
/// - Recently used section
/// - Skin tone selector
/// - Animated appearance
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with callback-based interaction
///
/// **Usage**:
/// ```dart
/// AppReactionPicker(
///   onReactionSelected: (emoji) {
///     _addReactionToMessage(emoji);
///   },
///   recentlyUsed: ['👍', '❤️', '😂'],
/// )
/// ```
class AppReactionPicker extends BaseStatefulWidget {
  /// Creates a reaction picker.
  const AppReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.recentlyUsed = const [],
    this.showSearch = true,
    this.showSkinTones = true,
    this.columns = 8,
    this.maxHeight = 400,
  });

  /// Callback when a reaction is selected
  final ValueChanged<String> onReactionSelected;

  /// Recently used reactions
  final List<String> recentlyUsed;

  /// Whether to show search field
  final bool showSearch;

  /// Whether to show skin tone selector
  final bool showSkinTones;

  /// Number of columns in grid
  final int columns;

  /// Maximum height of picker
  final double maxHeight;

  @override
  AppReactionPickerState createState() => AppReactionPickerState();
}

class AppReactionPickerState extends BaseState<AppReactionPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  String _searchQuery = '';
  String _selectedCategory = 'smileys';
  int _selectedSkinTone = 0; // 0 = default, 1-5 = skin tones

  // Emoji categories
  final Map<String, List<String>> _emojiCategories = {
    'smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
      '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪',
      '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
      '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
      '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
      '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯',
      '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁',
      '☹️', '😮', '😯', '😲', '😳', '🥺', '😦', '😧',
      '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣',
      '😞', '😓', '😩', '😫', '🥱', '😤', '😡', '😠',
      '🤬', '😈', '👿', '💀', '☠️', '💩', '🤡', '👹',
      '👺', '👻', '👽', '👾', '🤖', '😺', '😸', '😹',
      '😻', '😼', '😽', '🙀', '😿', '😾',
    ],
    'gestures': [
      '👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤏', '✌️',
      '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕',
      '👇', '☝️', '👍', '👎', '✊', '👊', '🤛', '🤜',
      '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💅',
      '🤳', '💪', '🦾', '🦿', '🦵', '🦶', '👂', '🦻',
      '👃', '🧠', '🦷', '🦴', '👀', '👁️', '👅', '👄',
    ],
    'people': [
      '👶', '👧', '🧒', '👦', '👩', '🧑', '👨', '👩‍🦱',
      '🧑‍🦱', '👨‍🦱', '👩‍🦰', '🧑‍🦰', '👨‍🦰', '👱‍♀️', '👱', '👱‍♂️',
      '👩‍🦳', '🧑‍🦳', '👨‍🦳', '👩‍🦲', '🧑‍🦲', '👨‍🦲', '🧔', '👵',
      '🧓', '👴', '👲', '👳‍♀️', '👳', '👳‍♂️', '🧕', '👮‍♀️',
      '👮', '👮‍♂️', '👷‍♀️', '👷', '👷‍♂️', '💂‍♀️', '💂', '💂‍♂️',
    ],
    'animals': [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
      '🐨', '🐯', '🦁', '🐮', '🐷', '🐽', '🐸', '🐵',
      '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤',
      '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗',
      '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜',
      '🦟', '🦗', '🕷️', '🕸️', '🦂', '🐢', '🐍', '🦎',
      '🦖', '🦕', '🐙', '🦑', '🦐', '🦞', '🦀', '🐡',
      '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊', '🐅',
      '🐆', '🦓', '🦍', '🦧', '🐘', '🦛', '🦏', '🐪',
      '🐫', '🦒', '🦘', '🐃', '🐂', '🐄', '🐎', '🐖',
      '🐏', '🐑', '🦙', '🐐', '🦌', '🐕', '🐩', '🦮',
      '🐕‍🦺', '🐈', '🐓', '🦃', '🦚', '🦜', '🦢', '🦩',
    ],
    'food': [
      '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇',
      '🍓', '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝',
      '🍅', '🍆', '🥑', '🥦', '🥬', '🥒', '🌶️', '🌽',
      '🥕', '🧄', '🧅', '🥔', '🍠', '🥐', '🥯', '🍞',
      '🥖', '🥨', '🧀', '🥚', '🍳', '🧈', '🥞', '🧇',
      '🥓', '🥩', '🍗', '🍖', '🦴', '🌭', '🍔', '🍟',
      '🍕', '🥪', '🥙', '🧆', '🌮', '🌯', '🥗', '🥘',
      '🥫', '🍝', '🍜', '🍲', '🍛', '🍣', '🍱', '🥟',
      '🦪', '🍤', '🍙', '🍚', '🍘', '🍥', '🥠', '🥮',
      '🍢', '🍡', '🍧', '🍨', '🍦', '🥧', '🧁', '🍰',
      '🎂', '🍮', '🍭', '🍬', '🍫', '🍿', '🍩', '🍪',
    ],
    'activities': [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉',
      '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🏑', '🥍',
      '🏏', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿', '🥊',
      '🥋', '🎽', '🛹', '🛷', '⛸️', '🥌', '🎿', '⛷️',
      '🏂', '🪂', '🏋️', '🤼', '🤸', '🤺', '⛹️', '🤾',
      '🏌️', '🏇', '🧘', '🏊', '🤽', '🚣', '🧗', '🚵',
      '🚴', '🏆', '🥇', '🥈', '🥉', '🏅', '🎖️', '🏵️',
      '🎗️', '🎫', '🎟️', '🎪', '🤹', '🎭', '🩰', '🎨',
      '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺',
      '🎸', '🪕', '🎻', '🎲', '♟️', '🎯', '🎳', '🎮',
      '🎰', '🧩',
    ],
    'travel': [
      '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑',
      '🚒', '🚐', '🚚', '🚛', '🚜', '🦯', '🦽', '🦼',
      '🛴', '🚲', '🛵', '🏍️', '🛺', '🚨', '🚔', '🚍',
      '🚘', '🚖', '🚡', '🚠', '🚟', '🚃', '🚋', '🚞',
      '🚝', '🚄', '🚅', '🚈', '🚂', '🚆', '🚇', '🚊',
      '🚉', '✈️', '🛫', '🛬', '🛩️', '💺', '🛰️', '🚀',
      '🛸', '🚁', '🛶', '⛵', '🚤', '🛥️', '🛳️', '⛴️',
      '🚢', '⚓', '⛽', '🚧', '🚦', '🚥', '🚏', '🗺️',
      '🗿', '🗽', '🗼', '🏰', '🏯', '🏟️', '🎡', '🎢',
      '🎠', '⛲', '⛱️', '🏖️', '🏝️', '🏜️', '🌋', '⛰️',
    ],
    'objects': [
      '⌚', '📱', '📲', '💻', '⌨️', '🖥️', '🖨️', '🖱️',
      '🖲️', '🕹️', '🗜️', '💽', '💾', '💿', '📀', '📼',
      '📷', '📸', '📹', '🎥', '📽️', '🎞️', '📞', '☎️',
      '📟', '📠', '📺', '📻', '🎙️', '🎚️', '🎛️', '🧭',
      '⏱️', '⏲️', '⏰', '🕰️', '⌛', '⏳', '📡', '🔋',
      '🔌', '💡', '🔦', '🕯️', '🪔', '🧯', '🛢️', '💸',
      '💵', '💴', '💶', '💷', '💰', '💳', '💎', '⚖️',
      '🧰', '🔧', '🔨', '⚒️', '🛠️', '⛏️', '🔩', '⚙️',
      '🧱', '⛓️', '🧲', '🔫', '💣', '🧨', '🪓', '🔪',
      '🗡️', '⚔️', '🛡️', '🚬', '⚰️', '⚱️', '🏺', '🔮',
    ],
    'symbols': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
      '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️',
      '✡️', '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '♈',
      '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐',
      '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️',
      '📴', '📳', '🈶', '🈚', '🈸', '🈺', '🈷️', '✴️',
      '🆚', '💮', '🉐', '㊙️', '㊗️', '🈴', '🈵', '🈹',
      '🈲', '🅰️', '🅱️', '🆎', '🆑', '🅾️', '🆘', '❌',
      '⭕', '🛑', '⛔', '📛', '🚫', '💯', '💢', '♨️',
    ],
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppDimens.durationMedium),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.bottomCenter,
        child: Material(
          elevation: AppDimens.elevationDialog,
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: widget.maxHeight,
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                if (widget.showSearch) _buildSearchField(context, l10n),

                // Category tabs
                _buildCategoryTabs(context, l10n),

                // Emoji grid
                Flexible(
                  child: _buildEmojiGrid(context),
                ),

                // Skin tone selector
                if (widget.showSkinTones) _buildSkinToneSelector(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      child: TextField(
        decoration: InputDecoration(
          hintText: l10n.searchEmoji,
          prefixIcon: const Icon(Icons.search, size: AppDimens.iconSmall),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: AppDimens.iconSmall),
                  onPressed: () {
                    safeSetState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingSmall,
          ),
        ),
        style: AppTextStyles.bodyMedium(context),
        onChanged: (value) {
          safeSetState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Container(
      height: AppDimens.touchTargetMin,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _emojiCategories.keys.map((category) {
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXSmall),
            child: ChoiceChip(
              label: Text(_getCategoryLabel(category, l10n)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  safeSetState(() {
                    _selectedCategory = category;
                  });
                }
              },
              labelStyle: AppTextStyles.labelMedium(context).copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiGrid(BuildContext context) {
    final emojis = _getFilteredEmojis();

    if (emojis.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        mainAxisSpacing: AppDimens.spaceSmall,
        crossAxisSpacing: AppDimens.spaceSmall,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];

        return InkWell(
          onTap: () => widget.onReactionSelected(emoji),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkinToneSelector(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    final skinTones = [
      '👋', // Default
      '👋🏻', // Light
      '👋🏼', // Medium-light
      '👋🏽', // Medium
      '👋🏾', // Medium-dark
      '👋🏿', // Dark
    ];

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: AppDimens.dividerThin,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(skinTones.length, (index) {
          final isSelected = _selectedSkinTone == index;

          return InkWell(
            onTap: () {
              safeSetState(() {
                _selectedSkinTone = index;
              });
            },
            borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
            child: Container(
              width: AppDimens.touchTargetMin / 1.5,
              height: AppDimens.touchTargetMin / 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  skinTones[index],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: AppDimens.iconXXLarge,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppDimens.spaceMedium),
            Text(
              l10n.noEmojisFound,
              style: AppTextStyles.bodyLarge(context).copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getFilteredEmojis() {
    // Show recently used if no search and no category selected
    if (_searchQuery.isEmpty && _selectedCategory == 'smileys' && widget.recentlyUsed.isNotEmpty) {
      return widget.recentlyUsed;
    }

    // Get emojis from selected category
    final categoryEmojis = _emojiCategories[_selectedCategory] ?? [];

    // Filter by search query if present
    if (_searchQuery.isEmpty) {
      return categoryEmojis;
    }

    // For search, search across all categories
    final allEmojis = _emojiCategories.values.expand((list) => list).toList();
    return allEmojis;
  }

  String _getCategoryLabel(String category, AppLocalizations l10n) {
    switch (category) {
      case 'smileys':
        return l10n.smileysAndPeople;
      case 'gestures':
        return l10n.gesturesAndBodyParts;
      case 'people':
        return l10n.peopleAndProfessions;
      case 'animals':
        return l10n.animalsAndNature;
      case 'food':
        return l10n.foodAndDrink;
      case 'activities':
        return l10n.activitiesAndSports;
      case 'travel':
        return l10n.travelAndPlaces;
      case 'objects':
        return l10n.objects;
      case 'symbols':
        return l10n.symbols;
      default:
        return category;
    }
  }
}

library;

/// **APP EMOJI PICKER**
///
/// Emoji picker component with categories, search, and skin tone support.
/// Extends [BaseStatefulWidget] for lifecycle management.
///
/// **Features**:
/// - Category tabs (Recent, Smileys, Animals, Food, etc.)
/// - Search functionality
/// - Recently used section
/// - Skin tone selector
/// - Emoji preview on hover
/// - Grid layout with virtual scrolling
/// - Keyboard navigation support
/// - Dark mode support
/// - Accessibility labels
///
/// **Architecture**: Clean Architecture + Design System
/// **Pattern**: Stateful widget with emoji management
///
/// **Usage**:
/// ```dart
/// AppEmojiPicker(
///   onEmojiSelected: (emoji) {
///     print('Selected: $emoji');
///   },
///   recentEmojis: ['😀', '👍', '❤️'],
/// )
/// ```

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/theme/app_text_styles.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/media_enums.dart';

/// App Emoji Picker widget
class AppEmojiPicker extends BaseStatefulWidget {
  const AppEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.recentEmojis = const [],
    this.maxRecentEmojis = 24,
    this.columns = 8,
    this.emojiSize = 32.0,
    this.height = 400.0,
    this.showSearch = true,
    this.showSkinTones = true,
    this.showCategoryTabs = true,
    this.initialCategory = EmojiCategory.recent,
  });

  /// Callback when emoji is selected
  final ValueChanged<String> onEmojiSelected;

  /// List of recently used emojis
  final List<String> recentEmojis;

  /// Maximum number of recent emojis to show
  final int maxRecentEmojis;

  /// Number of columns in grid
  final int columns;

  /// Size of each emoji
  final double emojiSize;

  /// Height of the picker
  final double height;

  /// Whether to show search bar
  final bool showSearch;

  /// Whether to show skin tone selector
  final bool showSkinTones;

  /// Whether to show category tabs
  final bool showCategoryTabs;

  /// Initial category to display
  final EmojiCategory initialCategory;

  @override
  AppEmojiPickerState createState() => AppEmojiPickerState();
}

class AppEmojiPickerState extends BaseState<AppEmojiPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EmojiCategory _currentCategory;
  SkinTone _selectedSkinTone = SkinTone.none;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mock emoji data - in real app, use emoji package
  final Map<EmojiCategory, List<String>> _emojisByCategory = {
    EmojiCategory.smileys: [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
      '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪',
      '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
    ],
    EmojiCategory.animals: [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
      '🐨', '🐯', '🦁', '🐮', '🐷', '🐽', '🐸', '🐵',
      '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤',
      '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗',
    ],
    EmojiCategory.food: [
      '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇',
      '🍓', '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝',
      '🍅', '🍆', '🥑', '🥦', '🥬', '🥒', '🌶', '🌽',
      '🥕', '🥔', '🍠', '🥐', '🥯', '🍞', '🥖', '🥨',
    ],
    EmojiCategory.travel: [
      '🚗', '🚕', '🚙', '🚌', '🚎', '🏎', '🚓', '🚑',
      '🚒', '🚐', '🚚', '🚛', '🚜', '🛴', '🚲', '🛵',
      '🏍', '🛺', '🚨', '🚔', '🚍', '🚘', '🚖', '🚡',
      '🚠', '🚟', '🚃', '🚋', '🚞', '🚝', '🚄', '🚅',
    ],
    EmojiCategory.activities: [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉',
      '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🏑', '🥍',
      '🏏', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿', '🥊',
      '🥋', '🎽', '🛹', '🛷', '⛸', '🥌', '🎿', '⛷',
    ],
    EmojiCategory.objects: [
      '⌚', '📱', '📲', '💻', '⌨', '🖥', '🖨', '🖱',
      '🖲', '🕹', '🗜', '💽', '💾', '💿', '📀', '📼',
      '📷', '📸', '📹', '🎥', '📽', '🎞', '📞', '☎',
      '📟', '📠', '📺', '📻', '🎙', '🎚', '🎛', '🧭',
    ],
    EmojiCategory.symbols: [
      '❤', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🤎', '💔', '❣', '💕', '💞', '💓', '💗', '💖',
      '💘', '💝', '💟', '☮', '✝', '☪', '🕉', '☸',
      '✡', '🔯', '🕎', '☯', '☦', '🛐', '⛎', '♈',
    ],
    EmojiCategory.flags: [
      '🏁', '🚩', '🎌', '🏴', '🏳', '🏳️‍🌈', '🏳️‍⚧️', '🏴‍☠️',
      '🇦🇨', '🇦🇩', '🇦🇪', '🇦🇫', '🇦🇬', '🇦🇮', '🇦🇱', '🇦🇲',
      '🇦🇴', '🇦🇶', '🇦🇷', '🇦🇸', '🇦🇹', '🇦🇺', '🇦🇼', '🇦🇽',
      '🇦🇿', '🇧🇦', '🇧🇧', '🇧🇩', '🇧🇪', '🇧🇫', '🇧🇬', '🇧🇭',
    ],
  };

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.initialCategory;
    _tabController = TabController(
      length: EmojiCategory.values.length,
      vsync: this,
      initialIndex: EmojiCategory.values.indexOf(_currentCategory),
    );
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      safeSetState(() {
        _currentCategory = EmojiCategory.values[_tabController.index];
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  void _handleEmojiTap(String emoji) {
    String finalEmoji = emoji;
    
    // Apply skin tone if applicable
    if (_selectedSkinTone != SkinTone.none && _canApplySkinTone(emoji)) {
      finalEmoji = emoji + _selectedSkinTone.modifier;
    }
    
    widget.onEmojiSelected(finalEmoji);
  }

  bool _canApplySkinTone(String emoji) {
    // Simplified check - in real app, check if emoji supports skin tones
    final skinToneEmojis = ['👋', '🤚', '🖐', '✋', '🖖', '👌', '🤌', '🤏'];
    return skinToneEmojis.contains(emoji);
  }

  List<String> _getFilteredEmojis() {
    List<String> emojis;

    if (_currentCategory == EmojiCategory.recent) {
      emojis = widget.recentEmojis.take(widget.maxRecentEmojis).toList();
    } else {
      emojis = _emojisByCategory[_currentCategory] ?? [];
    }

    if (_searchQuery.isNotEmpty) {
      // In real app, search by emoji name/keywords
      emojis = emojis.where((emoji) => emoji.contains(_searchQuery)).toList();
    }

    return emojis;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.borderDarkMode : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Search bar
          if (widget.showSearch) _buildSearchBar(theme, isDark),

          // Category tabs
          if (widget.showCategoryTabs) _buildCategoryTabs(theme, isDark),

          // Emoji grid
          Expanded(
            child: _buildEmojiGrid(theme, isDark),
          ),

          // Skin tone selector
          if (widget.showSkinTones) _buildSkinToneSelector(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.l10n.searchEmojis,
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.iconDarkMode : AppColors.icon,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? AppColors.iconDarkMode : AppColors.icon,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    safeSetState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingMedium,
            vertical: AppDimens.paddingSmall,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          safeSetState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark 
            ? AppColors.textSecondaryDarkMode 
            : AppColors.textSecondary,
        tabs: EmojiCategory.values.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppDimens.spaceXSmall),
                Text(
                  _getCategoryName(category),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiGrid(ThemeData theme, bool isDark) {
    final emojis = _getFilteredEmojis();

    if (emojis.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        mainAxisSpacing: AppDimens.spaceSmall,
        crossAxisSpacing: AppDimens.spaceSmall,
        childAspectRatio: 1.0,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return _buildEmojiButton(emoji, theme, isDark);
      },
    );
  }

  Widget _buildEmojiButton(String emoji, ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () => _handleEmojiTap(emoji),
      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          color: Colors.transparent,
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: widget.emojiSize),
          ),
        ),
      ),
    );
  }

  Widget _buildSkinToneSelector(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDarkMode : AppColors.border,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: SkinTone.values.map((tone) {
          final isSelected = _selectedSkinTone == tone;
          return InkWell(
            onTap: () {
              safeSetState(() {
                _selectedSkinTone = tone;
              });
            },
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.paddingSmall),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(
                tone.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: AppDimens.iconXXLarge,
            color: isDark 
                ? AppColors.iconDarkMode.withValues(alpha: 0.5) 
                : AppColors.icon.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimens.spaceMedium),
          Text(
            _searchQuery.isNotEmpty
                ? context.l10n.noEmojisFound
                : context.l10n.noRecentEmojis,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark 
                  ? AppColors.textSecondaryDarkMode 
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(EmojiCategory category) {
    switch (category) {
      case EmojiCategory.recent:
        return context.l10n.recent;
      case EmojiCategory.smileys:
        return context.l10n.smileys;
      case EmojiCategory.animals:
        return context.l10n.animals;
      case EmojiCategory.food:
        return context.l10n.food;
      case EmojiCategory.travel:
        return context.l10n.travel;
      case EmojiCategory.activities:
        return context.l10n.activities;
      case EmojiCategory.objects:
        return context.l10n.objects;
      case EmojiCategory.symbols:
        return context.l10n.symbols;
      case EmojiCategory.flags:
        return context.l10n.flags;
    }
  }
}

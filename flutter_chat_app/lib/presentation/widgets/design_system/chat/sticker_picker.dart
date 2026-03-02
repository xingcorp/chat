import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/domain/entities/sticker.dart';
import 'package:flutter_chat_app/domain/repositories/i_sticker_repository.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:get_it/get_it.dart';

/// Sticker picker shown as a bottom sheet.
class StickerPickerBottomSheet extends BaseStatefulWidget {
  const StickerPickerBottomSheet({
    required this.onStickerSelected,
    this.height = 420,
    super.key,
  });

  /// Called when user selects a sticker.
  final ValueChanged<Sticker> onStickerSelected;

  /// Height of the bottom sheet content.
  final double height;

  /// Show sticker picker modal.
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<Sticker> onStickerSelected,
    double height = 420,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StickerPickerBottomSheet(
        onStickerSelected: onStickerSelected,
        height: height,
      ),
    );
  }

  @override
  State<StickerPickerBottomSheet> createState() =>
      _StickerPickerBottomSheetState();
}

class _StickerPickerBottomSheetState extends BaseState<StickerPickerBottomSheet>
    with SingleTickerProviderStateMixin {
  static const int _recentLimit = 24;

  late final IStickerRepository _stickerRepository;

  TabController? _tabController;
  List<StickerPack> _packs = const <StickerPack>[];
  List<Sticker> _recentStickers = const <Sticker>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stickerRepository = GetIt.I<IStickerRepository>();
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final packsResult = await _stickerRepository.getAvailablePacks();
    final recentResult = await _stickerRepository.getRecentlyUsed();

    final packs = packsResult.fold(
      (_) => const <StickerPack>[],
      (data) => data,
    );
    final recent = recentResult.fold(
      (_) => const <Sticker>[],
      (data) => data,
    );

    _ensureTabController((packs.length + 1).clamp(1, 99));

    safeSetState(() {
      _packs = packs;
      _recentStickers = recent;
      _isLoading = false;
    });
  }

  void _ensureTabController(int length) {
    final normalizedLength = length <= 0 ? 1 : length;

    if (_tabController == null) {
      _tabController = TabController(length: normalizedLength, vsync: this)
        ..addListener(_onTabChanged);
      return;
    }

    if (_tabController!.length == normalizedLength) {
      return;
    }

    final previousIndex = _tabController!.index;
    _tabController!
      ..removeListener(_onTabChanged)
      ..dispose();

    _tabController = TabController(
      length: normalizedLength,
      vsync: this,
      initialIndex: previousIndex.clamp(0, normalizedLength - 1),
    )..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted || _tabController == null || _tabController!.indexIsChanging) {
      return;
    }
    safeSetState(() {});
  }

  List<Sticker> _stickersForCurrentTab() {
    final index = _tabController?.index ?? 0;
    if (index == 0) {
      return _recentStickers;
    }

    final packIndex = index - 1;
    if (packIndex < 0 || packIndex >= _packs.length) {
      return const <Sticker>[];
    }

    return _packs[packIndex].stickers;
  }

  Future<void> _onStickerTap(Sticker sticker) async {
    await _stickerRepository.addToRecentlyUsed(sticker);

    if (!mounted) {
      return;
    }

    final updatedRecent = <Sticker>[
      sticker,
      ..._recentStickers.where((item) => item.code != sticker.code),
    ].take(_recentLimit).toList(growable: false);

    safeSetState(() {
      _recentStickers = updatedRecent;
    });

    widget.onStickerSelected(sticker);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _isAssetPath(String value) {
    return value.startsWith('assets/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stickers = _stickersForCurrentTab();
    final hasAnySticker = _recentStickers.isNotEmpty ||
        _packs.any((pack) => pack.stickers.isNotEmpty);

    return Container(
      height: widget.height + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusBottomSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(
                top: AppDimens.spaceSmall,
                bottom: AppDimens.spaceSmall,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppDimens.radiusCircular),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      l10n.stickers,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spaceSmall),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (!hasAnySticker)
              Expanded(
                child: Center(
                  child: AppText(
                    l10n.noStickersAvailable,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else ...[
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(
                    key: const Key('sticker_tab_recent'),
                    text: l10n.recentStickers,
                  ),
                  ..._packs.map(_buildPackTab),
                ],
              ),
              const SizedBox(height: AppDimens.spaceSmall),
              Expanded(
                child: stickers.isEmpty
                    ? Center(
                        child: AppText(
                          l10n.noStickersAvailable,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingMedium,
                          vertical: AppDimens.paddingSmall,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: AppDimens.spaceSmall,
                          mainAxisSpacing: AppDimens.spaceSmall,
                        ),
                        itemCount: stickers.length,
                        itemBuilder: (context, index) {
                          final sticker = stickers[index];
                          return GestureDetector(
                            key: Key('sticker_item_${sticker.code}'),
                            onTap: () => _onStickerTap(sticker),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusSmall),
                              ),
                              padding:
                                  const EdgeInsets.all(AppDimens.paddingXSmall),
                              child: _isAssetPath(sticker.imageUrl)
                                  ? AppImage.asset(
                                      assetPath: sticker.imageUrl,
                                      fit: BoxFit.contain,
                                    )
                                  : AppImage.network(
                                      imageUrl: sticker.imageUrl,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Tab _buildPackTab(StickerPack pack) {
    return Tab(
      key: Key('sticker_tab_${pack.id}'),
      child: Row(
        children: [
          SizedBox(
            width: AppDimens.iconSizeSmall,
            height: AppDimens.iconSizeSmall,
            child: _isAssetPath(pack.thumbnailUrl)
                ? AppImage.asset(
                    assetPath: pack.thumbnailUrl,
                    fit: BoxFit.contain,
                  )
                : AppImage.network(
                    imageUrl: pack.thumbnailUrl,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(width: AppDimens.spaceXSmall),
          AppText(
            pack.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

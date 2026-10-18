import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/sasang_theme.dart';
import '../../models/map_models.dart';
import 'map_preview.dart';
import 'owned_map.dart';

class MapModeSelector extends StatelessWidget {
  const MapModeSelector({
    required this.value,
    required this.onChanged,
    super.key,
    this.elevated = false,
    this.purchasedMaps = const [],
    this.selectedMapId,
    this.onOwnedMapChanged,
    this.previewAssets = const {},
  });

  final MapMode value;
  final ValueChanged<MapMode> onChanged;
  final bool elevated;

  /// Maps already confirmed as owned by the purchase/data layer.
  final List<OwnedMapItem> purchasedMaps;
  final String? selectedMapId;
  final ValueChanged<OwnedMapItem>? onOwnedMapChanged;
  final Map<MapMode, RegionMapAsset> previewAssets;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () => _show(context),
    child: Container(
      key: const Key('map-mode-selector-pill'),
      constraints: const BoxConstraints(maxWidth: 168),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: elevated ? .94 : .92),
        borderRadius: SasangRadii.pill,
        border: Border.all(
          color: elevated ? SasangOverlayStyle.border : SasangColors.divider,
          width: .6,
        ),
        boxShadow: elevated ? SasangOverlayStyle.shadows : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF27272A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color: Color(0xFF52525B),
          ),
        ],
      ),
    ),
  );

  Future<void> _show(BuildContext context) async {
    final ownedMaps = buildOwnedMapLibrary(purchasedMaps: purchasedMaps);
    final activeMapId = selectedMapId ?? value.storageKey;
    final selected = await showModalBottomSheet<OwnedMapItem>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .30),
      isScrollControlled: true,
      builder: (sheetContext) => _OwnedMapSheet(
        maps: ownedMaps,
        activeMapId: activeMapId,
        previewAssets: previewAssets,
        onBrowseStore: () {
          Navigator.pop(sheetContext);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pushNamed(context, '/map-store');
          });
        },
      ),
    );
    if (selected == null) return;
    if (selected.mode case final mode?) onChanged(mode);
    onOwnedMapChanged?.call(selected);
  }
}

class _OwnedMapSheet extends StatelessWidget {
  const _OwnedMapSheet({
    required this.maps,
    required this.activeMapId,
    required this.onBrowseStore,
    required this.previewAssets,
  });

  final List<OwnedMapItem> maps;
  final String activeMapId;
  final VoidCallback onBrowseStore;
  final Map<MapMode, RegionMapAsset> previewAssets;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(1);
    final bottom = math.max(mediaQuery.padding.bottom, 10).toDouble();
    final maxHeight = mediaQuery.size.height * .74;
    final defaultMaps = maps
        .where((item) => item.group == OwnedMapGroup.defaultMaps)
        .toList(growable: false);
    final purchasedMaps = maps
        .where((item) => item.group == OwnedMapGroup.purchasedMaps)
        .toList(growable: false);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        key: const Key('map-mode-sheet'),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: SasangColors.background,
          borderRadius: SasangRadii.sheetTop,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 9),
            Container(
              key: const Key('owned-map-drag-handle'),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D4D8),
                borderRadius: SasangRadii.pill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 17, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('내 지도', style: SasangTypography.sheetTitle),
                        const SizedBox(height: 5),
                        Text(
                          '보유한 지도 ${maps.length}개',
                          key: const Key('owned-map-count'),
                          style: const TextStyle(
                            color: SasangColors.secondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    key: const Key('owned-map-close-button'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 19,
                      color: SasangColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                key: const Key('owned-map-scroll-view'),
                padding: const EdgeInsets.fromLTRB(20, 3, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OwnedMapGroup(
                      title: '기본 지도',
                      showTitle: purchasedMaps.isNotEmpty,
                      maps: defaultMaps,
                      activeMapId: activeMapId,
                      previewAssets: previewAssets,
                    ),
                    if (purchasedMaps.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _OwnedMapGroup(
                        title: '추가 지도',
                        showTitle: true,
                        maps: purchasedMaps,
                        activeMapId: activeMapId,
                        previewAssets: previewAssets,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: SasangColors.background,
                border: Border(
                  top: BorderSide(color: SasangColors.border, width: .6),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 7, 20, bottom),
              child: SizedBox(
                width: double.infinity,
                height: 48 + math.max(0.0, textScale - 1) * 18,
                child: CupertinoButton(
                  key: const Key('map-store-browse-button'),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: onBrowseStore,
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          '새로운 지도 둘러보기',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SasangColors.accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnedMapGroup extends StatelessWidget {
  const _OwnedMapGroup({
    required this.title,
    required this.showTitle,
    required this.maps,
    required this.activeMapId,
    required this.previewAssets,
  });

  final String title;
  final bool showTitle;
  final List<OwnedMapItem> maps;
  final String activeMapId;
  final Map<MapMode, RegionMapAsset> previewAssets;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardHeight = 174.0 + math.max(0.0, textScale - 1) * 42;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 11),
            child: Text(
              title,
              style: const TextStyle(
                color: SasangColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: maps.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) {
            final map = maps[index];
            return _OwnedMapCard(
              map: map,
              selected: map.id == activeMapId,
              previewAsset: previewAssets[map.previewMode],
              onPressed: () => Navigator.pop(context, map),
            );
          },
        ),
      ],
    );
  }
}

class _OwnedMapCard extends StatelessWidget {
  const _OwnedMapCard({
    required this.map,
    required this.selected,
    required this.previewAsset,
    required this.onPressed,
  });

  final OwnedMapItem map;
  final bool selected;
  final RegionMapAsset? previewAsset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    borderRadius: SasangRadii.selectionCard,
    onPressed: onPressed,
    child: Container(
      key: Key('map-mode-card-${map.id}'),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: SasangRadii.selectionCard,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: SasangRadii.selectionCard,
        border: Border.all(
          color: selected
              ? SasangColors.accent.withValues(alpha: .72)
              : SasangColors.border,
          width: selected ? 1 : .7,
        ),
      ),
      child: ClipRRect(
        key: Key('map-mode-preview-clip-${map.id}'),
        borderRadius: SasangRadii.selectionCard,
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 96,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: MapPreview(
                        mode: map.previewMode,
                        countryCode: map.countryCode,
                        asset: previewAsset,
                      ),
                    ),
                    if (selected)
                      const Positioned(
                        right: 10,
                        top: 9,
                        child: Text(
                          '사용 중',
                          key: Key('owned-map-active-badge'),
                          style: TextStyle(
                            color: SasangColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
                child: Text(
                  map.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SasangColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Text(
                  map.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SasangColors.secondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

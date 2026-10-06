import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';
import '../core/storage/sasang_storage.dart';
import '../core/layout/sasang_layout.dart';
import '../features/map/map_mode_selector.dart';
import '../features/map/map_repository.dart';
import '../features/map/region_map_view.dart';
import '../features/photos/photo_date.dart';
import '../features/photos/photo_date_dialog.dart';
import '../features/photos/photo_picker_service.dart';
import '../features/share/map_share_service.dart';
import '../features/state/sasang_state.dart';
import '../models/map_models.dart';
import '../widgets/ad_banner.dart';
import '../widgets/sasang_ui.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({required this.state, super.key});
  final SasangState state;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

String regionDisplaySubtitle(MapRegion region, MapMode mode) {
  final provinceName = region.provinceName?.trim();
  if (provinceName != null && provinceName.isNotEmpty) return provinceName;
  final englishName = region.englishName?.trim();
  if (mode == MapMode.world &&
      englishName != null &&
      englishName.isNotEmpty &&
      englishName != region.name) {
    return englishName;
  }
  return mode == MapMode.korea ? '대한민국' : '세계 지도';
}

class _MapScreenState extends State<MapScreen> {
  final _maps = MapRepository();
  final _picker = PhotoPickerService();
  final _search = TextEditingController();
  final Map<MapMode, RegionMapAsset> _mapAssets = {};
  late final Map<MapMode, Future<RegionMapAsset>> _mapLoads;
  late final MapShareService _shareService;
  bool _saving = false;
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    _shareService = MapShareService(widget.state.storage);
    _mapLoads = {for (final mode in MapMode.values) mode: _maps.load(mode)};
    for (final mode in MapMode.values) {
      unawaited(_rememberMapAsset(mode));
    }
  }

  Future<void> _rememberMapAsset(MapMode mode) async {
    try {
      final asset = await _mapLoads[mode]!;
      if (!mounted) return;
      setState(() => _mapAssets[mode] = asset);
    } on Object {
      // The persistent map layer presents the asset loading failure.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adShown) {
      _adShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAdSheet());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _showAdSheet() => showSasangSheet<void>(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdBanner(placement: AdPlacement.home),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '닫기',
              style: TextStyle(
                color: SasangColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _pickPhoto(MapRegion region) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final picked = await _picker.pick();
      if (picked == null || !mounted) return;
      final metadataDate = await readPhotoTakenDate(picked.file);
      final now = DateTime.now();
      final validMetadata = metadataDate != null && !metadataDate.isAfter(now);
      if (!mounted) return;
      final selectedDate = await showPhotoDateDialog(
        context,
        photo: picked.file,
        initialDate: validMetadata ? metadataDate : now,
        dateFromMetadata: validMetadata,
      );
      if (selectedDate == null) return;
      final saved = await widget.state.storage.copyImage(
        picked.file,
        'photos',
        '${widget.state.mode.storageKey}-${region.code}',
      );
      widget.state.setRegionPhoto(
        widget.state.mode,
        region.code,
        RegionPhoto(
          id: picked.id,
          uri: saved.uri.toString(),
          width: picked.width,
          height: picked.height,
          scale: 1,
          offsetX: 0,
          offsetY: 0,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          takenAt: photoDateKey(selectedDate),
        ),
      );
    } on Object catch (error) {
      if (mounted) _showError('사진을 추가할 수 없어요', error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String title, Object error) => showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(error.toString()),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  Future<void> _openShareSheet(RegionMapAsset map, MapMode mode) async {
    final hasPhotos = widget.state.regionPhotos.keys.any(
      (key) => key.startsWith('${mode.storageKey}:'),
    );
    if (!hasPhotos) {
      _showError('공유할 여행 기록이 없어요', '지도에 사진을 먼저 추가해 주세요.');
      return;
    }
    final format = await showSasangSheet<MapShareFormat>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SizedBox(
              width: 36,
              child: Divider(thickness: 4, color: Color(0xFFD4D4D8)),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '여행 지도 공유',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            '사진 보관함에 저장한 뒤 Instagram을 포함한 다른 앱으로 공유할 수 있어요.',
            style: TextStyle(color: SasangColors.secondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          _ShareOptionRow(
            key: const Key('share-map-image'),
            icon: CupertinoIcons.photo,
            title: '사진으로 내보내기',
            subtitle: '9:16 여행 지도 · 방문 비율 포함',
            onTap: () => Navigator.pop(context, MapShareFormat.image),
          ),
          const SizedBox(height: 10),
          _ShareOptionRow(
            key: const Key('share-map-video'),
            icon: CupertinoIcons.play_rectangle,
            title: '타임라인 영상으로 내보내기',
            subtitle: '촬영일 순으로 지도가 채워지는 9:16 MP4',
            onTap: () => Navigator.pop(context, MapShareFormat.video),
          ),
        ],
      ),
    );
    if (format == null || !mounted) return;
    await _exportMap(map: map, mode: mode, format: format);
  }

  Future<void> _exportMap({
    required RegionMapAsset map,
    required MapMode mode,
    required MapShareFormat format,
  }) async {
    final progress = ValueNotifier<double>(0);
    final dialogReady = Completer<void>();
    BuildContext? exportDialogContext;
    unawaited(
      showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          exportDialogContext = dialogContext;
          if (!dialogReady.isCompleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!dialogReady.isCompleted) dialogReady.complete();
            });
          }
          return ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) => CupertinoAlertDialog(
              title: Text(
                format == MapShareFormat.image
                    ? '여행 지도를 만드는 중'
                    : '여행 타임라인을 만드는 중',
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    CupertinoActivityIndicator(radius: 12 + value * 2),
                    const SizedBox(height: 12),
                    Text(
                      format == MapShareFormat.image
                          ? '사진을 정리하고 있어요.'
                          : '${(value * 100).floor()}% 진행됐어요.',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    await dialogReady.future;
    try {
      final result = format == MapShareFormat.image
          ? await _shareService.exportImage(
              asset: map,
              mode: mode,
              photos: widget.state.regionPhotos,
            )
          : await _shareService.exportTimelineVideo(
              asset: map,
              mode: mode,
              photos: widget.state.regionPhotos,
              onProgress: (value) => progress.value = value,
            );
      if (!mounted) return;
      final dialogContext = exportDialogContext;
      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? Rect.fromLTWH(0, 0, MediaQuery.sizeOf(context).width, 1)
          : box.localToGlobal(Offset.zero) & box.size;
      if (!result.savedToGallery && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 보관함에 저장하지 못했지만 바로 공유할 수 있어요.')),
        );
      }
      await _shareService.share(result, origin);
    } on Object catch (error) {
      if (!mounted) return;
      final dialogContext = exportDialogContext;
      if (dialogContext != null && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      _showError('내보내기를 완료하지 못했어요', error);
    } finally {
      progress.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.state.mode;
    final map = _mapAssets[mode];
    final selected = map?.regions
        .where((region) => region.code == widget.state.selectedRegionCode)
        .firstOrNull;
    final query = _search.text.trim().toLowerCase();
    final results = query.isEmpty || map == null
        ? const <MapRegion>[]
        : map.regions
              .where(
                (region) =>
                    '${region.name} ${region.englishName ?? ''} ${region.provinceName ?? ''}'
                        .toLowerCase()
                        .contains(query),
              )
              .take(6)
              .toList();
    final count =
        map?.regions
            .where(
              (region) => widget.state.regionPhotos.containsKey(
                regionPhotoKey(mode, region.code),
              ),
            )
            .length ??
        0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomOverlayOffset = sasangMapOverlayBottomOffset(safeBottom);
    return Stack(
      children: [
        Positioned.fill(
          // Each RegionMapView owns decoded ui.Image instances. Keeping both
          // layers mounted avoids decoding every saved photo again on a mode
          // round trip; IndexedStack paints only the active map.
          child: IndexedStack(
            index: mode.index,
            sizing: StackFit.expand,
            children: [
              for (final layerMode in MapMode.values)
                _PersistentMapLayer(
                  key: ValueKey(layerMode),
                  future: _mapLoads[layerMode]!,
                  mode: layerMode,
                  photos: widget.state.regionPhotos,
                  selectedRegionCode: widget.state.selectedRegionCode,
                  onSelectRegion: widget.state.selectRegion,
                  storage: widget.state.storage,
                ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapTopBar(
                  count: count,
                  totalCount: map?.regions.length ?? 0,
                  mode: mode,
                  onShare: map == null
                      ? null
                      : () => _openShareSheet(map, mode),
                  onModeChanged: (next) {
                    _search.clear();
                    widget.state.setMode(next);
                  },
                ),
                const SizedBox(height: 12),
                MapSearchBar(
                  controller: _search,
                  mode: mode,
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _search.clear();
                    setState(() {});
                  },
                ),
                if (query.isNotEmpty)
                  SasangSurface(
                    blur: true,
                    radius: 18,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: results.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('검색 결과 없음'),
                          )
                        : Column(
                            children: [
                              for (final region in results)
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  onPressed: () {
                                    widget.state.selectRegion(region.code);
                                    _search.text = region.name;
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.circle_fill,
                                        color: SasangColors.accent,
                                        size: 8,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              region.name,
                                              style: const TextStyle(
                                                color: SasangColors.ink,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              regionDisplaySubtitle(
                                                region,
                                                mode,
                                              ),
                                              style: const TextStyle(
                                                color: SasangColors.secondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        CupertinoIcons.chevron_forward,
                                        color: SasangColors.secondary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
              ],
            ),
          ),
        ),
        if (map != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomOverlayOffset,
            child: selected == null
                ? _selectionHint()
                : _regionControl(selected, mode),
          ),
      ],
    );
  }

  Widget _selectionHint() => const Align(
    child: SasangSurface(
      blur: true,
      radius: 22,
      padding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      child: Text(
        '지역을 선택해 기록을 시작하세요',
        style: TextStyle(color: Color(0xFF52525B), fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _regionControl(MapRegion region, MapMode mode) {
    final photo = widget.state.regionPhotos[regionPhotoKey(mode, region.code)];
    return SasangSurface(
      blur: true,
      radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          _PhotoThumb(uri: photo?.uri, storage: widget.state.storage),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  region.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  regionDisplaySubtitle(region, mode),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SasangColors.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (photo != null)
            SasangTextButton(
              onPressed: () =>
                  widget.state.removeRegionPhoto(mode, region.code),
              label: '삭제',
            ),
          SizedBox(
            width: 46,
            height: 46,
            child: CupertinoButton(
              color: SasangColors.accent,
              borderRadius: BorderRadius.circular(23),
              padding: EdgeInsets.zero,
              onPressed: _saving ? null : () => _pickPhoto(region),
              child: _saving
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : photo == null
                  ? const Icon(
                      CupertinoIcons.add,
                      color: Colors.white,
                      size: 24,
                    )
                  : const Text(
                      '수정',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersistentMapLayer extends StatelessWidget {
  const _PersistentMapLayer({
    required this.future,
    required this.mode,
    required this.photos,
    required this.selectedRegionCode,
    required this.onSelectRegion,
    required this.storage,
    super.key,
  });

  final Future<RegionMapAsset> future;
  final MapMode mode;
  final Map<String, RegionPhoto> photos;
  final String? selectedRegionCode;
  final ValueChanged<String?> onSelectRegion;
  final SasangStorage storage;

  @override
  Widget build(BuildContext context) => FutureBuilder<RegionMapAsset>(
    future: future,
    builder: (context, snapshot) {
      final asset = snapshot.data;
      if (asset != null) {
        return RegionMapView(
          asset: asset,
          mode: mode,
          photos: photos,
          selectedRegionCode: selectedRegionCode,
          onSelectRegion: onSelectRegion,
          storage: storage,
        );
      }
      if (snapshot.hasError) {
        return const Center(child: Text('지도를 불러오지 못했어요.'));
      }
      return const Center(child: CupertinoActivityIndicator());
    },
  );
}

class _PhotoThumb extends StatefulWidget {
  const _PhotoThumb({required this.uri, required this.storage});
  final String? uri;
  final SasangStorage storage;

  @override
  State<_PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<_PhotoThumb> {
  late Future<File?> _image;

  @override
  void initState() {
    super.initState();
    _image = widget.storage.resolveImage(widget.uri);
  }

  @override
  void didUpdateWidget(covariant _PhotoThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri || oldWidget.storage != widget.storage) {
      _image = widget.storage.resolveImage(widget.uri);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: _image,
    builder: (context, snapshot) => ClipOval(
      child: snapshot.data == null
          ? const ColoredBox(
              color: SasangColors.accent,
              child: SizedBox(width: 42, height: 42),
            )
          : Image.file(
              snapshot.data!,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
            ),
    ),
  );
}

class MapTopBar extends StatelessWidget {
  const MapTopBar({
    required this.count,
    required this.totalCount,
    required this.mode,
    required this.onShare,
    required this.onModeChanged,
    super.key,
  });

  final int count;
  final int totalCount;
  final MapMode mode;
  final VoidCallback? onShare;
  final ValueChanged<MapMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final percentage = travelProgressPercent(count, totalCount);
    final unit = mode == MapMode.korea ? '지역' : '국가';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          label: '현재 지도 $totalCount개 $unit 중 $count개 여행, $percentage퍼센트',
          button: false,
          child: Container(
            key: const Key('map-record-summary'),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: SasangOverlayStyle.border, width: .6),
              boxShadow: SasangOverlayStyle.shadows,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count개 $unit',
                  key: const Key('map-record-count'),
                  style: const TextStyle(
                    color: SasangColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '·',
                  style: TextStyle(
                    color: Color(0xFFB4B4BA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$percentage%',
                  key: const Key('map-travel-percentage'),
                  style: const TextStyle(
                    color: SasangColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: SasangSurface(
                blur: true,
                radius: 19,
                padding: EdgeInsets.zero,
                child: CupertinoButton(
                  key: const Key('map-share-button'),
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(19),
                  onPressed: onShare,
                  child: const Icon(
                    CupertinoIcons.share,
                    size: 18,
                    color: SasangColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            MapModeSelector(
              value: mode,
              onChanged: onModeChanged,
              elevated: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareOptionRow extends StatelessWidget {
  const _ShareOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SasangSurface(
    radius: 18,
    child: CupertinoButton(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onPressed: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: SasangColors.accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SasangColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SasangColors.secondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 17,
            color: SasangColors.secondary,
          ),
        ],
      ),
    ),
  );
}

int travelProgressPercent(int visitedCount, int totalCount) {
  if (totalCount <= 0 || visitedCount <= 0) return 0;
  final safeVisitedCount = visitedCount.clamp(0, totalCount);
  return (safeVisitedCount * 100 / totalCount).floor();
}

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    required this.controller,
    required this.mode,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final MapMode mode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => TapRegion(
    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    child: SizedBox(
      height: 46,
      child: SasangSurface(
        blur: true,
        radius: 23,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: CupertinoSearchTextField(
          key: const Key('map-search-field'),
          controller: controller,
          onChanged: onChanged,
          placeholder: mode == MapMode.korea ? '지역 이름 검색' : '국가 이름 검색',
          backgroundColor: Colors.transparent,
          itemColor: const Color(0xFF8E8E93),
          itemSize: 17,
          style: const TextStyle(
            color: SasangColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          placeholderStyle: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onSuffixTap: onClear,
        ),
      ),
    ),
  );
}

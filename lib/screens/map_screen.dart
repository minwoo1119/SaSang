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
import '../features/photos/photo_picker_service.dart';
import '../features/photos/region_photo_album_sheet.dart';
import '../features/photos/region_photo_flow.dart';
import '../features/share/map_share_service.dart';
import '../features/state/sasang_state.dart';
import '../models/map_models.dart';
import '../widgets/ad_banner.dart';
import '../widgets/sasang_ui.dart';

enum _ExportDestination { gallery, share }

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
  MapExportProgress? _exportProgress;
  MapExportCancellationToken? _exportCancellationToken;
  ({RegionMapAsset map, MapMode mode})? _videoRetry;

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
      final mode = widget.state.mode;
      final photo = await pickRegionPhoto(
        context: context,
        picker: _picker,
        storage: widget.state.storage,
        mode: mode,
        region: region,
      );
      if (photo != null) widget.state.addRegionPhoto(mode, region.code, photo);
    } on Object catch (error) {
      if (mounted) _showError('사진을 추가할 수 없어요', error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openRegionAlbum(MapRegion region, MapMode mode) =>
      showRegionPhotoAlbumSheet(
        context: context,
        state: widget.state,
        mode: mode,
        region: region,
        onAdd: () => _pickPhoto(region),
      );

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
    final format = await showSasangExportFormatPicker(context);
    if (format == null || !mounted) return;
    await _exportMap(map: map, mode: mode, format: format);
  }

  Future<void> _exportMap({
    required RegionMapAsset map,
    required MapMode mode,
    required MapShareFormat format,
  }) async {
    if (_exportProgress != null) return;
    final isVideo = format == MapShareFormat.video;
    final cancellationToken = isVideo ? MapExportCancellationToken() : null;
    if (isVideo) {
      setState(() {
        _exportProgress = const MapExportProgress(MapExportPhase.preparing);
        _exportCancellationToken = cancellationToken;
        _videoRetry = (map: map, mode: mode);
      });
    }
    try {
      final result = format == MapShareFormat.image
          ? await _shareService.exportImage(
              asset: map,
              mode: mode,
              photos: widget.state.regionPhotos,
              saveToGallery: false,
            )
          : await _shareService.exportTimelineVideo(
              asset: map,
              mode: mode,
              photos: widget.state.regionPhotos,
              albums: widget.state.regionPhotoAlbums,
              cancellationToken: cancellationToken,
              onProgress: (value) {
                if (mounted) setState(() => _exportProgress = value);
              },
              saveToGallery: false,
            );
      if (!mounted) return;
      if (isVideo) setState(_clearExportState);
      await _completeExport(result, format);
    } on MapExportCancelledException {
      if (mounted) setState(_clearExportState);
    } on Object catch (error) {
      if (!mounted) return;
      if (isVideo) {
        setState(() {
          _exportProgress = const MapExportProgress(MapExportPhase.failed);
          _exportCancellationToken = null;
        });
      } else {
        _showError('내보내기를 완료하지 못했어요', error);
      }
    }
  }

  void _clearExportState() {
    _exportProgress = null;
    _exportCancellationToken = null;
    _videoRetry = null;
  }

  void _cancelExport() {
    _exportCancellationToken?.cancel();
    setState(() {
      _exportProgress = const MapExportProgress(MapExportPhase.cancelled);
      _exportCancellationToken = null;
    });
  }

  void _retryVideoExport() {
    final retry = _videoRetry;
    if (retry == null) return;
    setState(_clearExportState);
    unawaited(
      _exportMap(
        map: retry.map,
        mode: retry.mode,
        format: MapShareFormat.video,
      ),
    );
  }

  Future<void> _completeExport(
    MapShareResult result,
    MapShareFormat format,
  ) async {
    final destination = await _showSasangExportDestinationPicker(context);
    if (destination == null || !mounted) return;
    if (destination == _ExportDestination.gallery) {
      final saved = await _shareService.saveToGallery(result.file, format);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? '사진 보관함에 저장했어요.' : '사진 보관함에 저장하지 못했어요.'),
        ),
      );
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? Rect.fromLTWH(0, 0, MediaQuery.sizeOf(context).width, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    await _shareService.share(result, origin);
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
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: MapSearchResults(
                      results: results,
                      mode: mode,
                      onSelected: (region) {
                        widget.state.selectRegion(region.code);
                        _search.text = region.name;
                        FocusScope.of(context).unfocus();
                      },
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
            child: _exportProgress != null
                ? MapExportFloatingProgress(
                    progress: _exportProgress!,
                    onCancel:
                        _exportCancellationToken == null ||
                            _exportProgress!.phase == MapExportPhase.encoding
                        ? null
                        : _cancelExport,
                    onRetry: _exportProgress!.phase == MapExportPhase.failed
                        ? _retryVideoExport
                        : null,
                    onClose:
                        _exportProgress!.phase == MapExportPhase.failed ||
                            _exportProgress!.phase == MapExportPhase.cancelled
                        ? () => setState(_clearExportState)
                        : null,
                  )
                : selected == null
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
    final photoCount =
        widget.state.regionAlbum(mode, region.code)?.photos.length ?? 0;
    return CupertinoButton(
      key: const Key('selected-region-album-button'),
      padding: EdgeInsets.zero,
      onPressed: () => _openRegionAlbum(region, mode),
      child: SasangSurface(
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
                      color: SasangColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    photoCount == 0 ? '눌러서 사진 추가' : '$photoCount장의 여행 사진',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SasangColors.secondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (photoCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x14007AFF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '$photoCount장',
                  style: const TextStyle(
                    color: SasangColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: SasangColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                  size: 21,
                ),
              ),
            const SizedBox(width: 5),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: Color(0xFFB4B4BA),
              size: 15,
            ),
          ],
        ),
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

Future<MapShareFormat?> showSasangExportFormatPicker(BuildContext context) =>
    _showSasangChoiceSheet<MapShareFormat>(
      context: context,
      title: '여행 지도 내보내기',
      description: '내 여행을 원하는 형식으로 남겨보세요.',
      choices: const [
        (
          value: MapShareFormat.image,
          label: '사진으로 내보내기',
          description: '방문한 지역과 비율을 이미지로 저장',
        ),
        (
          value: MapShareFormat.video,
          label: '영상으로 내보내기',
          description: '방문 기록을 시간순 영상으로 저장',
        ),
      ],
      keys: const [Key('share-map-image'), Key('share-map-video')],
    );

@Deprecated('Use showSasangExportFormatPicker for the shared custom design.')
Future<MapShareFormat?> showAdaptiveExportFormatPicker(BuildContext context) =>
    showSasangExportFormatPicker(context);

Future<_ExportDestination?> _showSasangExportDestinationPicker(
  BuildContext context,
) => _showSasangChoiceSheet<_ExportDestination>(
  context: context,
  title: '내보내기 완료',
  description: '완성된 여행 지도를 어디에 남길까요?',
  choices: const [
    (
      value: _ExportDestination.gallery,
      label: '사진 보관함에 저장',
      description: '기기의 사진 보관함에 안전하게 저장',
    ),
    (
      value: _ExportDestination.share,
      label: '다른 앱으로 공유',
      description: '메시지나 다른 앱으로 바로 보내기',
    ),
  ],
);

Future<T?> _showSasangChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required String description,
  required List<({T value, String label, String description})> choices,
  List<Key> keys = const [],
}) {
  var selectionMade = false;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .20),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colors = theme.colorScheme;
      void close([T? value]) {
        if (selectionMade) return;
        selectionMade = true;
        Navigator.pop(sheetContext, value);
      }

      return Container(
        key: const Key('sasang-export-choice-sheet'),
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .9,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 12, 30, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colors.onSurface,
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      button: true,
                      label: '내보내기 선택 닫기',
                      excludeSemantics: true,
                      child: InkWell(
                        key: const Key('close-export-choice-sheet'),
                        borderRadius: BorderRadius.circular(20),
                        onTap: close,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          child: Text(
                            '닫기',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 34),
                for (var index = 0; index < choices.length; index++) ...[
                  if (index > 0)
                    Divider(
                      key: Key('export-choice-divider-$index'),
                      height: 1,
                      thickness: 1,
                      color: colors.outlineVariant,
                    ),
                  Material(
                    color: Colors.transparent,
                    child: Semantics(
                      button: true,
                      label:
                          '${choices[index].label}. ${choices[index].description}',
                      excludeSemantics: true,
                      child: InkWell(
                        key: index < keys.length ? keys[index] : null,
                        onTap: () => close(choices[index].value),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 108),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    choices[index].label,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colors.onSurface,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -.2,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    choices[index].description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class MapExportFloatingProgress extends StatelessWidget {
  const MapExportFloatingProgress({
    required this.progress,
    this.onCancel,
    this.onRetry,
    this.onClose,
    super.key,
  });

  final MapExportProgress progress;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.phase == MapExportPhase.rendering
        ? progress.fraction?.clamp(0, 1).toDouble()
        : null;
    final failed = progress.phase == MapExportPhase.failed;
    final cancelled = progress.phase == MapExportPhase.cancelled;
    final title = switch (progress.phase) {
      MapExportPhase.preparing => '여행 기록을 준비하고 있어요',
      MapExportPhase.rendering => '여행 영상을 만들고 있어요',
      MapExportPhase.encoding => '영상을 저장하고 있어요',
      MapExportPhase.ready => '영상이 준비됐어요',
      MapExportPhase.cancelled => '내보내기를 중단했어요',
      MapExportPhase.failed => '영상을 만들지 못했어요',
    };
    return DecoratedBox(
      key: const Key('share-export-floating-progress'),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SasangOverlayStyle.border, width: .6),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: SasangColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (fraction != null)
                  Text(
                    '${(fraction * 100).floor()}%',
                    key: const Key('share-video-progress-percent'),
                    style: const TextStyle(
                      color: SasangColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (onCancel != null)
                  CupertinoButton(
                    key: const Key('share-export-cancel'),
                    padding: const EdgeInsets.only(left: 14),
                    minimumSize: const Size(42, 28),
                    onPressed: onCancel,
                    child: const Text('중단', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            if (failed || cancelled) ...[
              const SizedBox(height: 5),
              Text(
                failed ? '기기 저장 공간을 확인한 뒤 다시 시도해 주세요.' : '지도와 기록은 그대로 유지됩니다.',
                style: const TextStyle(
                  color: SasangColors.secondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onClose != null)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(44, 30),
                      onPressed: onClose,
                      child: const Text('닫기', style: TextStyle(fontSize: 13)),
                    ),
                  if (onRetry != null)
                    CupertinoButton(
                      key: const Key('share-export-retry'),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(44, 30),
                      onPressed: onRetry,
                      child: const Text(
                        '다시 시도',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  key: const Key('share-video-progress'),
                  value: fraction,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFE4E4E7),
                  color: SasangColors.accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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

class MapSearchResults extends StatelessWidget {
  const MapSearchResults({
    required this.results,
    required this.mode,
    required this.onSelected,
    super.key,
  });

  final List<MapRegion> results;
  final MapMode mode;
  final ValueChanged<MapRegion> onSelected;

  @override
  Widget build(BuildContext context) => SasangSurface(
    blur: true,
    radius: 20,
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: results.isEmpty
        ? const SizedBox(
            key: Key('map-search-empty'),
            height: 56,
            child: Center(
              child: Text(
                '일치하는 지역이 없어요',
                style: TextStyle(
                  color: SasangColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        : Column(
            key: const Key('map-search-results'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < results.length; index++) ...[
                _MapSearchResultRow(
                  region: results[index],
                  mode: mode,
                  onPressed: () => onSelected(results[index]),
                ),
                if (index != results.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Divider(height: 1, thickness: .6),
                  ),
              ],
            ],
          ),
  );
}

class _MapSearchResultRow extends StatelessWidget {
  const _MapSearchResultRow({
    required this.region,
    required this.mode,
    required this.onPressed,
  });

  final MapRegion region;
  final MapMode mode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: Key('map-search-result-${region.code}'),
    padding: EdgeInsets.zero,
    pressedOpacity: .55,
    onPressed: onPressed,
    child: SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SasangColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    regionDisplaySubtitle(region, mode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SasangColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: Color(0xFFAEAEB2),
              size: 13,
            ),
          ],
        ),
      ),
    ),
  );
}

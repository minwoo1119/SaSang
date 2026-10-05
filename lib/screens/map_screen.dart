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
  bool _saving = false;
  bool _adShown = false;

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

  @override
  Widget build(BuildContext context) {
    final mode = widget.state.mode;
    return FutureBuilder<RegionMapAsset>(
      future: _maps.load(mode),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final map = snapshot.data!;
        final selected = map.regions
            .where((region) => region.code == widget.state.selectedRegionCode)
            .firstOrNull;
        final query = _search.text.trim().toLowerCase();
        final results = query.isEmpty
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
        final count = map.regions
            .where(
              (region) => widget.state.regionPhotos.containsKey(
                regionPhotoKey(mode, region.code),
              ),
            )
            .length;
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        final bottomOverlayOffset = sasangMapOverlayBottomOffset(safeBottom);
        return Stack(
          children: [
            Positioned.fill(
              child: RegionMapView(
                key: ValueKey(mode),
                asset: map,
                mode: mode,
                photos: widget.state.regionPhotos,
                selectedRegionCode: widget.state.selectedRegionCode,
                onSelectRegion: widget.state.selectRegion,
                storage: widget.state.storage,
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
                      mode: mode,
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
                                                    color:
                                                        SasangColors.secondary,
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
      },
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
    required this.mode,
    required this.onModeChanged,
    super.key,
  });

  final int count;
  final MapMode mode;
  final ValueChanged<MapMode> onModeChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Semantics(
        label: '$count개의 여행 기록',
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
              const Text(
                '여행 기록',
                style: TextStyle(
                  color: SasangColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                key: const Key('map-record-count'),
                style: const TextStyle(
                  color: SasangColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      MapModeSelector(value: mode, onChanged: onModeChanged, elevated: true),
    ],
  );
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

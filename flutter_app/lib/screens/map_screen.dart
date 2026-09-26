import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/sasang_theme.dart';
import '../core/storage/sasang_storage.dart';
import '../features/map/map_mode_selector.dart';
import '../features/map/map_repository.dart';
import '../features/map/region_map_view.dart';
import '../features/photos/photo_date.dart';
import '../features/photos/photo_date_dialog.dart';
import '../features/photos/photo_picker_service.dart';
import '../features/state/sasang_state.dart';
import '../models/map_models.dart';
import '../widgets/ad_banner.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({required this.state, super.key});
  final SasangState state;

  @override
  State<MapScreen> createState() => _MapScreenState();
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

  Future<void> _showAdSheet() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 16),
        child: AdBanner(placement: AdPlacement.home),
      ),
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

  void _showError(String title, Object error) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(error.toString()),
      actions: [
        TextButton(
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
          return const Center(child: CircularProgressIndicator());
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
                        '${region.name} ${region.englishName ?? ''} ${region.provinceName ?? ''} ${region.code}'
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/main-text-design.png',
                              width: 49,
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                            Text(
                              '$count개의 여행 기록',
                              style: const TextStyle(
                                color: SasangColors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        MapModeSelector(
                          value: mode,
                          onChanged: (next) {
                            _search.clear();
                            widget.state.setMode(next);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Material(
                      elevation: 2,
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(23),
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: mode == MapMode.korea
                              ? '지역명 또는 코드'
                              : '국가명 또는 코드',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      Material(
                        elevation: 3,
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: results.isEmpty
                            ? const ListTile(title: Text('검색 결과 없음'))
                            : Column(
                                children: [
                                  for (final region in results)
                                    ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.circle,
                                        color: SasangColors.accent,
                                        size: 9,
                                      ),
                                      title: Text(
                                        region.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${region.provinceName ?? (mode == MapMode.korea ? '국내' : '해외')} · ${region.code}',
                                      ),
                                      onTap: () {
                                        widget.state.selectRegion(region.code);
                                        _search.text = region.name;
                                        FocusScope.of(context).unfocus();
                                      },
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
              right: 72,
              bottom: 94,
              child: selected == null
                  ? _selectionHint()
                  : _regionControl(selected, mode),
            ),
          ],
        );
      },
    );
  }

  Widget _selectionHint() => Align(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SasangColors.divider),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        child: Text(
          '지역을 선택해 기록을 시작하세요',
          style: TextStyle(
            color: Color(0xFF52525B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );

  Widget _regionControl(MapRegion region, MapMode mode) {
    final photo = widget.state.regionPhotos[regionPhotoKey(mode, region.code)];
    return Material(
      elevation: 3,
      color: Colors.white.withValues(alpha: 0.93),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
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
                    '${region.provinceName ?? (mode == MapMode.korea ? '대한민국' : '세계')} · ${region.code}',
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
              TextButton(
                onPressed: () =>
                    widget.state.removeRegionPhoto(mode, region.code),
                child: const Text(
                  '삭제',
                  style: TextStyle(color: SasangColors.secondary),
                ),
              ),
            SizedBox(
              width: 46,
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: _saving ? null : () => _pickPhoto(region),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        photo == null ? '+' : '수정',
                        style: TextStyle(
                          fontSize: photo == null ? 23 : 13,
                          fontWeight: FontWeight.w800,
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

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.uri, required this.storage});
  final String? uri;
  final SasangStorage storage;

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: storage.resolveImage(uri),
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

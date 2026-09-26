import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../core/storage/sasang_storage.dart';
import '../core/theme/sasang_theme.dart';
import '../features/map/map_mode_selector.dart';
import '../features/map/map_repository.dart';
import '../features/photos/photo_date.dart';
import '../features/photos/photo_date_dialog.dart';
import '../features/photos/photo_picker_service.dart';
import '../features/state/sasang_state.dart';
import '../models/map_models.dart';
import '../widgets/ad_banner.dart';
import '../widgets/sasang_ui.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({required this.state, required this.onOpenMap, super.key});
  final SasangState state;
  final VoidCallback onOpenMap;

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final _maps = MapRepository();
  final _picker = PhotoPickerService();
  bool _newest = true;

  Future<void> _manage(_Place item) async {
    await showSasangSheet<void>(
      context,
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StoredImage(
              uri: item.photo.uri,
              storage: widget.state.storage,
              height: 190,
              radius: 18,
            ),
            const SizedBox(height: 12),
            Text(
              item.region.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SasangPrimaryButton(
                onPressed: () {
                  Navigator.pop(context);
                  _replace(item);
                },
                label: '새 사진으로 변경',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SasangTextButton(
                  onPressed: () => Navigator.pop(context),
                  label: '닫기',
                ),
                SasangTextButton(
                  onPressed: () {
                    widget.state.removeRegionPhoto(item.mode, item.region.code);
                    Navigator.pop(context);
                  },
                  label: '삭제',
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _replace(_Place item) async {
    final picked = await _picker.pick();
    if (picked == null || !mounted) return;
    final metadata = await readPhotoTakenDate(picked.file);
    final now = DateTime.now();
    final valid = metadata != null && !metadata.isAfter(now);
    if (!mounted) return;
    final selected = await showPhotoDateDialog(
      context,
      photo: picked.file,
      initialDate: valid ? metadata : now,
      dateFromMetadata: valid,
    );
    if (selected == null) return;
    final saved = await widget.state.storage.copyImage(
      picked.file,
      'photos',
      '${item.mode.storageKey}-${item.region.code}',
    );
    widget.state.setRegionPhoto(
      item.mode,
      item.region.code,
      RegionPhoto(
        id: picked.id,
        uri: saved.uri.toString(),
        width: picked.width,
        height: picked.height,
        scale: 1,
        offsetX: 0,
        offsetY: 0,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        takenAt: photoDateKey(selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.state.mode;
    return SafeArea(
      child: FutureBuilder<RegionMapAsset>(
        future: _maps.load(mode),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final regions = {
            for (final region in snapshot.data!.regions) region.code: region,
          };
          final items = <_Place>[];
          for (final entry in widget.state.regionPhotos.entries) {
            final parts = entry.key.split(':');
            if (parts.length != 2 || parts.first != mode.storageKey) continue;
            final region = regions[parts.last];
            if (region != null) {
              items.add(_Place(mode, region, entry.value));
            }
          }
          items.sort((a, b) {
            final compared = regionPhotoDate(
              a.photo.takenAt,
              a.photo.createdAt,
            ).compareTo(regionPhotoDate(b.photo.takenAt, b.photo.createdAt));
            return _newest ? -compared : compared;
          });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: MapModeSelector(
                        value: mode,
                        onChanged: widget.state.setMode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      onPressed: () => setState(() => _newest = !_newest),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.arrow_up_arrow_down,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(_newest ? '최신순' : '오래된순'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
                        itemCount: items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 1) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 14),
                              child: AdBanner(placement: AdPlacement.places),
                            );
                          }
                          final actual = index > 1 ? index - 1 : index;
                          if (actual >= items.length) {
                            return const SizedBox.shrink();
                          }
                          final item = items[actual];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _manage(item),
                              child: SasangSurface(
                                radius: 20,
                                padding: EdgeInsets.zero,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _StoredImage(
                                      uri: item.photo.uri,
                                      storage: widget.state.storage,
                                      height: 220,
                                      radius: 20,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.region.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                '${item.region.provinceName ?? (mode == MapMode.korea ? '대한민국' : '해외')} · ${koreanDate(regionPhotoDate(item.photo.takenAt, item.photo.createdAt))}',
                                                style: const TextStyle(
                                                  color: SasangColors.secondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            mode == MapMode.korea ? '국내' : '해외',
                                            style: const TextStyle(
                                              color: SasangColors.accent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0x1A007AFF),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Icon(CupertinoIcons.map, color: SasangColors.accent),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '아직 기록이 없어요',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const Text(
            '지도에서 첫 사진을 추가해보세요.',
            style: TextStyle(color: SasangColors.secondary),
          ),
          const SizedBox(height: 18),
          SasangPrimaryButton(
            onPressed: widget.onOpenMap,
            label: '지도에서 시작하기',
            icon: CupertinoIcons.arrow_right,
          ),
        ],
      ),
    ),
  );
}

class _Place {
  const _Place(this.mode, this.region, this.photo);
  final MapMode mode;
  final MapRegion region;
  final RegionPhoto photo;
}

class _StoredImage extends StatelessWidget {
  const _StoredImage({
    required this.uri,
    required this.storage,
    required this.height,
    required this.radius,
  });
  final String uri;
  final SasangStorage storage;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: storage.resolveImage(uri),
    builder: (context, snapshot) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: snapshot.data == null
          ? Container(height: height, color: const Color(0xFFF4F4F5))
          : Image.file(
              snapshot.data!,
              width: double.infinity,
              height: height,
              fit: BoxFit.cover,
            ),
    ),
  );
}

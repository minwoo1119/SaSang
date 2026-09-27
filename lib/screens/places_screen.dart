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
  const PlacesScreen({
    required this.state,
    required this.onOpenMap,
    super.key,
    this.mapAsset,
  });
  final SasangState state;
  final VoidCallback onOpenMap;
  final Future<RegionMapAsset>? mapAsset;

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
        future: widget.mapAsset ?? _maps.load(mode),
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
                key: const Key('places-filter-bar'),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MapModeSelector(
                      value: mode,
                      onChanged: widget.state.setMode,
                    ),
                    const SizedBox(width: 10),
                    _SortButton(
                      newest: _newest,
                      onPressed: () => setState(() => _newest = !_newest),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                        itemCount: items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 1) {
                            return const Padding(
                              padding: EdgeInsets.fromLTRB(0, 12, 0, 20),
                              child: AdBanner(placement: AdPlacement.places),
                            );
                          }
                          final actual = index > 1 ? index - 1 : index;
                          if (actual >= items.length) {
                            return const SizedBox.shrink();
                          }
                          final item = items[actual];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () => _manage(item),
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0x1A18181B),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0F18181B),
                                      blurRadius: 14,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 1.18,
                                      child: _StoredImage(
                                        uri: item.photo.uri,
                                        storage: widget.state.storage,
                                        radius: 0,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: .5,
                                      child: ColoredBox(
                                        color: Color(0x1218181B),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        13,
                                        12,
                                        13,
                                        13,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.region.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: SasangColors.ink,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0x1A007AFF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  mode == MapMode.korea
                                                      ? '국내'
                                                      : '해외',
                                                  style: const TextStyle(
                                                    color: SasangColors.accent,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.region.provinceName ??
                                                (mode == MapMode.korea
                                                    ? '대한민국'
                                                    : '해외'),
                                            style: const TextStyle(
                                              color: Color(0xFF52525B),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            koreanDate(
                                              regionPhotoDate(
                                                item.photo.takenAt,
                                                item.photo.createdAt,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: SasangColors.secondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
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

  Widget _empty() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
    children: [
      Container(
        key: const Key('places-empty-state'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A18181B),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.map_pin_ellipse,
                color: SasangColors.accent,
                size: 25,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '아직 기록이 없어요',
              style: TextStyle(
                color: SasangColors.ink,
                fontSize: 22,
                height: 1.32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '지도에서 첫 사진을 추가해보세요.',
              style: TextStyle(
                color: SasangColors.secondary,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                borderRadius: BorderRadius.circular(16),
                color: SasangColors.accent,
                onPressed: widget.onOpenMap,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '지도에서 시작하기',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.arrow_right,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 36),
      const AdBanner(placement: AdPlacement.places),
    ],
  );
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.newest, required this.onPressed});

  final bool newest;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    key: const Key('places-sort-button'),
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: onPressed,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: SasangColors.divider, width: .6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.arrow_up_arrow_down,
            size: 13,
            color: Color(0xFF52525B),
          ),
          const SizedBox(width: 6),
          Text(
            newest ? '최신순' : '오래된순',
            style: const TextStyle(
              color: Color(0xFF27272A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
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
    required this.radius,
    this.height,
  });
  final String uri;
  final SasangStorage storage;
  final double? height;
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

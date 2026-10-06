import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../core/storage/sasang_storage.dart';
import '../core/theme/sasang_theme.dart';
import '../features/map/map_mode_selector.dart';
import '../features/map/map_repository.dart';
import '../features/photos/photo_date.dart';
import '../features/photos/photo_picker_service.dart';
import '../features/photos/region_photo_album_sheet.dart';
import '../features/photos/region_photo_flow.dart';
import '../features/state/sasang_state.dart';
import '../models/map_models.dart';
import '../widgets/ad_banner.dart';

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

  Future<void> _manage(_Place item) => showRegionPhotoAlbumSheet(
    context: context,
    state: widget.state,
    mode: item.mode,
    region: item.region,
    onAdd: () => _add(item.mode, item.region),
  );

  Future<void> _add(MapMode mode, MapRegion region) async {
    final photo = await pickRegionPhoto(
      context: context,
      picker: _picker,
      storage: widget.state.storage,
      mode: mode,
      region: region,
    );
    if (photo != null) widget.state.addRegionPhoto(mode, region.code, photo);
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
          for (final entry in widget.state.regionPhotoAlbums.entries) {
            final parts = entry.key.split(':');
            if (parts.length != 2 || parts.first != mode.storageKey) continue;
            final region = regions[parts.last];
            if (region != null && entry.value.coverPhoto != null) {
              items.add(_Place(mode, region, entry.value));
            }
          }
          items.sort((a, b) {
            final compared = a.latestDate.compareTo(b.latestDate);
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
                      elevated: true,
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
                                    color: SasangOverlayStyle.border,
                                  ),
                                  boxShadow: SasangOverlayStyle.shadows,
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
                                                  '${item.album.photos.length}장',
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
      Padding(
        key: const Key('places-empty-state'),
        padding: const EdgeInsets.fromLTRB(24, 46, 24, 38),
        child: Column(
          children: [
            const Text(
              '아직 기록이 없어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SasangColors.ink,
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w700,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '지도에 첫 사진을 남겨보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SasangColors.secondary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              key: const Key('places-empty-action'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(44, 44),
              onPressed: widget.onOpenMap,
              child: const Text(
                '지도에서 시작하기',
                style: TextStyle(
                  color: SasangColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
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
      key: const Key('places-sort-surface'),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: SasangOverlayStyle.border, width: .6),
        boxShadow: SasangOverlayStyle.shadows,
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
  const _Place(this.mode, this.region, this.album);
  final MapMode mode;
  final MapRegion region;
  final RegionPhotoAlbum album;

  RegionPhoto get photo => album.coverPhoto!;

  DateTime get latestDate => album.photos
      .map((photo) => regionPhotoDate(photo.takenAt, photo.createdAt))
      .reduce((a, b) => a.isAfter(b) ? a : b);
}

class _StoredImage extends StatelessWidget {
  const _StoredImage({
    required this.uri,
    required this.storage,
    required this.radius,
  });
  final String uri;
  final SasangStorage storage;
  final double radius;

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: storage.resolveImage(uri),
    builder: (context, snapshot) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: snapshot.data == null
          ? const ColoredBox(color: Color(0xFFF4F4F5))
          : Image.file(
              snapshot.data!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    ),
  );
}

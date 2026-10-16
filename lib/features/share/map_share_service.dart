import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_drawing/path_drawing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/storage/sasang_storage.dart';
import '../../core/theme/sasang_theme.dart';
import '../../models/map_models.dart';
import '../map/region_map_view.dart';
import '../photos/photo_date.dart';
import 'geo_route.dart';

enum MapShareFormat { image, video }

enum MapExportPhase { preparing, rendering, encoding, ready, cancelled, failed }

class MapExportProgress {
  const MapExportProgress(this.phase, [this.fraction]);

  final MapExportPhase phase;
  final double? fraction;
}

class MapExportCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw const MapExportCancelledException();
  }
}

class MapExportCancelledException implements Exception {
  const MapExportCancelledException();

  @override
  String toString() => '영상 내보내기가 취소되었습니다.';
}

class MapShareResult {
  const MapShareResult({required this.file, required this.savedToGallery});

  final File file;
  final bool savedToGallery;
}

class MapTimelineItem {
  const MapTimelineItem({
    required this.key,
    required this.region,
    required this.photo,
  });

  final String key;
  final MapRegion region;
  final RegionPhoto photo;

  DateTime get date => regionPhotoDate(photo.takenAt, photo.createdAt);
}

List<MapTimelineItem> buildMapTimeline({
  required RegionMapAsset asset,
  required MapMode mode,
  required Map<String, RegionPhoto> photos,
  Map<String, RegionPhotoAlbum> albums = const {},
}) {
  final regions = {for (final region in asset.regions) region.code: region};
  final prefix = '${mode.storageKey}:';
  final items = <MapTimelineItem>[];
  for (final entry in albums.entries) {
    if (!entry.key.startsWith(prefix)) continue;
    final region = regions[entry.key.substring(prefix.length)];
    if (region == null) continue;
    for (final photo in entry.value.photos) {
      items.add(MapTimelineItem(key: entry.key, region: region, photo: photo));
    }
  }
  for (final entry in photos.entries) {
    if (!entry.key.startsWith(prefix) || albums.containsKey(entry.key)) {
      continue;
    }
    final region = regions[entry.key.substring(prefix.length)];
    if (region == null) continue;
    items.add(
      MapTimelineItem(key: entry.key, region: region, photo: entry.value),
    );
  }
  items.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byCreatedAt = a.photo.createdAt.compareTo(b.photo.createdAt);
    return byCreatedAt != 0 ? byCreatedAt : a.key.compareTo(b.key);
  });
  return items;
}

int mapTravelPercentage(int visitedCount, int totalCount) {
  if (visitedCount <= 0 || totalCount <= 0) return 0;
  return (visitedCount.clamp(0, totalCount) * 100 / totalCount).floor();
}

double mapTravelProgress({
  required RegionMapAsset asset,
  required MapMode mode,
  required Map<String, RegionPhoto> photos,
}) {
  if (asset.regions.isEmpty) return 0;
  return buildMapTimeline(asset: asset, mode: mode, photos: photos).length /
      asset.regions.length;
}

class MapShareService {
  MapShareService(this.storage);

  static const _timelineChannel = MethodChannel('com.sasang.app/timeline');
  static const _videoWidth = 720;
  static const _videoHeight = 1280;
  static const _videoFps = 30;

  final SasangStorage storage;

  Future<MapShareResult> exportImage({
    required RegionMapAsset asset,
    required MapMode mode,
    required Map<String, RegionPhoto> photos,
    bool saveToGallery = true,
  }) async {
    final renderer = await _MapShareRenderer.create(
      asset: asset,
      mode: mode,
      photos: photos,
      storage: storage,
    );
    try {
      final travelProgress = mapTravelProgress(
        asset: asset,
        mode: mode,
        photos: photos,
      );
      final bytes = await renderer.renderPng(
        width: 1080,
        height: 1920,
        visiblePhotos: photos,
        progress: travelProgress,
      );
      final directory = await getTemporaryDirectory();
      final file = File(
        p.join(
          directory.path,
          'sasang-map-${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(bytes, flush: true);
      return MapShareResult(
        file: file,
        savedToGallery: saveToGallery
            ? await this.saveToGallery(file, MapShareFormat.image)
            : false,
      );
    } finally {
      renderer.dispose();
    }
  }

  Future<MapShareResult> exportTimelineVideo({
    required RegionMapAsset asset,
    required MapMode mode,
    required Map<String, RegionPhoto> photos,
    Map<String, RegionPhotoAlbum> albums = const {},
    ValueChanged<MapExportProgress>? onProgress,
    MapExportCancellationToken? cancellationToken,
    bool saveToGallery = true,
  }) async {
    onProgress?.call(const MapExportProgress(MapExportPhase.preparing));
    final snapshotPhotos = Map<String, RegionPhoto>.unmodifiable(photos);
    final snapshotAlbums = Map<String, RegionPhotoAlbum>.unmodifiable({
      for (final entry in albums.entries)
        entry.key: RegionPhotoAlbum(
          photos: List<RegionPhoto>.unmodifiable(entry.value.photos),
          coverPhotoId: entry.value.coverPhotoId,
        ),
    });
    final timeline = buildMapTimeline(
      asset: asset,
      mode: mode,
      photos: snapshotPhotos,
      albums: snapshotAlbums,
    );
    if (timeline.isEmpty) {
      throw StateError('영상으로 만들 여행 기록이 없어요.');
    }

    final temporary = await getTemporaryDirectory();
    final exportRoot = Directory(
      p.join(
        temporary.path,
        'sasang-timeline-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await exportRoot.create(recursive: true);
    final output = File(p.join(exportRoot.path, 'sasang-timeline.mp4'));
    final renderer = await _MapShareRenderer.create(
      asset: asset,
      mode: mode,
      photos: snapshotPhotos,
      albums: snapshotAlbums,
      storage: storage,
    );

    try {
      final framePaths = <String>[];
      final repeats = <int>[];
      final visible = <String, RegionPhoto>{};
      final anchors = [
        for (final item in timeline)
          const GeoAnchorResolver().resolve(
            asset: asset,
            region: item.region,
            photo: item.photo,
          ),
      ];
      final completedRoutes = <TravelRoute>[];
      final motion = timelineMotionSteps(timeline.length);
      final totalRenderFrames =
          2 + timeline.length * (motion.travelFrames + motion.revealFrames);
      var renderedFrames = 0;
      var frameIndex = 0;

      void reportRenderedFrame() {
        renderedFrames++;
        onProgress?.call(
          MapExportProgress(
            MapExportPhase.rendering,
            renderedFrames / totalRenderFrames,
          ),
        );
      }

      cancellationToken?.throwIfCancelled();
      framePaths.add(
        await _writeTimelineFrame(
          renderer: renderer,
          directory: exportRoot,
          index: frameIndex++,
          visiblePhotos: visible,
          progress: 0,
        ),
      );
      repeats.add(_videoFps);
      reportRenderedFrame();
      for (var index = 0; index < timeline.length; index++) {
        final item = timeline[index];
        final anchor = anchors[index];
        final destination = anchor.point;
        final focusZoom = regionFocusZoom(
          item.region,
          asset,
          focusBounds: anchor.focusBounds,
        );
        final isFirst = index == 0;
        final departure = isFirst ? destination : anchors[index - 1].point;
        final travelRoute = isFirst
            ? const TravelRoute([])
            : buildTravelRoute(
                departure: departure,
                destination: destination,
                asset: asset,
                mode: mode,
              );

        for (var step = 1; step <= motion.travelFrames; step++) {
          cancellationToken?.throwIfCancelled();
          final phase = _easeInOut(step / motion.travelFrames);
          final previousZoom = isFirst
              ? 1.0
              : regionFocusZoom(
                  timeline[index - 1].region,
                  asset,
                  focusBounds: anchors[index - 1].focusBounds,
                );
          final plane = travelRoute.pointAt(phase);
          framePaths.add(
            await _writeTimelineFrame(
              renderer: renderer,
              directory: exportRoot,
              index: frameIndex++,
              visiblePhotos: visible,
              progress: (index + phase * .65) / timeline.length,
              current: item,
              mapZoom: isFirst
                  ? ui.lerpDouble(1, focusZoom * .82, phase)!
                  : _travelZoom(previousZoom, focusZoom, phase),
              focusAssetPoint: isFirst
                  ? destination
                  : _cameraPointForRoute(
                      travelRoute,
                      phase,
                      asset,
                      departure,
                      destination,
                    ),
              completedRoutes: completedRoutes,
              activeRouteSegments: travelRoute.partial(phase),
              planeAssetPoint: plane,
              planeAngle: travelRoute.angleAt(phase),
            ),
          );
          repeats.add(1);
          reportRenderedFrame();
        }

        visible[item.key] = item.photo;
        if (!travelRoute.isEmpty) completedRoutes.add(travelRoute);
        for (var step = 1; step <= motion.revealFrames; step++) {
          cancellationToken?.throwIfCancelled();
          final phase = _easeOut(step / motion.revealFrames);
          framePaths.add(
            await _writeTimelineFrame(
              renderer: renderer,
              directory: exportRoot,
              index: frameIndex++,
              visiblePhotos: visible,
              progress: (index + .65 + phase * .35) / timeline.length,
              current: item,
              mapZoom: ui.lerpDouble(focusZoom * .82, focusZoom, phase)!,
              focusAssetPoint: destination,
              completedRoutes: completedRoutes,
              arrivalAssetPoint: destination,
              arrivalPulse: phase,
              photoOpacities: {item.key: phase},
            ),
          );
          repeats.add(
            1 + (step == motion.revealFrames ? motion.holdFrames : 0),
          );
          reportRenderedFrame();
        }
        await Future<void>.delayed(Duration.zero);
      }

      cancellationToken?.throwIfCancelled();
      framePaths.add(
        await _writeTimelineFrame(
          renderer: renderer,
          directory: exportRoot,
          index: frameIndex,
          visiblePhotos: visible,
          progress: 1,
          completedRoutes: completedRoutes,
        ),
      );
      repeats.add(_videoFps * 2);
      reportRenderedFrame();

      onProgress?.call(const MapExportProgress(MapExportPhase.encoding));
      final encoded = await _timelineChannel
          .invokeMethod<bool>('encodeTimeline', {
            'framePaths': framePaths,
            'repeats': repeats,
            'outputPath': output.path,
            'width': _videoWidth,
            'height': _videoHeight,
            'fps': _videoFps,
            'bitrate': 5000000,
          });
      if (encoded != true || !await output.exists()) {
        throw StateError('타임라인 영상을 만들지 못했어요.');
      }
      cancellationToken?.throwIfCancelled();
      final saved = saveToGallery
          ? await this.saveToGallery(output, MapShareFormat.video)
          : false;
      onProgress?.call(const MapExportProgress(MapExportPhase.ready, 1));
      return MapShareResult(file: output, savedToGallery: saved);
    } finally {
      renderer.dispose();
      if (cancellationToken?.isCancelled == true && output.existsSync()) {
        try {
          output.deleteSync();
        } on FileSystemException {
          // The temporary directory will be cleaned by the operating system.
        }
      }
      for (final entity in exportRoot.listSync()) {
        if (entity is File && entity.path != output.path) {
          try {
            entity.deleteSync();
          } on FileSystemException {
            // Temporary frames can be cleaned by the operating system later.
          }
        }
      }
    }
  }

  Future<String> _writeTimelineFrame({
    required _MapShareRenderer renderer,
    required Directory directory,
    required int index,
    required Map<String, RegionPhoto> visiblePhotos,
    required double progress,
    MapTimelineItem? current,
    double mapZoom = 1,
    Offset? focusAssetPoint,
    List<TravelRoute> completedRoutes = const [],
    List<List<Offset>> activeRouteSegments = const [],
    Offset? planeAssetPoint,
    double? planeAngle,
    Offset? arrivalAssetPoint,
    double arrivalPulse = 0,
    Map<String, double> photoOpacities = const {},
  }) async {
    final bytes = await renderer.renderPng(
      width: _videoWidth,
      height: _videoHeight,
      visiblePhotos: visiblePhotos,
      progress: progress,
      current: current,
      mapZoom: mapZoom,
      focusAssetPoint: focusAssetPoint,
      completedRoutes: completedRoutes,
      activeRouteSegments: activeRouteSegments,
      planeAssetPoint: planeAssetPoint,
      planeAngle: planeAngle,
      arrivalAssetPoint: arrivalAssetPoint,
      arrivalPulse: arrivalPulse,
      photoOpacities: photoOpacities,
    );
    final file = File(
      p.join(directory.path, 'frame-${index.toString().padLeft(3, '0')}.png'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<bool> saveToGallery(File file, MapShareFormat format) async {
    try {
      if (format == MapShareFormat.image) {
        await Gal.putImage(file.path);
      } else {
        await Gal.putVideo(file.path);
      }
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> share(MapShareResult result, Rect origin) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(result.file.path)],
        title: '사상 여행 지도',
        sharePositionOrigin: origin,
      ),
    );
  }
}

({int travelFrames, int revealFrames, int holdFrames}) timelineMotionSteps(
  int itemCount,
) {
  if (itemCount <= 20) {
    return (travelFrames: 18, revealFrames: 10, holdFrames: 12);
  }
  if (itemCount <= 50) {
    return (travelFrames: 12, revealFrames: 8, holdFrames: 8);
  }
  return (travelFrames: 8, revealFrames: 5, holdFrames: 4);
}

double regionFocusZoom(
  MapRegion region,
  RegionMapAsset asset, {
  Rect? focusBounds,
}) {
  final bounds =
      focusBounds ??
      Rect.fromLTWH(
        region.bounds.x,
        region.bounds.y,
        region.bounds.width,
        region.bounds.height,
      );
  final widthZoom = asset.width / math.max(bounds.width, 1) * .42;
  final heightZoom = asset.height / math.max(bounds.height, 1) * .42;
  return math.min(widthZoom, heightZoom).clamp(2.1, 4.5).toDouble();
}

Offset _cameraPointForRoute(
  TravelRoute route,
  double phase,
  RegionMapAsset asset,
  Offset departure,
  Offset destination,
) {
  if (route.segments.length <= 1) {
    return route.pointAt(phase) ?? Offset.lerp(departure, destination, phase)!;
  }
  final center = Offset(asset.width / 2, asset.height / 2);
  if (phase < .5) {
    return Offset.lerp(departure, center, _easeInOut(phase * 2))!;
  }
  return Offset.lerp(center, destination, _easeInOut((phase - .5) * 2))!;
}

double _travelZoom(double previousZoom, double nextZoom, double phase) {
  if (phase <= .5) {
    return ui.lerpDouble(previousZoom, 1.08, _easeInOut(phase * 2))!;
  }
  return ui.lerpDouble(1.08, nextZoom * .82, _easeInOut((phase - .5) * 2))!;
}

double _easeInOut(double value) =>
    (1 - math.cos(value.clamp(0, 1) * math.pi)) / 2;

double _easeOut(double value) =>
    1 - math.pow(1 - value.clamp(0, 1), 3).toDouble();

class _MapShareRenderer {
  _MapShareRenderer({
    required this.asset,
    required this.mode,
    required this.images,
    required this.paths,
  });

  final RegionMapAsset asset;
  final MapMode mode;
  final Map<String, ui.Image> images;
  final Map<String, Path> paths;

  static Future<_MapShareRenderer> create({
    required RegionMapAsset asset,
    required MapMode mode,
    required Map<String, RegionPhoto> photos,
    Map<String, RegionPhotoAlbum> albums = const {},
    required SasangStorage storage,
  }) async {
    final images = <String, ui.Image>{};
    final candidates = <RegionPhoto>[
      for (final entry in photos.entries)
        if (entry.key.startsWith('${mode.storageKey}:')) entry.value,
      for (final entry in albums.entries)
        if (entry.key.startsWith('${mode.storageKey}:')) ...entry.value.photos,
    ];
    for (final photo in candidates) {
      if (images.containsKey(photo.uri)) continue;
      final file = await storage.resolveImage(photo.uri);
      if (file == null) continue;
      try {
        final targetWidth = math.min(photo.width.round(), 1440);
        final codec = await ui.instantiateImageCodec(
          await file.readAsBytes(),
          targetWidth: math.max(1, targetWidth),
          allowUpscaling: false,
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        images[photo.uri] = frame.image;
      } on Object {
        // A missing/corrupt photo leaves its region unfilled in the export.
      }
    }
    return _MapShareRenderer(
      asset: asset,
      mode: mode,
      images: images,
      paths: {
        for (final region in asset.regions)
          region.code: parseSvgPathData(region.pathData),
      },
    );
  }

  Future<Uint8List> renderPng({
    required int width,
    required int height,
    required Map<String, RegionPhoto> visiblePhotos,
    required double progress,
    MapTimelineItem? current,
    double mapZoom = 1,
    Offset? focusAssetPoint,
    List<TravelRoute> completedRoutes = const [],
    List<List<Offset>> activeRouteSegments = const [],
    Offset? planeAssetPoint,
    double? planeAngle,
    Offset? arrivalAssetPoint,
    double arrivalPulse = 0,
    Map<String, double> photoOpacities = const {},
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFAFAFA),
    );

    final margin = width * .075;
    final headerTop = height * .065;
    _drawText(
      canvas,
      '사상',
      Offset(margin, headerTop),
      fontSize: width * .032,
      color: SasangColors.accent,
      weight: FontWeight.w800,
      letterSpacing: 1.2,
    );
    _drawText(
      canvas,
      mode == MapMode.korea ? '나의 대한민국 여행' : '나의 세계 여행',
      Offset(margin, headerTop + width * .06),
      fontSize: width * .052,
      color: SasangColors.ink,
      weight: FontWeight.w800,
    );

    final mapTop = height * .22;
    final mapHeight = height * .58;
    final mapRect = Rect.fromLTWH(
      margin,
      mapTop,
      width - margin * 2,
      mapHeight,
    );
    final safeZoom = mapZoom.clamp(1, 4.5).toDouble();
    final contentRect = mapContentRect(mapRect.size, asset);
    final focus = focusAssetPoint == null
        ? mapRect.size.center(Offset.zero)
        : _assetToLocal(focusAssetPoint, contentRect);
    final mapOffset = safeZoom == 1
        ? Offset.zero
        : mapRect.size.center(Offset.zero) - focus * safeZoom;
    final controller = TransformationController(
      Matrix4.diagonal3Values(safeZoom, safeZoom, 1),
    );
    canvas.save();
    canvas.clipRect(mapRect);
    canvas.translate(mapRect.left, mapRect.top);
    canvas.translate(mapOffset.dx, mapOffset.dy);
    canvas.scale(safeZoom);
    RegionMapPainter(
      asset: asset,
      mode: mode,
      paths: paths,
      photos: visiblePhotos,
      images: {
        for (final entry in visiblePhotos.entries)
          if (images[entry.value.uri] case final image?) entry.key: image,
      },
      selectedRegionCode: current?.region.code,
      transformationController: controller,
      photoOpacities: photoOpacities,
    ).paint(canvas, mapRect.size);
    _drawRoutes(
      canvas,
      contentRect: contentRect,
      completedRoutes: completedRoutes,
      activeRouteSegments: activeRouteSegments,
      planeAssetPoint: planeAssetPoint,
      planeAngle: planeAngle,
      arrivalAssetPoint: arrivalAssetPoint,
      arrivalPulse: arrivalPulse,
      zoom: safeZoom,
    );
    canvas.restore();
    controller.dispose();

    final count = visiblePhotos.keys
        .where((key) => key.startsWith('${mode.storageKey}:'))
        .length;
    final percent = mapTravelPercentage(count, asset.regions.length);
    final unit = mode == MapMode.korea ? '개 지역' : '개 국가';
    final footerTop = height * .835;
    if (current != null) {
      _drawText(
        canvas,
        _dateLabel(current.date),
        Offset(margin, footerTop),
        fontSize: width * .027,
        color: SasangColors.secondary,
        weight: FontWeight.w700,
      );
      _drawText(
        canvas,
        current.region.name,
        Offset(margin, footerTop + width * .046),
        fontSize: width * .048,
        color: SasangColors.ink,
        weight: FontWeight.w800,
      );
    } else {
      _drawText(
        canvas,
        '나의 여행 지도',
        Offset(margin, footerTop + width * .025),
        fontSize: width * .044,
        color: SasangColors.ink,
        weight: FontWeight.w800,
      );
    }
    _drawText(
      canvas,
      '$count$unit  ·  $percent%',
      Offset(width - margin, footerTop + width * .055),
      fontSize: width * .027,
      color: SasangColors.accent,
      weight: FontWeight.w800,
      align: TextAlign.right,
    );

    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, height * .94, width - margin * 2, width * .008),
      Radius.circular(width * .004),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xFFE4E4E7));
    final progressRect = Rect.fromLTWH(
      margin,
      height * .94,
      (width - margin * 2) * progress.clamp(0, 1),
      width * .008,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(progressRect, Radius.circular(width * .004)),
      Paint()..color = SasangColors.accent,
    );

    final image = await recorder.endRecording().toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('공유 이미지를 만들지 못했어요.');
    return data.buffer.asUint8List();
  }

  void dispose() {
    for (final image in images.values) {
      image.dispose();
    }
  }

  Offset _assetToLocal(Offset point, Rect contentRect) => Offset(
    contentRect.left + point.dx / asset.width * contentRect.width,
    contentRect.top + point.dy / asset.height * contentRect.height,
  );

  void _drawRoutes(
    Canvas canvas, {
    required Rect contentRect,
    required List<TravelRoute> completedRoutes,
    required List<List<Offset>> activeRouteSegments,
    required Offset? planeAssetPoint,
    required double? planeAngle,
    required Offset? arrivalAssetPoint,
    required double arrivalPulse,
    required double zoom,
  }) {
    final visibleCompleted = completedRoutes.length > 6
        ? completedRoutes.sublist(completedRoutes.length - 6)
        : completedRoutes;
    for (var index = 0; index < visibleCompleted.length; index++) {
      final route = visibleCompleted[index];
      final age = visibleCompleted.length - index;
      _drawDashedSegments(
        canvas,
        contentRect: contentRect,
        segments: route.segments,
        zoom: zoom,
        opacity: (.34 - age * .025).clamp(.16, .30),
      );
    }
    _drawDashedSegments(
      canvas,
      contentRect: contentRect,
      segments: activeRouteSegments,
      zoom: zoom,
      opacity: .82,
    );

    if (arrivalAssetPoint != null) {
      final arrival = _assetToLocal(arrivalAssetPoint, contentRect);
      final phase = arrivalPulse.clamp(0, 1);
      canvas.drawCircle(
        arrival,
        (5 + 18 * phase) / zoom,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 / zoom
          ..color = SasangColors.accent.withValues(alpha: .38 * (1 - phase)),
      );
      canvas.drawCircle(
        arrival,
        3.2 / zoom,
        Paint()..color = SasangColors.accent.withValues(alpha: .9),
      );
    }
    if (planeAssetPoint == null) return;

    final plane = _assetToLocal(planeAssetPoint, contentRect);
    final planeSize = 11 / zoom;
    final planePath = Path()
      ..moveTo(planeSize, 0)
      ..lineTo(-planeSize * .58, -planeSize * .4)
      ..lineTo(-planeSize * .2, 0)
      ..lineTo(-planeSize * .58, planeSize * .4)
      ..close();
    canvas.save();
    canvas.translate(plane.dx, plane.dy);
    canvas.rotate(planeAngle ?? 0);
    canvas.drawPath(planePath, Paint()..color = SasangColors.accent);
    canvas.restore();
  }

  void _drawDashedSegments(
    Canvas canvas, {
    required Rect contentRect,
    required List<List<Offset>> segments,
    required double zoom,
    required double opacity,
  }) {
    for (final segment in segments) {
      if (segment.length < 2) continue;
      final points = segment
          .map((point) => _assetToLocal(point, contentRect))
          .toList(growable: false);
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        dashPath(
          path,
          dashArray: CircularIntervalList<double>([5 / zoom, 6 / zoom]),
        ),
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1.7 / zoom
          ..color = SasangColors.accent.withValues(alpha: opacity),
      );
    }
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset anchor, {
    required double fontSize,
    required Color color,
    required FontWeight weight,
    double letterSpacing = 0,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'SUIT',
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: letterSpacing,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = align == TextAlign.right
        ? Offset(anchor.dx - painter.width, anchor.dy)
        : anchor;
    painter.paint(canvas, offset);
  }

  static String _dateLabel(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

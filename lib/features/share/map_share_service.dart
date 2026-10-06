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

enum MapShareFormat { image, video }

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
}) {
  final regions = {for (final region in asset.regions) region.code: region};
  final prefix = '${mode.storageKey}:';
  final items = <MapTimelineItem>[];
  for (final entry in photos.entries) {
    if (!entry.key.startsWith(prefix)) continue;
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
  static const _videoFps = 12;

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
    ValueChanged<double>? onProgress,
    bool saveToGallery = true,
  }) async {
    final timeline = buildMapTimeline(asset: asset, mode: mode, photos: photos);
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
      photos: photos,
      storage: storage,
    );

    try {
      final framePaths = <String>[];
      final repeats = <int>[];
      final visible = <String, RegionPhoto>{};
      final route = <Offset>[];
      final motion = timelineMotionSteps(timeline.length);
      var frameIndex = 0;

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
      for (var index = 0; index < timeline.length; index++) {
        final item = timeline[index];
        final destination = _regionCenter(item.region);
        final focusZoom = regionFocusZoom(item.region, asset);

        for (var step = 1; step <= motion.travelFrames; step++) {
          final phase = _easeInOut(step / motion.travelFrames);
          final isFirst = index == 0;
          final departure = isFirst ? destination : route.last;
          final plane = Offset.lerp(departure, destination, phase)!;
          final previousZoom = isFirst
              ? 1.0
              : regionFocusZoom(timeline[index - 1].region, asset);
          framePaths.add(
            await _writeTimelineFrame(
              renderer: renderer,
              directory: exportRoot,
              index: frameIndex++,
              visiblePhotos: visible,
              progress: (index + phase * .55) / timeline.length,
              current: item,
              mapZoom: isFirst
                  ? ui.lerpDouble(1, focusZoom * .82, phase)!
                  : _travelZoom(previousZoom, focusZoom, phase),
              focusAssetPoint: isFirst
                  ? destination
                  : Offset.lerp(departure, destination, phase),
              routeAssetPoints: isFirst ? const [] : [...route, plane],
              planeAssetPoint: isFirst ? null : plane,
            ),
          );
          repeats.add(1);
        }

        visible[item.key] = item.photo;
        route.add(destination);
        for (var step = 1; step <= motion.revealFrames; step++) {
          final phase = _easeOut(step / motion.revealFrames);
          framePaths.add(
            await _writeTimelineFrame(
              renderer: renderer,
              directory: exportRoot,
              index: frameIndex++,
              visiblePhotos: visible,
              progress: (index + .55 + phase * .45) / timeline.length,
              current: item,
              mapZoom: ui.lerpDouble(focusZoom * .82, focusZoom, phase)!,
              focusAssetPoint: destination,
              routeAssetPoints: route,
              planeAssetPoint: destination,
              photoOpacities: {item.key: phase},
            ),
          );
          repeats.add(
            1 + (step == motion.revealFrames ? motion.holdFrames : 0),
          );
        }
        onProgress?.call((index + 1) / timeline.length * .72);
        await Future<void>.delayed(Duration.zero);
      }

      framePaths.add(
        await _writeTimelineFrame(
          renderer: renderer,
          directory: exportRoot,
          index: frameIndex,
          visiblePhotos: visible,
          progress: 1,
          routeAssetPoints: route,
          planeAssetPoint: route.last,
        ),
      );
      repeats.add(_videoFps * 2);

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
      onProgress?.call(.92);
      final saved = saveToGallery
          ? await this.saveToGallery(output, MapShareFormat.video)
          : false;
      onProgress?.call(1);
      return MapShareResult(file: output, savedToGallery: saved);
    } finally {
      renderer.dispose();
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
    List<Offset> routeAssetPoints = const [],
    Offset? planeAssetPoint,
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
      routeAssetPoints: routeAssetPoints,
      planeAssetPoint: planeAssetPoint,
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
    return (travelFrames: 5, revealFrames: 4, holdFrames: 3);
  }
  if (itemCount <= 50) {
    return (travelFrames: 3, revealFrames: 2, holdFrames: 1);
  }
  return (travelFrames: 1, revealFrames: 1, holdFrames: 0);
}

Offset _regionCenter(MapRegion region) => Offset(
  region.bounds.x + region.bounds.width / 2,
  region.bounds.y + region.bounds.height / 2,
);

double regionFocusZoom(MapRegion region, RegionMapAsset asset) {
  final widthZoom = asset.width / math.max(region.bounds.width, 1) * .42;
  final heightZoom = asset.height / math.max(region.bounds.height, 1) * .42;
  return math.min(widthZoom, heightZoom).clamp(2.1, 4.5).toDouble();
}

double _travelZoom(double previousZoom, double nextZoom, double phase) {
  if (phase <= .5) {
    return ui.lerpDouble(previousZoom, 1.25, _easeInOut(phase * 2))!;
  }
  return ui.lerpDouble(1.25, nextZoom * .82, _easeInOut((phase - .5) * 2))!;
}

double _easeInOut(double value) =>
    (1 - math.cos(value.clamp(0, 1) * math.pi)) / 2;

double _easeOut(double value) =>
    1 - math.pow(1 - value.clamp(0, 1), 3).toDouble();

class _MapShareRenderer {
  _MapShareRenderer({
    required this.asset,
    required this.mode,
    required this.photos,
    required this.images,
    required this.paths,
  });

  final RegionMapAsset asset;
  final MapMode mode;
  final Map<String, RegionPhoto> photos;
  final Map<String, ui.Image> images;
  final Map<String, Path> paths;

  static Future<_MapShareRenderer> create({
    required RegionMapAsset asset,
    required MapMode mode,
    required Map<String, RegionPhoto> photos,
    required SasangStorage storage,
  }) async {
    final images = <String, ui.Image>{};
    for (final entry in photos.entries) {
      if (!entry.key.startsWith('${mode.storageKey}:')) continue;
      final file = await storage.resolveImage(entry.value.uri);
      if (file == null) continue;
      try {
        final targetWidth = math.min(entry.value.width.round(), 1440);
        final codec = await ui.instantiateImageCodec(
          await file.readAsBytes(),
          targetWidth: math.max(1, targetWidth),
          allowUpscaling: false,
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        images[entry.key] = frame.image;
      } on Object {
        // A missing/corrupt photo leaves its region unfilled in the export.
      }
    }
    return _MapShareRenderer(
      asset: asset,
      mode: mode,
      photos: photos,
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
    List<Offset> routeAssetPoints = const [],
    Offset? planeAssetPoint,
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
      images: images,
      selectedRegionCode: current?.region.code,
      transformationController: controller,
      photoOpacities: photoOpacities,
    ).paint(canvas, mapRect.size);
    _drawRoute(
      canvas,
      contentRect: contentRect,
      points: routeAssetPoints,
      planeAssetPoint: planeAssetPoint,
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

  void _drawRoute(
    Canvas canvas, {
    required Rect contentRect,
    required List<Offset> points,
    required Offset? planeAssetPoint,
    required double zoom,
  }) {
    final localPoints = points
        .map((point) => _assetToLocal(point, contentRect))
        .toList(growable: false);
    if (localPoints.length >= 2) {
      final route = Path()..moveTo(localPoints.first.dx, localPoints.first.dy);
      for (final point in localPoints.skip(1)) {
        route.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        route,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.4 / zoom
          ..color = SasangColors.accent.withValues(alpha: .72),
      );
    }
    if (planeAssetPoint == null) return;

    final plane = _assetToLocal(planeAssetPoint, contentRect);
    final previous = localPoints.length >= 2
        ? localPoints[localPoints.length - 2]
        : plane - const Offset(1, 0);
    final angle = math.atan2(plane.dy - previous.dy, plane.dx - previous.dx);
    final planeSize = 15 / zoom;
    final planePath = Path()
      ..moveTo(planeSize * .8, 0)
      ..lineTo(-planeSize * .62, -planeSize * .45)
      ..lineTo(-planeSize * .25, 0)
      ..lineTo(-planeSize * .62, planeSize * .45)
      ..close();
    canvas.save();
    canvas.translate(plane.dx, plane.dy);
    canvas.rotate(angle);
    canvas.drawShadow(planePath, Colors.black38, 3 / zoom, true);
    canvas.drawPath(
      planePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 / zoom
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    canvas.drawPath(planePath, Paint()..color = SasangColors.accent);
    canvas.restore();
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

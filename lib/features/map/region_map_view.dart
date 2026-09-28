import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../core/storage/sasang_storage.dart';
import '../../core/layout/sasang_layout.dart';
import '../../core/theme/sasang_theme.dart';
import '../../models/map_models.dart';
import '../../widgets/sasang_ui.dart';

class RegionMapView extends StatefulWidget {
  const RegionMapView({
    required this.asset,
    required this.mode,
    required this.photos,
    required this.selectedRegionCode,
    required this.onSelectRegion,
    required this.storage,
    super.key,
  });

  final RegionMapAsset asset;
  final MapMode mode;
  final Map<String, RegionPhoto> photos;
  final String? selectedRegionCode;
  final ValueChanged<String?> onSelectRegion;
  final SasangStorage storage;

  @override
  State<RegionMapView> createState() => _RegionMapViewState();
}

class _RegionMapViewState extends State<RegionMapView> {
  final _controller = TransformationController();
  final Map<String, ui.Image> _images = {};
  final Map<String, String> _imageUris = {};
  late Map<String, Path> _paths;

  @override
  void initState() {
    super.initState();
    _parsePaths();
    unawaited(_loadImages());
  }

  @override
  void didUpdateWidget(covariant RegionMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _controller.value = Matrix4.identity();
      _parsePaths();
    }
    unawaited(_loadImages());
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }

  void _parsePaths() {
    _paths = {
      for (final region in widget.asset.regions)
        region.code: parseSvgPathData(region.pathData),
    };
  }

  Future<void> _loadImages() async {
    final next = <String, ui.Image>{};
    for (final region in widget.asset.regions) {
      final key = regionPhotoKey(widget.mode, region.code);
      final photo = widget.photos[key];
      if (photo == null) continue;
      final existing = _images[key];
      if (existing != null && _imageUris[key] == photo.uri) {
        next[key] = existing;
        continue;
      }
      final file = await widget.storage.resolveImage(photo.uri);
      if (file == null) continue;
      final image = await _decode(file);
      if (image != null) next[key] = image;
    }
    if (!mounted) {
      for (final image in next.values) {
        if (!_images.containsValue(image)) image.dispose();
      }
      return;
    }
    for (final entry in _images.entries) {
      if (!identical(next[entry.key], entry.value)) entry.value.dispose();
    }
    setState(() {
      _images
        ..clear()
        ..addAll(next);
      _imageUris
        ..clear()
        ..addEntries(
          widget.photos.entries
              .where((entry) => next.containsKey(entry.key))
              .map((entry) => MapEntry(entry.key, entry.value.uri)),
        );
    });
  }

  Future<ui.Image?> _decode(File file) async {
    try {
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } on Object {
      return null;
    }
  }

  void _handleTap(Offset localPosition, Size size) {
    final scene = _controller.toScene(localPosition);
    final contentRect = mapContentRect(size, widget.asset);
    if (!contentRect.contains(scene)) {
      widget.onSelectRegion(null);
      return;
    }
    final mapPoint = Offset(
      (scene.dx - contentRect.left) / contentRect.width * widget.asset.width,
      (scene.dy - contentRect.top) / contentRect.height * widget.asset.height,
    );
    for (final region in widget.asset.regions.reversed) {
      final bounds = region.bounds;
      if (mapPoint.dx < bounds.x ||
          mapPoint.dx > bounds.x + bounds.width ||
          mapPoint.dy < bounds.y ||
          mapPoint.dy > bounds.y + bounds.height) {
        continue;
      }
      if (_paths[region.code]?.contains(mapPoint) ?? false) {
        widget.onSelectRegion(region.code);
        return;
      }
    }
    widget.onSelectRegion(null);
  }

  void _zoom(double factor, Size size) {
    final current = _controller.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 12.0);
    final center = size.center(Offset.zero);
    _controller.value = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(next, next, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(details.localPosition, size),
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 12,
                boundaryMargin: EdgeInsets.symmetric(
                  horizontal: size.width,
                  vertical: size.height,
                ),
                child: CustomPaint(
                  size: size,
                  painter: RegionMapPainter(
                    asset: widget.asset,
                    mode: widget.mode,
                    paths: _paths,
                    photos: widget.photos,
                    images: _images,
                    selectedRegionCode: widget.selectedRegionCode,
                    transformationController: _controller,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: sasangZoomControlsBottomOffset(
                MediaQuery.paddingOf(context).bottom,
              ),
              child: SasangSurface(
                blur: true,
                radius: 24,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ZoomButton(
                      icon: CupertinoIcons.add,
                      label: '지도 확대',
                      onTap: () => _zoom(1.55, size),
                    ),
                    const SizedBox(width: 28, child: Divider(height: 1)),
                    _ZoomButton(
                      icon: CupertinoIcons.minus,
                      label: '지도 축소',
                      onTap: () => _zoom(0.65, size),
                    ),
                    const SizedBox(width: 28, child: Divider(height: 1)),
                    _ZoomButton(
                      text: '1:1',
                      label: '지도 위치 초기화',
                      onTap: () => _controller.value = Matrix4.identity(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.text,
  });

  final IconData? icon;
  final String? text;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: icon != null
              ? Icon(icon, color: SasangColors.accent, size: 22)
              : Text(
                  text!,
                  style: const TextStyle(
                    color: SasangColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    ),
  );
}

class RegionMapPainter extends CustomPainter {
  RegionMapPainter({
    required this.asset,
    required this.mode,
    required this.paths,
    required this.photos,
    required this.images,
    required this.selectedRegionCode,
    required this.transformationController,
  }) : super(repaint: transformationController);

  final RegionMapAsset asset;
  final MapMode mode;
  final Map<String, Path> paths;
  final Map<String, RegionPhoto> photos;
  final Map<String, ui.Image> images;
  final String? selectedRegionCode;
  final TransformationController transformationController;

  @override
  void paint(Canvas canvas, Size size) {
    final contentRect = mapContentRect(size, asset);
    final assetToScreenScale = contentRect.width / asset.width;
    final interactiveScale = transformationController.value.getMaxScaleOnAxis();
    final selectedStrokeWidth = mapStrokeWidth(
      assetToScreenScale: assetToScreenScale,
      interactiveScale: interactiveScale,
    );
    canvas.save();
    canvas.translate(contentRect.left, contentRect.top);
    canvas.scale(
      contentRect.width / asset.width,
      contentRect.height / asset.height,
    );
    for (final region in asset.regions) {
      final path = paths[region.code]!;
      final key = regionPhotoKey(mode, region.code);
      final photo = photos[key];
      final image = images[key];
      if (photo != null && image != null) {
        _drawPhoto(canvas, path, region, photo, image);
      } else {
        canvas.drawPath(path, Paint()..color = const Color(0xFFFFFFFF));
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = mode == MapMode.world ? 0.18 : 0.52
          ..color = photo != null
              ? const Color(0xFF71717A)
              : const Color(0x3871717A),
      );
      if (selectedRegionCode == region.code) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = selectedStrokeWidth
            ..color = SasangColors.accent,
        );
      }
    }
    canvas.restore();
  }

  void _drawPhoto(
    Canvas canvas,
    Path path,
    MapRegion region,
    RegionPhoto photo,
    ui.Image image,
  ) {
    final bounds = Rect.fromLTWH(
      region.bounds.x,
      region.bounds.y,
      region.bounds.width,
      region.bounds.height,
    );
    final imageRatio = image.width / image.height;
    final boundsRatio = bounds.width / bounds.height;
    late double sourceWidth;
    late double sourceHeight;
    if (imageRatio > boundsRatio) {
      sourceHeight = image.height.toDouble() / photo.scale;
      sourceWidth = sourceHeight * boundsRatio;
    } else {
      sourceWidth = image.width.toDouble() / photo.scale;
      sourceHeight = sourceWidth / boundsRatio;
    }
    final centerX = image.width / 2 - photo.offsetX;
    final centerY = image.height / 2 - photo.offsetY;
    final source = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: sourceWidth.clamp(1, image.width.toDouble()),
      height: sourceHeight.clamp(1, image.height.toDouble()),
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawImageRect(
      image,
      source,
      bounds,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RegionMapPainter oldDelegate) => true;
}

Rect mapContentRect(Size viewport, RegionMapAsset asset) {
  final scale = math.min(
    viewport.width / asset.width,
    viewport.height / asset.height,
  );
  final width = asset.width * scale;
  final height = asset.height * scale;
  return Rect.fromLTWH(
    (viewport.width - width) / 2,
    (viewport.height - height) / 2,
    width,
    height,
  );
}

double mapStrokeWidth({
  required double assetToScreenScale,
  required double interactiveScale,
  double screenWidth = 1.6,
}) => screenWidth / (assetToScreenScale * interactiveScale);

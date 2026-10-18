import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../models/map_models.dart';
import 'map_repository.dart';

class MapPreview extends StatelessWidget {
  const MapPreview({
    required this.mode,
    super.key,
    this.countryCode,
    this.asset,
  });

  static final _maps = MapRepository();

  final MapMode mode;
  final String? countryCode;
  final RegionMapAsset? asset;

  @override
  Widget build(BuildContext context) {
    final previewAsset = asset;
    return ColoredBox(
      color: const Color(0xFFF4F7F9),
      child: previewAsset == null ? _loadedPreview() : _preview(previewAsset),
    );
  }

  Widget _loadedPreview() => FutureBuilder<RegionMapAsset>(
    future: _maps.load(mode),
    builder: (context, snapshot) => snapshot.hasData
        ? _preview(snapshot.data!)
        : const Center(child: CupertinoActivityIndicator(radius: 9)),
  );

  Widget _preview(RegionMapAsset asset) {
    final country = countryCode == null
        ? null
        : asset.regions
              .where((region) => region.code == countryCode)
              .firstOrNull;
    final regions = country == null ? asset.regions : [country];
    final bounds = country == null
        ? Rect.fromLTWH(0, 0, asset.width, asset.height)
        : Rect.fromLTWH(
            country.bounds.x,
            country.bounds.y,
            country.bounds.width,
            country.bounds.height,
          ).inflate(
            math.max(country.bounds.width, country.bounds.height) * .12,
          );
    return CustomPaint(
      painter: _MapPreviewPainter(
        paths: regions
            .map((region) => parseSvgPathData(region.pathData))
            .toList(growable: false),
        bounds: bounds,
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter({required this.paths, required this.bounds});

  final List<Path> paths;
  final Rect bounds;

  @override
  void paint(Canvas canvas, Size size) {
    if (bounds.isEmpty || size.isEmpty) return;
    const padding = 9.0;
    final contentWidth = math.max(1.0, size.width - padding * 2);
    final contentHeight = math.max(1.0, size.height - padding * 2);
    final scale = math.min(
      contentWidth / bounds.width,
      contentHeight / bounds.height,
    );
    final left = (size.width - bounds.width * scale) / 2;
    final top = (size.height - bounds.height * scale) / 2;
    canvas.save();
    canvas.translate(left, top);
    canvas.scale(scale);
    canvas.translate(-bounds.left, -bounds.top);
    for (final path in paths) {
      canvas.drawPath(path, Paint()..color = const Color(0xFFDCE5ED));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = .7 / scale
          ..color = const Color(0xFF81909D),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) =>
      oldDelegate.paths != paths || oldDelegate.bounds != bounds;
}

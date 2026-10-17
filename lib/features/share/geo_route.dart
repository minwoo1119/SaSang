import 'dart:math' as math;
import 'dart:ui';

import 'package:path_drawing/path_drawing.dart';

import '../../models/map_models.dart';

enum GeoAnchorSource { photoGps, regionRepresentative, dominantComponent }

class ResolvedGeoAnchor {
  const ResolvedGeoAnchor({
    required this.point,
    required this.focusBounds,
    required this.source,
  });

  final Offset point;
  final Rect focusBounds;
  final GeoAnchorSource source;
}

class GeoAnchorResolver {
  const GeoAnchorResolver();

  ResolvedGeoAnchor resolve({
    required RegionMapAsset asset,
    required MapRegion region,
    required RegionPhoto photo,
  }) {
    final path = parseSvgPathData(region.pathData);
    final projection = asset.projection;
    final latitude = photo.latitude;
    final longitude = photo.longitude;
    if (projection?.geographic == true &&
        latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      final projected = projection!.project(
        latitude: latitude,
        longitude: longitude,
      );
      final point = Offset(projected.x, projected.y);
      if (path.contains(point)) {
        return ResolvedGeoAnchor(
          point: point,
          focusBounds: _componentBounds(path, point) ?? path.getBounds(),
          source: GeoAnchorSource.photoGps,
        );
      }
    }

    final generatedAnchor = region.anchor;
    final generatedBounds = region.anchorBounds;
    if (generatedAnchor != null && generatedBounds != null) {
      final point = Offset(generatedAnchor.x, generatedAnchor.y);
      return ResolvedGeoAnchor(
        point: point,
        focusBounds: _rect(generatedBounds),
        source: GeoAnchorSource.regionRepresentative,
      );
    }

    final component = _dominantComponent(path);
    final bounds = component.getBounds();
    return ResolvedGeoAnchor(
      point: _insidePoint(component, bounds),
      focusBounds: bounds,
      source: GeoAnchorSource.dominantComponent,
    );
  }

  static Rect _rect(RegionBounds bounds) =>
      Rect.fromLTWH(bounds.x, bounds.y, bounds.width, bounds.height);

  static Rect? _componentBounds(Path path, Offset point) {
    for (final metric in path.computeMetrics()) {
      final component = metric.extractPath(0, metric.length);
      if (component.contains(point)) return component.getBounds();
    }
    return null;
  }

  static Path _dominantComponent(Path path) {
    Path? largest;
    var largestArea = -1.0;
    for (final metric in path.computeMetrics()) {
      final component = metric.extractPath(0, metric.length);
      final bounds = component.getBounds();
      final area = bounds.width * bounds.height;
      if (area > largestArea) {
        largest = component;
        largestArea = area;
      }
    }
    return largest ?? path;
  }

  static Offset _insidePoint(Path path, Rect bounds) {
    if (path.contains(bounds.center)) return bounds.center;
    Offset? best;
    var bestDistance = double.infinity;
    for (var row = 0; row < 25; row++) {
      for (var column = 0; column < 25; column++) {
        final point = Offset(
          bounds.left + bounds.width * (column + .5) / 25,
          bounds.top + bounds.height * (row + .5) / 25,
        );
        if (!path.contains(point)) continue;
        final distance = (point - bounds.center).distanceSquared;
        if (distance < bestDistance) {
          best = point;
          bestDistance = distance;
        }
      }
    }
    return best ?? bounds.center;
  }
}

class TravelRoute {
  const TravelRoute(this.segments);

  final List<List<Offset>> segments;

  bool get isEmpty => segments.every((segment) => segment.length < 2);

  List<List<Offset>> partial(double progress) {
    if (isEmpty || progress <= 0) return const [];
    if (progress >= 1) return segments;
    final total = _totalLength;
    var remaining = total * progress;
    final result = <List<Offset>>[];
    for (final segment in segments) {
      if (segment.length < 2) continue;
      final partial = <Offset>[segment.first];
      for (var index = 1; index < segment.length; index++) {
        final start = segment[index - 1];
        final end = segment[index];
        final length = (end - start).distance;
        if (remaining >= length) {
          partial.add(end);
          remaining -= length;
          continue;
        }
        if (remaining > 0 && length > 0) {
          partial.add(Offset.lerp(start, end, remaining / length)!);
        }
        if (partial.length >= 2) result.add(partial);
        return result;
      }
      result.add(partial);
    }
    return result;
  }

  Offset? pointAt(double progress) {
    final visible = partial(progress);
    return visible.isEmpty ? null : visible.last.last;
  }

  double? angleAt(double progress) {
    final visible = partial(progress);
    if (visible.isEmpty || visible.last.length < 2) return null;
    final segment = visible.last;
    final delta = segment.last - segment[segment.length - 2];
    return math.atan2(delta.dy, delta.dx);
  }

  double get _totalLength {
    var total = 0.0;
    for (final segment in segments) {
      for (var index = 1; index < segment.length; index++) {
        total += (segment[index] - segment[index - 1]).distance;
      }
    }
    return total;
  }
}

TravelRoute buildTravelRoute({
  required Offset departure,
  required Offset destination,
  required RegionMapAsset asset,
  required MapMode mode,
  int samples = 24,
}) {
  if ((destination - departure).distance < .5) {
    return const TravelRoute([]);
  }
  final projection = asset.projection;
  if (mode == MapMode.world && projection?.geographic == true) {
    final segments = _splitAntimeridian(
      _greatCirclePoints(departure, destination, projection!, samples),
      projection,
    );
    if (segments.length > 1) {
      // The export uses one fixed world-map frame. Wrapping across opposite
      // edges makes the dashed route and camera appear to travel in different
      // directions, so keep dateline crossings on one visible screen curve.
      return TravelRoute([
        _containedWorldCurve(departure, destination, asset, samples),
      ]);
    }
    return TravelRoute(segments);
  }

  final delta = destination - departure;
  final distance = delta.distance;
  final normal = Offset(-delta.dy, delta.dx) / distance;
  final direction = departure.dx <= destination.dx ? -1.0 : 1.0;
  final control =
      Offset.lerp(departure, destination, .5)! +
      normal * math.min(distance * .16, asset.width * .07) * direction;
  return TravelRoute([
    [
      for (var index = 0; index <= samples; index++)
        _quadratic(departure, control, destination, index / samples),
    ],
  ]);
}

List<Offset> _containedWorldCurve(
  Offset departure,
  Offset destination,
  RegionMapAsset asset,
  int samples,
) {
  final midpoint = Offset.lerp(departure, destination, .5)!;
  final bend = math.min(
    (destination - departure).distance * .16,
    asset.height * .07,
  );
  final control = Offset(
    midpoint.dx.clamp(0, asset.width).toDouble(),
    (midpoint.dy - bend).clamp(0, asset.height).toDouble(),
  );
  return [
    for (var index = 0; index <= samples; index++)
      _quadratic(departure, control, destination, index / samples),
  ];
}

Offset _quadratic(Offset start, Offset control, Offset end, double t) {
  final inverse = 1 - t;
  return start * (inverse * inverse) +
      control * (2 * inverse * t) +
      end * (t * t);
}

List<Offset> _greatCirclePoints(
  Offset departure,
  Offset destination,
  MapProjection projection,
  int samples,
) {
  final start = projection.unproject(
    MapCoordinate(x: departure.dx, y: departure.dy),
  );
  final end = projection.unproject(
    MapCoordinate(x: destination.dx, y: destination.dy),
  );
  final startVector = _unitVector(start.latitude, start.longitude);
  final endVector = _unitVector(end.latitude, end.longitude);
  final dot =
      (startVector.$1 * endVector.$1 +
              startVector.$2 * endVector.$2 +
              startVector.$3 * endVector.$3)
          .clamp(-1.0, 1.0);
  final omega = math.acos(dot);
  final sinOmega = math.sin(omega);
  final result = <Offset>[];
  for (var index = 0; index <= samples; index++) {
    final t = index / samples;
    final firstWeight = sinOmega.abs() < 1e-8
        ? 1 - t
        : math.sin((1 - t) * omega) / sinOmega;
    final secondWeight = sinOmega.abs() < 1e-8
        ? t
        : math.sin(t * omega) / sinOmega;
    final x = startVector.$1 * firstWeight + endVector.$1 * secondWeight;
    final y = startVector.$2 * firstWeight + endVector.$2 * secondWeight;
    final z = startVector.$3 * firstWeight + endVector.$3 * secondWeight;
    final latitude = math.atan2(z, math.sqrt(x * x + y * y)) * 180 / math.pi;
    final longitude = math.atan2(y, x) * 180 / math.pi;
    final projected = projection.project(
      latitude: latitude,
      longitude: longitude,
    );
    result.add(Offset(projected.x, projected.y));
  }
  return result;
}

(double, double, double) _unitVector(double latitude, double longitude) {
  final lat = latitude * math.pi / 180;
  final lon = longitude * math.pi / 180;
  return (
    math.cos(lat) * math.cos(lon),
    math.cos(lat) * math.sin(lon),
    math.sin(lat),
  );
}

List<List<Offset>> _splitAntimeridian(
  List<Offset> points,
  MapProjection projection,
) {
  if (points.length < 2) return [points];
  final left = projection.originX;
  final right = projection.originX + 360 * projection.scale;
  final worldWidth = right - left;
  final segments = <List<Offset>>[
    [points.first],
  ];
  for (var index = 1; index < points.length; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final delta = current.dx - previous.dx;
    if (delta.abs() <= worldWidth / 2) {
      segments.last.add(current);
      continue;
    }
    final crossesRight = delta < 0;
    final adjustedX = current.dx + (crossesRight ? worldWidth : -worldWidth);
    final boundary = crossesRight ? right : left;
    final ratio = (boundary - previous.dx) / (adjustedX - previous.dx);
    final y = previous.dy + (current.dy - previous.dy) * ratio.clamp(0, 1);
    segments.last.add(Offset(boundary, y));
    segments.add([Offset(crossesRight ? left : right, y), current]);
  }
  return segments.where((segment) => segment.length >= 2).toList();
}

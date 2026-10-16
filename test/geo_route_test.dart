import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:sasang/features/share/geo_route.dart';
import 'package:sasang/models/map_models.dart';

const _photo = RegionPhoto(
  id: 'photo',
  uri: 'file:///photo.jpg',
  width: 100,
  height: 100,
  scale: 1,
  offsetX: 0,
  offsetY: 0,
  createdAt: '2026-01-01T00:00:00Z',
);

void main() {
  late RegionMapAsset world;

  setUpAll(() {
    world = RegionMapAsset.fromJsonString(
      File('assets/maps/world/countries.json').readAsStringSync(),
    );
  });

  test('world projection round-trips GPS coordinates', () {
    final projection = world.projection!;
    final point = projection.project(latitude: 37.5665, longitude: 126.978);
    final coordinate = projection.unproject(point);

    expect(coordinate.latitude, closeTo(37.5665, 1e-9));
    expect(coordinate.longitude, closeTo(126.978, 1e-9));
  });

  test(
    'France uses its mainland representative anchor, not overseas bounds',
    () {
      final france = world.regions.singleWhere((region) => region.code == 'FR');
      final anchor = const GeoAnchorResolver().resolve(
        asset: world,
        region: france,
        photo: _photo,
      );

      expect(anchor.source, GeoAnchorSource.regionRepresentative);
      expect(anchor.point.dx, inInclusiveRange(350, 380));
      expect(anchor.point.dy, inInclusiveRange(70, 100));
      expect(anchor.focusBounds.width, lessThan(france.bounds.width / 3));
      expect(parseSvgPathData(france.pathData).contains(anchor.point), isTrue);
    },
  );

  test('valid photo GPS takes precedence when it lies inside the country', () {
    final japan = world.regions.singleWhere((region) => region.code == 'JP');
    const tokyoPhoto = RegionPhoto(
      id: 'tokyo',
      uri: 'file:///tokyo.jpg',
      width: 100,
      height: 100,
      scale: 1,
      offsetX: 0,
      offsetY: 0,
      createdAt: '2026-01-01T00:00:00Z',
      latitude: 35.6762,
      longitude: 139.6503,
    );
    final anchor = const GeoAnchorResolver().resolve(
      asset: world,
      region: japan,
      photo: tokyoPhoto,
    );

    expect(anchor.source, GeoAnchorSource.photoGps);
    expect(parseSvgPathData(japan.pathData).contains(anchor.point), isTrue);
  });

  test('great-circle route splits at the antimeridian', () {
    final projection = world.projection!;
    final route = buildTravelRoute(
      departure: Offset(
        projection.project(latitude: 35.6762, longitude: 139.6503).x,
        projection.project(latitude: 35.6762, longitude: 139.6503).y,
      ),
      destination: Offset(
        projection.project(latitude: 37.7749, longitude: -122.4194).x,
        projection.project(latitude: 37.7749, longitude: -122.4194).y,
      ),
      asset: world,
      mode: MapMode.world,
    );

    expect(route.segments.length, 2);
    for (final segment in route.segments) {
      for (var index = 1; index < segment.length; index++) {
        expect(
          (segment[index].dx - segment[index - 1].dx).abs(),
          lessThan(world.width / 2),
        );
      }
    }
  });

  test('local route follows a deterministic curve', () {
    final asset = RegionMapAsset(
      version: 'test',
      width: 400,
      height: 300,
      regions: const [],
    );
    final first = buildTravelRoute(
      departure: const Offset(20, 80),
      destination: const Offset(360, 220),
      asset: asset,
      mode: MapMode.korea,
    );
    final second = buildTravelRoute(
      departure: const Offset(20, 80),
      destination: const Offset(360, 220),
      asset: asset,
      mode: MapMode.korea,
    );

    expect(first.segments, second.segments);
    expect(first.segments.single.length, 25);
    expect(
      first.pointAt(.5),
      isNot(Offset.lerp(const Offset(20, 80), const Offset(360, 220), .5)),
    );
  });
}

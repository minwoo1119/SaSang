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

  test('antimeridian route stays inside the current map frame', () {
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

    expect(route.segments, hasLength(1));
    for (final point in route.segments.single) {
      expect(point.dx, inInclusiveRange(0, world.width));
      expect(point.dy, inInclusiveRange(0, world.height));
    }
  });

  test('Canada to Russia travels right within the current map frame', () {
    final canada = world.regions.singleWhere((region) => region.code == 'CA');
    final russia = world.regions.singleWhere((region) => region.code == 'RU');
    final departure = Offset(canada.anchor!.x, canada.anchor!.y);
    final destination = Offset(russia.anchor!.x, russia.anchor!.y);
    final route = buildTravelRoute(
      departure: departure,
      destination: destination,
      asset: world,
      mode: MapMode.world,
    );

    expect(route.segments, hasLength(1));
    final points = route.segments.single;
    expect(points.first, departure);
    expect(points.last, destination);
    for (var index = 1; index < points.length; index++) {
      expect(points[index].dx, greaterThanOrEqualTo(points[index - 1].dx));
      expect(points[index].dx, inInclusiveRange(0, world.width));
      expect(points[index].dy, inInclusiveRange(0, world.height));
    }
    expect(route.pointAt(.25)!.dx, lessThan(route.pointAt(.75)!.dx));
    expect(route.pointAt(.5), route.partial(.5).last.last);
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sasang/core/storage/sasang_storage.dart';
import 'package:sasang/features/map/region_map_view.dart';
import 'package:sasang/features/photos/photo_date.dart';
import 'package:sasang/models/map_models.dart';
import 'package:sasang/screens/map_store_screen.dart';

void main() {
  test('decodes the legacy Zustand persist envelope', () {
    final state = decodeZustandState(
      '{"state":{"hasStarted":true,"name":"여행자"},"version":0}',
    );
    expect(state['hasStarted'], isTrue);
    expect(state['name'], '여행자');
  });

  test('parses Expo EXIF and persisted photo dates', () {
    expect(parsePhotoDate('2025:03:09 18:02:11'), DateTime(2025, 3, 9, 12));
    expect(photoDateKey(DateTime(2026, 9, 6)), '2026-09-06');
  });

  test('preserves multipolygon region metadata and photo transforms', () {
    final asset = RegionMapAsset.fromJsonString('''
      {
        "metadata": {"version": "test"},
        "viewBox": {"width": 100, "height": 80},
        "regions": [{
          "code": "XX",
          "name": "Test",
          "geometryType": "MultiPolygon",
          "polygonCount": 2,
          "bounds": {"x": 1, "y": 2, "width": 10, "height": 20},
          "path": "M 1 2 L 11 2 L 11 22 Z M 3 4 L 4 4 L 4 5 Z"
        }]
      }
    ''');
    expect(asset.regions.single.geometryType, 'MultiPolygon');
    expect(asset.regions.single.polygonCount, 2);

    final photo = RegionPhoto.fromJson({
      'id': 'photo',
      'uri': 'file:///sasang/photos/photo.jpg',
      'width': 100,
      'height': 200,
      'scale': 1.5,
      'offsetX': 3,
      'offsetY': -4,
      'createdAt': '2026-09-26T00:00:00Z',
    });
    expect(photo.toJson()['scale'], 1.5);
    expect(photo.toJson()['offsetY'], -4.0);
  });

  test('keeps the map asset aspect ratio inside a tall phone viewport', () {
    const asset = RegionMapAsset(
      version: 'test',
      width: 360,
      height: 520,
      regions: [],
    );
    final rect = mapContentRect(const Size(390, 844), asset);

    expect(rect.width / rect.height, closeTo(360 / 520, .0001));
    expect(rect.center, const Offset(195, 422));
    expect(rect.top, greaterThan(0));
    expect(rect.bottom, lessThan(844));
  });

  test('keeps the selected-region border constant while zooming', () {
    const assetToScreenScale = 1.25;
    for (final zoom in [1.0, 2.0, 6.0, 12.0]) {
      final assetStroke = mapStrokeWidth(
        assetToScreenScale: assetToScreenScale,
        interactiveScale: zoom,
      );
      expect(assetStroke * assetToScreenScale * zoom, closeTo(1.6, .0001));
    }
  });

  testWidgets('map store uses country previews instead of code placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MapStoreScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('국가별 지도'), findsOneWidget);
    expect(find.text('6개'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.lock_fill), findsNWidgets(6));
    expect(find.text('JP'), findsNothing);
  });
}

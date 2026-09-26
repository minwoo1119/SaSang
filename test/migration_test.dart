import 'package:flutter_test/flutter_test.dart';
import 'package:sasang/core/storage/sasang_storage.dart';
import 'package:sasang/features/photos/photo_date.dart';
import 'package:sasang/models/map_models.dart';

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
}

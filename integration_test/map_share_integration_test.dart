import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sasang/core/storage/sasang_storage.dart';
import 'package:sasang/features/share/map_share_service.dart';
import 'package:sasang/models/map_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('exports a 9:16 map image and H.264 timeline video', (
    tester,
  ) async {
    final directory = await getTemporaryDirectory();
    final source = File(p.join(directory.path, 'sasang-share-test-source.png'));
    await source.writeAsBytes(await _testImageBytes());
    final storage = _TestStorage(source);
    final service = MapShareService(storage);
    const asset = RegionMapAsset(
      version: 'test',
      width: 100,
      height: 100,
      regions: [
        MapRegion(
          code: 'TEST',
          name: '테스트 지역',
          geometryType: 'Polygon',
          polygonCount: 1,
          bounds: RegionBounds(x: 10, y: 10, width: 80, height: 80),
          pathData: 'M 10 10 L 90 10 L 90 90 L 10 90 Z',
        ),
        MapRegion(
          code: 'EMPTY_1',
          name: '빈 지역 1',
          geometryType: 'Polygon',
          polygonCount: 1,
          bounds: RegionBounds(x: 0, y: 0, width: 5, height: 5),
          pathData: 'M 0 0 L 5 0 L 5 5 Z',
        ),
        MapRegion(
          code: 'EMPTY_2',
          name: '빈 지역 2',
          geometryType: 'Polygon',
          polygonCount: 1,
          bounds: RegionBounds(x: 90, y: 0, width: 5, height: 5),
          pathData: 'M 90 0 L 95 0 L 95 5 Z',
        ),
        MapRegion(
          code: 'EMPTY_3',
          name: '빈 지역 3',
          geometryType: 'Polygon',
          polygonCount: 1,
          bounds: RegionBounds(x: 0, y: 90, width: 5, height: 5),
          pathData: 'M 0 90 L 5 90 L 5 95 Z',
        ),
      ],
    );
    const photo = RegionPhoto(
      id: 'test',
      uri: 'file:///test-source.png',
      width: 256,
      height: 256,
      scale: 1,
      offsetX: 0,
      offsetY: 0,
      createdAt: '2026-01-02T00:00:00Z',
      takenAt: '2026-01-01',
    );
    const photos = {'korea:TEST': photo};

    final imageResult = await service.exportImage(
      asset: asset,
      mode: MapMode.korea,
      photos: photos,
      saveToGallery: false,
    );
    final image = await _decode(await imageResult.file.readAsBytes());
    expect(image.width, 1080);
    expect(image.height, 1920);
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(pixels, isNotNull);
    expect(_pixelAt(pixels!, image.width, 150, 1805), const [0, 122, 255, 255]);
    expect(_pixelAt(pixels, image.width, 500, 1805), const [
      228,
      228,
      231,
      255,
    ]);
    image.dispose();

    final videoResult = await service.exportTimelineVideo(
      asset: asset,
      mode: MapMode.korea,
      photos: photos,
      saveToGallery: false,
    );
    expect(await videoResult.file.exists(), isTrue);
    expect(await videoResult.file.length(), greaterThan(1024));
  });
}

List<int> _pixelAt(ByteData data, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return [
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

class _TestStorage extends SasangStorage {
  _TestStorage(this.image);

  final File image;

  @override
  Future<File?> resolveImage(String? uri) async => image;
}

Future<List<int>> _testImageBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 256, 256),
    Paint()..color = const Color(0xFF3B82F6),
  );
  canvas.drawCircle(
    const Offset(128, 128),
    72,
    Paint()..color = const Color(0xFFFFD166),
  );
  final image = await recorder.endRecording().toImage(256, 256);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decode(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

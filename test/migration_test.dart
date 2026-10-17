import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sasang/core/theme/sasang_theme.dart';
import 'package:sasang/core/storage/sasang_storage.dart';
import 'package:sasang/core/layout/sasang_layout.dart';
import 'package:sasang/features/more/info_content.dart';
import 'package:sasang/features/map/map_mode_selector.dart';
import 'package:sasang/features/map/map_preview.dart';
import 'package:sasang/features/map/map_repository.dart';
import 'package:sasang/features/map/region_map_view.dart';
import 'package:sasang/features/photos/photo_date.dart';
import 'package:sasang/features/photos/photo_date_dialog.dart';
import 'package:sasang/features/photos/region_photo_album_sheet.dart';
import 'package:sasang/features/share/map_share_service.dart';
import 'package:sasang/features/state/sasang_state.dart';
import 'package:sasang/models/map_models.dart';
import 'package:sasang/screens/map_screen.dart';
import 'package:sasang/screens/map_store_screen.dart';
import 'package:sasang/screens/more_screen.dart';
import 'package:sasang/screens/info_detail_screen.dart';
import 'package:sasang/screens/places_screen.dart';
import 'package:sasang/widgets/ad_banner.dart';

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

  testWidgets('photo date picker stays legible in system dark mode', (
    tester,
  ) async {
    final initialDate = DateTime(2025, 3, 9, 12);

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: SizedBox(
          height: 176,
          child: PhotoDatePicker(
            initialDate: initialDate,
            maximumDate: DateTime(2026),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final pickerContext = tester.element(
      find.byKey(const Key('photo-date-picker')),
    );
    final pickerTheme = CupertinoTheme.of(pickerContext);
    expect(pickerTheme.brightness, Brightness.light);
    expect(
      pickerTheme.textTheme.dateTimePickerTextStyle.color,
      SasangColors.ink,
    );
  });

  testWidgets('photo date picker uses Korean localization', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PhotoDatePicker(
          initialDate: DateTime(2025, 3, 9),
          maximumDate: DateTime(2026),
          onChanged: (_) {},
        ),
      ),
    );

    final pickerContext = tester.element(
      find.byKey(const Key('photo-date-picker')),
    );
    expect(Localizations.localeOf(pickerContext), const Locale('ko', 'KR'));
  });

  test('reuses the loaded map future to avoid tab-return flicker', () async {
    final repository = MapRepository();
    final first = repository.load(MapMode.korea);
    final second = repository.load(MapMode.korea);

    expect(identical(first, second), isTrue);
    expect((await first).regions, isNotEmpty);
  });

  test('selects production banner units by platform and placement', () {
    const expected = <(TargetPlatform, AdPlacement), String>{
      (TargetPlatform.android, AdPlacement.home):
          'ca-app-pub-6638972080325593/8388425749',
      (TargetPlatform.android, AdPlacement.places):
          'ca-app-pub-6638972080325593/1709240829',
      (TargetPlatform.android, AdPlacement.more):
          'ca-app-pub-6638972080325593/5864108254',
      (TargetPlatform.iOS, AdPlacement.home):
          'ca-app-pub-6638972080325593/6737134392',
      (TargetPlatform.iOS, AdPlacement.places):
          'ca-app-pub-6638972080325593/8050216064',
      (TargetPlatform.iOS, AdPlacement.more):
          'ca-app-pub-6638972080325593/2115363102',
    };
    for (final entry in expected.entries) {
      expect(
        adUnitIdFor(
          platform: entry.key.$1,
          placement: entry.key.$2,
          useTestAds: false,
        ),
        entry.value,
      );
    }
  });

  test('uses platform-specific Google test banner units in debug', () {
    expect(
      adUnitIdFor(
        placement: AdPlacement.home,
        platform: TargetPlatform.android,
        useTestAds: true,
      ),
      'ca-app-pub-3940256099942544/6300978111',
    );
    expect(
      adUnitIdFor(
        placement: AdPlacement.home,
        platform: TargetPlatform.iOS,
        useTestAds: true,
      ),
      'ca-app-pub-3940256099942544/2934735716',
    );
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

  test('builds a chronological map timeline for the selected map only', () {
    const asset = RegionMapAsset(
      version: 'test',
      width: 100,
      height: 100,
      regions: [
        MapRegion(
          code: 'A',
          name: '첫 번째',
          geometryType: 'Polygon',
          polygonCount: 1,
          bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
          pathData: 'M 0 0 L 10 0 L 10 10 Z',
        ),
        MapRegion(
          code: 'B',
          name: '두 번째',
          geometryType: 'Polygon',
          polygonCount: 1,
          bounds: RegionBounds(x: 10, y: 10, width: 10, height: 10),
          pathData: 'M 10 10 L 20 10 L 20 20 Z',
        ),
      ],
    );
    const earlier = RegionPhoto(
      id: 'earlier',
      uri: 'file:///earlier.jpg',
      width: 100,
      height: 100,
      scale: 1,
      offsetX: 0,
      offsetY: 0,
      createdAt: '2025-02-01T00:00:00Z',
      takenAt: '2024-01-01',
    );
    const later = RegionPhoto(
      id: 'later',
      uri: 'file:///later.jpg',
      width: 100,
      height: 100,
      scale: 1,
      offsetX: 0,
      offsetY: 0,
      createdAt: '2025-01-01T00:00:00Z',
      takenAt: '2024-06-01',
    );

    final timeline = buildMapTimeline(
      asset: asset,
      mode: MapMode.korea,
      photos: {'korea:A': later, 'korea:B': earlier, 'world:A': earlier},
    );

    expect(timeline.map((item) => item.region.code), ['B', 'A']);
    final compactMotion = timelineMotionSteps(timeline.length);
    expect(compactMotion.travelFrames, 18);
    expect(compactMotion.revealFrames, 10);
    expect(compactMotion.holdFrames, 12);
    expect(timelineMotionSteps(80).travelFrames, 8);
    expect(mapTravelPercentage(2, 175), 1);
    expect(
      mapTravelProgress(
        asset: asset,
        mode: MapMode.korea,
        photos: {'korea:B': earlier, 'world:A': earlier},
      ),
      .5,
    );
    expect(regionFocusZoom(asset.regions.first, asset), 4.2);
  });

  test('wraps legacy region photos in backward-compatible albums', () {
    final decoded = decodeStoredPhotoState({
      'regionPhotos': {
        'korea:11680': {
          'id': 'legacy',
          'uri': 'file:///legacy.jpg',
          'width': 100,
          'height': 80,
          'scale': 1,
          'offsetX': 0,
          'offsetY': 0,
          'createdAt': '2025-01-01T00:00:00Z',
        },
      },
    });

    expect(decoded.albums['korea:11680']!.photos, hasLength(1));
    expect(decoded.albums['korea:11680']!.coverPhoto!.id, 'legacy');
    expect(decoded.photos['korea:11680']!.uri, 'file:///legacy.jpg');
  });

  test('keeps multiple photos and the selected cover in timeline order', () {
    const region = MapRegion(
      code: 'A',
      name: '지역',
      geometryType: 'Polygon',
      polygonCount: 1,
      bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
      pathData: 'M 0 0 L 10 0 L 10 10 Z',
    );
    const asset = RegionMapAsset(
      version: 'test',
      width: 100,
      height: 100,
      regions: [region],
    );
    final old = _photo('old', '2024-01-01');
    final recent = _photo('recent', '2025-01-01');
    final album = RegionPhotoAlbum(
      photos: [recent, old],
      coverPhotoId: recent.id,
    );
    final timeline = buildMapTimeline(
      asset: asset,
      mode: MapMode.korea,
      photos: {'korea:A': recent},
      albums: {'korea:A': album},
    );

    expect(timeline.map((item) => item.photo.id), ['old', 'recent']);
    expect(album.coverPhoto!.id, 'recent');
  });

  test(
    'adds, changes cover, and removes album photos without losing legacy cover',
    () async {
      final storage = _MemoryStorage();
      final state = SasangState(storage);
      final first = _photo('first', '2025-01-01');
      final second = _photo('second', '2025-02-01');

      state.addRegionPhoto(MapMode.korea, 'A', first);
      state.addRegionPhoto(MapMode.korea, 'A', second);
      expect(state.regionAlbum(MapMode.korea, 'A')!.photos, hasLength(2));
      expect(state.regionPhotos['korea:A']!.id, 'first');

      state.setRegionCoverPhoto(MapMode.korea, 'A', second.id);
      expect(state.regionPhotos['korea:A']!.id, 'second');
      state.removePhoto(MapMode.korea, 'A', second.id);
      expect(state.regionPhotos['korea:A']!.id, 'first');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(storage.albums['korea:A']!.photos.single.id, 'first');
    },
  );

  testWidgets('region album shows photos and a final add card', (tester) async {
    final storage = _MemoryStorage();
    final state = SasangState(storage);
    state.addRegionPhoto(MapMode.korea, 'A', _photo('one', '2025-01-01'));
    state.addRegionPhoto(MapMode.korea, 'A', _photo('two', '2025-02-01'));
    const region = MapRegion(
      code: 'A',
      name: '테스트 지역',
      geometryType: 'Polygon',
      polygonCount: 1,
      bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
      pathData: 'M 0 0 L 10 0 L 10 10 Z',
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: RegionPhotoAlbumSheet(
            state: state,
            mode: MapMode.korea,
            region: region,
            onAdd: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('사진 2장'), findsOneWidget);
    expect(find.byKey(const Key('region-photo-carousel')), findsOneWidget);
    final tiltedCard = tester.widget<Transform>(
      find.byKey(const Key('region-album-card-tilt-0')),
    );
    expect(tiltedCard.transform.entry(0, 1).abs(), greaterThan(.01));
    await tester.drag(
      find.byKey(const Key('region-photo-carousel')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('region-photo-carousel')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('region-album-add-card')), findsOneWidget);
  });

  testWidgets('region album uses a landscape card for a landscape photo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = _MemoryStorage();
    final state = SasangState(storage);
    state.addRegionPhoto(
      MapMode.korea,
      'A',
      RegionPhoto(
        id: 'landscape',
        uri: 'file:///landscape.jpg',
        width: 1600,
        height: 900,
        scale: 1,
        offsetX: 0,
        offsetY: 0,
        createdAt: '2025-01-01T00:00:00Z',
        takenAt: '2025-01-01',
      ),
    );
    const region = MapRegion(
      code: 'A',
      name: '테스트 지역',
      geometryType: 'Polygon',
      polygonCount: 1,
      bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
      pathData: 'M 0 0 L 10 0 L 10 10 Z',
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: RegionPhotoAlbumSheet(
            state: state,
            mode: MapMode.korea,
            region: region,
            onAdd: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final size = tester.getSize(
      find.byKey(const Key('region-album-photo-card-landscape')),
    );
    expect(size.width / size.height, closeTo(16 / 9, .01));
    expect(size.height, lessThan(310));
  });

  test('region subtitles hide internal administrative codes', () {
    const antarctica = MapRegion(
      code: 'AQ',
      name: '남극',
      englishName: 'Antarctica',
      geometryType: 'MultiPolygon',
      polygonCount: 1,
      bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
      pathData: 'M 0 0 L 10 0 L 10 10 Z',
    );
    const gangnam = MapRegion(
      code: '11680',
      name: '강남구',
      provinceName: '서울특별시',
      geometryType: 'Polygon',
      polygonCount: 1,
      bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
      pathData: 'M 0 0 L 10 0 L 10 10 Z',
    );

    expect(regionDisplaySubtitle(antarctica, MapMode.world), 'Antarctica');
    expect(regionDisplaySubtitle(gangnam, MapMode.korea), '서울특별시');
    expect(
      regionDisplaySubtitle(antarctica, MapMode.world),
      isNot(contains('AQ')),
    );
    expect(
      regionDisplaySubtitle(gangnam, MapMode.korea),
      isNot(contains('11680')),
    );
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

  test('overlaps the map control with the bottom bar', () {
    expect(sasangBottomBarTopOffset(34), 100);
    expect(sasangBottomBarTopOffset(24), 90);
    expect(sasangBottomBarTopOffset(0), 80);
    expect(sasangMapOverlayBottomOffset(34), 64);
    expect(sasangZoomControlsBottomOffset(34), 170);
    expect(sasangZoomControlsBottomOffset(0), 136);
    expect(
      sasangBottomBarTopOffset(34) - sasangMapOverlayBottomOffset(34),
      sasangMapOverlayOverlap,
    );
  });

  testWidgets('map store uses country previews instead of code placeholders', (
    tester,
  ) async {
    final asset = RegionMapAsset.fromJsonString(
      File('assets/maps/world/countries.json').readAsStringSync(),
    );
    await tester.pumpWidget(
      MaterialApp(home: MapStoreScreen(mapAsset: Future.value(asset))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('국가별 지도'), findsOneWidget);
    expect(find.text('${asset.regions.length}개'), findsOneWidget);
    expect(mapStoreProducts(asset).length, asset.regions.length);
    expect(find.byIcon(CupertinoIcons.lock_fill), findsNothing);
    expect(find.text('출시 예정'), findsWidgets);
    expect(find.text('JP'), findsNothing);

    final firstProduct = mapStoreProducts(asset).first;
    final firstCard = tester.widget<Container>(
      find.byKey(Key('map-store-product-${firstProduct.code}')),
    );
    final firstCardDecoration = firstCard.decoration! as BoxDecoration;
    expect(firstCardDecoration.borderRadius, SasangRadii.contentCard);
    expect(firstCardDecoration.border, isNotNull);
    expect(firstCardDecoration.boxShadow, isNull);

    await tester.tap(find.byKey(Key('map-store-product-${firstProduct.code}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('map-store-modal-top-space')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('map-store-modal-top-space'))).height,
      12,
    );
  });

  test('map store prices stay within deterministic detail tiers', () {
    MapRegion regionWithDetail(int length) => MapRegion(
      code: 'XX',
      name: '테스트',
      geometryType: 'Polygon',
      polygonCount: 1,
      bounds: const RegionBounds(x: 0, y: 0, width: 10, height: 10),
      pathData: List.filled(length, 'M').join(),
    );

    expect(mapStorePriceFor(regionWithDetail(100)), 2000);
    expect(mapStorePriceFor(regionWithDetail(400)), 3000);
    expect(mapStorePriceFor(regionWithDetail(800)), 4000);
    expect(mapStorePriceFor(regionWithDetail(1300)), 5000);
  });

  testWidgets('information pages use their own titles and document layout', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final privacy = InfoContent.byId('privacy')!;
    await tester.pumpWidget(
      MaterialApp(
        theme: SasangTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: InfoDetailScreen(content: privacy),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('개인정보 처리방침'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('info-effective-date-privacy')),
      findsOneWidget,
    );
    expect(find.text('기기 저장'), findsOneWidget);
    expect(find.text('외부 서비스'), findsOneWidget);
    expect(find.text('정보 삭제'), findsOneWidget);
    expect(find.textContaining('정식 개인정보 처리방침은'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('정보 삭제'),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('info-document-privacy')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final terms = InfoContent.byId('terms')!;
    await tester.pumpWidget(
      MaterialApp(
        theme: SasangTheme.light,
        home: InfoDetailScreen(content: terms),
      ),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('이용약관'),
      ),
      findsOneWidget,
    );
    expect(find.text('사진 사용'), findsOneWidget);
    expect(find.text('지도 정보'), findsOneWidget);
    expect(find.textContaining('정식 이용약관은'), findsNothing);
  });

  testWidgets('app info reads installed version and opens real licenses', (
    tester,
  ) async {
    final appInfo = InfoContent.byId('app')!;
    final packageInfo = PackageInfo(
      appName: '사상',
      packageName: 'com.sasang.app',
      version: '1.1.1',
      buildNumber: '29',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: SasangTheme.light,
        home: InfoDetailScreen(
          content: appInfo,
          packageInfo: Future.value(packageInfo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-info-icon')), findsOneWidget);
    expect(find.text('사상'), findsOneWidget);
    expect(find.text('나의 여행을 지도에 남기다'), findsOneWidget);
    expect(find.text('1.1.1 (29)'), findsOneWidget);
    expect(find.textContaining('정식 배포 단계'), findsNothing);

    await tester.tap(find.byKey(const Key('open-source-licenses-button')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('information detail keeps navigator and system back behavior', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SasangTheme.light,
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    InfoDetailScreen(content: InfoContent.byId('terms')!),
              ),
            ),
            child: const Text('상세 열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('상세 열기'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoNavigationBarBackButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.text('이용약관'),
      ),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('상세 열기'), findsOneWidget);
  });

  testWidgets('map store keeps a two-column grid with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const asset = RegionMapAsset(
      version: 'test',
      width: 100,
      height: 100,
      regions: [
        MapRegion(
          code: 'AA',
          name: '가상 국가 A',
          geometryType: 'Polygon',
          polygonCount: 1,
          bounds: RegionBounds(x: 0, y: 0, width: 40, height: 40),
          pathData: 'M 0 0 L 40 0 L 40 40 Z',
        ),
        MapRegion(
          code: 'BB',
          name: '가상 국가 B',
          geometryType: 'Polygon',
          polygonCount: 1,
          bounds: RegionBounds(x: 50, y: 50, width: 40, height: 40),
          pathData: 'M 50 50 L 90 50 L 90 90 Z',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: SasangTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: MapStoreScreen(mapAsset: Future.value(asset)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final firstRect = tester.getRect(
      find.byKey(const Key('map-store-product-AA')),
    );
    final secondRect = tester.getRect(
      find.byKey(const Key('map-store-product-BB')),
    );
    expect(firstRect.top, closeTo(secondRect.top, 1));
    expect(firstRect.right, lessThan(secondRect.left));
    expect(tester.takeException(), isNull);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('owned map selector restores card sheet on $platform', (
      tester,
    ) async {
      var selectedMode = MapMode.korea;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          routes: {'/map-store': (_) => const SizedBox.shrink()},
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MapModeSelector(
                value: selectedMode,
                onChanged: (value) => setState(() => selectedMode = value),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MapModeSelector));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final selectorPill = tester.widget<Container>(
        find.byKey(const Key('map-mode-selector-pill')),
      );
      final selectorDecoration = selectorPill.decoration! as BoxDecoration;
      expect(selectorDecoration.borderRadius, SasangRadii.pill);

      expect(find.text('내 지도'), findsOneWidget);
      expect(find.text('보유한 지도'), findsOneWidget);
      expect(find.byType(MapPreview), findsNWidgets(2));
      expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
      expect(find.text('새로운 지도 둘러보기'), findsOneWidget);

      final sheet = tester.widget<Container>(
        find.byKey(const Key('map-mode-sheet')),
      );
      final sheetDecoration = sheet.decoration! as BoxDecoration;
      expect(sheetDecoration.borderRadius, SasangRadii.sheetTop);

      final selectedCard = tester.widget<Container>(
        find.byKey(const Key('map-mode-card-korea')),
      );
      final cardDecoration = selectedCard.decoration! as BoxDecoration;
      final foreground = selectedCard.foregroundDecoration! as BoxDecoration;
      expect(cardDecoration.borderRadius, SasangRadii.selectionCard);
      expect(foreground.borderRadius, SasangRadii.selectionCard);
      expect(foreground.border!.top.width, 1.5);
      expect(foreground.border!.top.color, SasangColors.accent);

      final previewClip = tester.widget<ClipRRect>(
        find.byKey(const Key('map-mode-preview-clip-korea')),
      );
      expect(previewClip.borderRadius, SasangRadii.selectionCard);

      final browseButton = tester.widget<CupertinoButton>(
        find.byKey(const Key('map-store-browse-button')),
      );
      expect(browseButton.borderRadius, SasangRadii.actionButton);
      final browseSurface = tester.widget<Container>(
        find.byKey(const Key('map-store-browse-surface')),
      );
      final browseDecoration = browseSurface.decoration! as BoxDecoration;
      expect(browseDecoration.borderRadius, SasangRadii.actionButton);

      await tester.tap(find.byKey(const Key('map-mode-card-world')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(selectedMode, MapMode.world);
    });
  }

  testWidgets('owned map sheet opens the map store', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/map-store': (_) => const SizedBox(key: Key('map-store-route')),
        },
        home: Scaffold(
          body: MapModeSelector(value: MapMode.korea, onChanged: (_) {}),
        ),
      ),
    );

    await tester.tap(find.byType(MapModeSelector));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('새로운 지도 둘러보기'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map-store-route')), findsOneWidget);
  });

  testWidgets('video export progress floats without a blocking dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MapExportFloatingProgress(
              progress: MapExportProgress(MapExportPhase.rendering, .42),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('share-export-floating-progress')),
      findsOneWidget,
    );
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.text('42%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('share-video-progress')),
          )
          .value,
      .42,
    );
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('export format picker uses the Sasang sheet on $platform', (
      tester,
    ) async {
      MapShareFormat? selectedFormat;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () async {
                selectedFormat = await showSasangExportFormatPicker(context);
              },
              child: const Text('열기'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(
        find.byKey(const Key('share-format-sheet-content')),
        findsOneWidget,
      );
      expect(find.text('원하는 형식을 선택해 주세요.'), findsOneWidget);
      expect(find.text('9:16 이미지 · 여행 비율 포함'), findsOneWidget);
      expect(find.text('촬영일 순 여행 타임라인 · 9:16 MP4'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.photo), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.play_rectangle), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_forward), findsNWidgets(2));
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);

      final imageRow = find.byKey(const Key('share-map-image'));
      final videoRow = find.byKey(const Key('share-map-video'));
      expect(imageRow, findsOneWidget);
      expect(videoRow, findsOneWidget);

      final expectedFormat = platform == TargetPlatform.iOS
          ? MapShareFormat.image
          : MapShareFormat.video;
      await tester.tap(
        expectedFormat == MapShareFormat.image ? imageRow : videoRow,
      );
      await tester.pumpAndSettle();
      expect(selectedFormat, expectedFormat);
      expect(find.byKey(const Key('share-format-sheet-content')), findsNothing);
    });
  }

  testWidgets('encoding progress does not display a fabricated percentage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapExportFloatingProgress(
            progress: MapExportProgress(MapExportPhase.encoding),
          ),
        ),
      ),
    );

    expect(find.text('영상을 저장하고 있어요'), findsOneWidget);
    expect(find.byKey(const Key('share-video-progress-percent')), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('share-video-progress')),
          )
          .value,
      isNull,
    );
  });

  test('travel progress drops decimals and stays within 0 to 100 percent', () {
    expect(travelProgressPercent(3, 161), 1);
    expect(travelProgressPercent(1, 175), 0);
    expect(travelProgressPercent(161, 161), 100);
    expect(travelProgressPercent(200, 161), 100);
    expect(travelProgressPercent(0, 0), 0);
  });

  testWidgets('map top bar shows a compact travel percentage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapTopBar(
            count: 3,
            totalCount: 161,
            mode: MapMode.korea,
            onShare: () {},
            onModeChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('map-record-summary')), findsOneWidget);
    expect(find.text('3개 지역'), findsOneWidget);
    expect(find.text('1%'), findsOneWidget);
    expect(find.byKey(const Key('map-share-button')), findsOneWidget);
    expect(find.byType(MapModeSelector), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('map search field keeps compact typography', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MapSearchBar(
                controller: controller,
                mode: MapMode.korea,
                onChanged: (_) {},
                onClear: () {},
              ),
              Expanded(
                child: GestureDetector(
                  key: const Key('map-test-area'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final field = tester.widget<CupertinoSearchTextField>(
      find.byKey(const Key('map-search-field')),
    );
    expect(field.style?.fontSize, 14);
    expect(field.placeholderStyle?.fontSize, 14);
    expect(field.placeholder, '지역 이름 검색');
    expect(tester.getSize(find.byType(MapSearchBar)).height, 46);
    expect(find.byKey(const Key('sasang-blur-shadow')), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-search-field')));
    await tester.pump();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(20, 100));
    await tester.pump();
    expect(editable.focusNode.hasFocus, isFalse);
  });

  testWidgets('map search results use a minimal separated list', (
    tester,
  ) async {
    MapRegion? selected;
    const results = [
      MapRegion(
        code: '11680',
        name: '강남구',
        provinceName: '서울특별시',
        geometryType: 'Polygon',
        polygonCount: 1,
        bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
        pathData: 'M 0 0 L 10 0 L 10 10 Z',
      ),
      MapRegion(
        code: '11740',
        name: '강동구',
        provinceName: '서울특별시',
        geometryType: 'Polygon',
        polygonCount: 1,
        bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
        pathData: 'M 0 0 L 10 0 L 10 10 Z',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchResults(
            results: results,
            mode: MapMode.korea,
            onSelected: (region) => selected = region,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('map-search-results')), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.circle_fill), findsNothing);
    expect(find.text('서울특별시'), findsNWidgets(2));
    expect(
      tester.getSize(find.byKey(const Key('map-search-result-11680'))).height,
      58,
    );

    await tester.tap(find.byKey(const Key('map-search-result-11740')));
    expect(selected?.code, '11740');
  });

  testWidgets('map search empty state stays text-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchResults(
            results: const [],
            mode: MapMode.world,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('map-search-empty')), findsOneWidget);
    expect(find.text('일치하는 지역이 없어요'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('places restores the compact filter bar and card empty state', (
    tester,
  ) async {
    final state = SasangState(SasangStorage());
    final mapAsset = Future.value(
      const RegionMapAsset(
        version: 'test',
        width: 360,
        height: 520,
        regions: [],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlacesScreen(
            state: state,
            onOpenMap: () {},
            mapAsset: mapAsset,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('places-filter-bar')), findsOneWidget);
    expect(find.byKey(const Key('places-sort-button')), findsOneWidget);
    expect(find.text('최신순'), findsOneWidget);
    expect(find.byKey(const Key('places-empty-state')), findsOneWidget);
    expect(find.text('아직 기록이 없어요'), findsOneWidget);
    expect(find.text('지도에서 시작하기'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.map_pin_ellipse), findsNothing);

    final mapSelector = tester.widget<MapModeSelector>(
      find.byType(MapModeSelector),
    );
    expect(mapSelector.elevated, isTrue);
    final sortSurface = tester.widget<Container>(
      find.byKey(const Key('places-sort-surface')),
    );
    final sortDecoration = sortSurface.decoration! as BoxDecoration;
    expect(sortDecoration.boxShadow, isNotEmpty);
    final emptyState = tester.widget<Container>(
      find.byKey(const Key('places-empty-state')),
    );
    final emptyDecoration = emptyState.decoration! as BoxDecoration;
    expect(emptyDecoration.color, CupertinoColors.white);
    expect(emptyDecoration.border, isNotNull);
    expect(emptyDecoration.boxShadow, sortDecoration.boxShadow);
    final emptyAction = tester.widget<CupertinoButton>(
      find.byKey(const Key('places-empty-action')),
    );
    expect(emptyAction.color, SasangColors.accent);
    expect(find.byIcon(CupertinoIcons.arrow_right), findsOneWidget);

    final selectorRect = tester.getRect(find.byType(MapModeSelector));
    final sortRect = tester.getRect(
      find.byKey(const Key('places-sort-button')),
    );
    expect(selectorRect.left, lessThan(sortRect.left));
    expect(selectorRect.center.dy, closeTo(sortRect.center.dy, 1));
  });

  testWidgets('more screen groups navigation, information, and account rows', (
    tester,
  ) async {
    final state = SasangState(SasangStorage());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MoreScreen(state: state)),
      ),
    );
    await tester.pump();

    expect(find.text('개인 프로필'), findsNothing);
    expect(find.text('프로필 사진과 표시 이름을 관리해요'), findsNothing);
    expect(find.text('수정'), findsNothing);
    expect(find.byKey(const Key('more-page-title')), findsOneWidget);
    expect(find.text('지도'), findsOneWidget);
    expect(find.text('약관 및 정보'), findsOneWidget);
    expect(find.text('지도 상점'), findsOneWidget);

    final adArea = tester.getSize(find.byKey(const Key('more-ad-area')));
    expect(adArea.height, 58);

    for (final id in ['map', 'information']) {
      final card = tester.widget<Container>(
        find.byKey(Key('more-section-card-$id')),
      );
      final decoration = card.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFFFFF));
      expect(decoration.borderRadius, BorderRadius.circular(19));
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNull);
    }

    await tester.scrollUntilVisible(
      find.text('계정 및 데이터'),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('more-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    expect(find.text('계정 및 데이터'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('데이터 지우고 로그아웃하기'), findsOneWidget);

    final accountCard = tester.widget<Container>(
      find.byKey(const Key('more-section-card-account')),
    );
    final accountDecoration = accountCard.decoration! as BoxDecoration;
    expect(accountDecoration.boxShadow, isNull);

    final logoutText = tester.widget<Text>(find.text('로그아웃'));
    final clearText = tester.widget<Text>(find.text('데이터 지우고 로그아웃하기'));
    expect(logoutText.style?.color, SasangColors.ink);
    expect(clearText.style?.color, CupertinoColors.systemRed);

    await tester.tap(find.byKey(const Key('more-menu-로그아웃')));
    await tester.pumpAndSettle();
    var actions = tester
        .widgetList<CupertinoDialogAction>(find.byType(CupertinoDialogAction))
        .toList();
    expect(actions.last.isDestructiveAction, isFalse);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('more-menu-데이터 지우고 로그아웃하기')));
    await tester.pumpAndSettle();
    actions = tester
        .widgetList<CupertinoDialogAction>(find.byType(CupertinoDialogAction))
        .toList();
    expect(actions.last.isDestructiveAction, isTrue);
  });

  testWidgets('more screen remains scrollable with large accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = SasangState(SasangStorage());
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(body: MoreScreen(state: state)),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('데이터 지우고 로그아웃하기'),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('more-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();

    expect(find.text('데이터 지우고 로그아웃하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

RegionPhoto _photo(String id, String takenAt) => RegionPhoto(
  id: id,
  uri: 'file:///$id.jpg',
  width: 100,
  height: 100,
  scale: 1,
  offsetX: 0,
  offsetY: 0,
  createdAt: '${takenAt}T00:00:00Z',
  takenAt: takenAt,
);

class _MemoryStorage extends SasangStorage {
  Map<String, RegionPhotoAlbum> albums = {};

  @override
  Future<void> writePhotoAlbums(Map<String, RegionPhotoAlbum> albums) async {
    this.albums = Map.of(albums);
  }

  @override
  Future<File?> resolveImage(String? uri) async => null;
}

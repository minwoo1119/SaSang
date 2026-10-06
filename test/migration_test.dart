import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sasang/core/theme/sasang_theme.dart';
import 'package:sasang/core/storage/sasang_storage.dart';
import 'package:sasang/core/layout/sasang_layout.dart';
import 'package:sasang/features/map/map_mode_selector.dart';
import 'package:sasang/features/map/map_preview.dart';
import 'package:sasang/features/map/map_repository.dart';
import 'package:sasang/features/map/region_map_view.dart';
import 'package:sasang/features/photos/photo_date.dart';
import 'package:sasang/features/photos/photo_date_dialog.dart';
import 'package:sasang/features/share/map_share_service.dart';
import 'package:sasang/features/state/sasang_state.dart';
import 'package:sasang/models/map_models.dart';
import 'package:sasang/screens/map_screen.dart';
import 'package:sasang/screens/map_store_screen.dart';
import 'package:sasang/screens/more_screen.dart';
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
    expect(compactMotion.travelFrames, 5);
    expect(compactMotion.revealFrames, 4);
    expect(compactMotion.holdFrames, 3);
    expect(timelineMotionSteps(80).travelFrames, 1);
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
    expect(find.byIcon(CupertinoIcons.lock_fill), findsWidgets);
    expect(find.text('JP'), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.lock_fill).first);
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

  testWidgets('owned map selector restores the illustrated iOS sheet', (
    tester,
  ) async {
    var selectedMode = MapMode.korea;
    await tester.pumpWidget(
      MaterialApp(
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

    await tester.tap(find.text('대한민국 지도'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('내 지도'), findsOneWidget);
    expect(find.text('보유한 지도'), findsOneWidget);
    expect(find.byType(MapPreview), findsNWidgets(2));
    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    expect(find.text('새로운 지도 둘러보기'), findsOneWidget);

    final selectedCard = tester.widget<Container>(
      find.byKey(const Key('map-mode-card-korea')),
    );
    expect(selectedCard.clipBehavior, Clip.none);
    final foreground = selectedCard.foregroundDecoration! as BoxDecoration;
    expect(foreground.border!.top.width, 1.5);
    expect(foreground.border!.top.color, const Color(0xFF007AFF));
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
    final emptySurface = tester.widget<Container>(
      find.byKey(const Key('places-empty-state')),
    );
    final emptyDecoration = emptySurface.decoration! as BoxDecoration;
    expect(emptyDecoration.boxShadow, sortDecoration.boxShadow);

    final selectorRect = tester.getRect(find.byType(MapModeSelector));
    final sortRect = tester.getRect(
      find.byKey(const Key('places-sort-button')),
    );
    expect(selectorRect.left, lessThan(sortRect.left));
    expect(selectorRect.center.dy, closeTo(sortRect.center.dy, 1));
  });

  testWidgets('more screen no longer shows personal profile controls', (
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
    expect(find.text('지도 상점'), findsOneWidget);
  });
}

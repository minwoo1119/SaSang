import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sasang/core/l10n/sasang_localizations.dart';
import 'package:sasang/core/storage/sasang_storage.dart';
import 'package:sasang/features/photos/photo_date_dialog.dart';
import 'package:sasang/features/photos/region_photo_album_sheet.dart';
import 'package:sasang/features/share/map_share_service.dart';
import 'package:sasang/features/state/sasang_state.dart';
import 'package:sasang/models/map_models.dart';
import 'package:sasang/screens/map_screen.dart';
import 'package:sasang/screens/onboarding_screen.dart';
import 'package:sasang/widgets/ad_banner.dart';

void main() {
  const smallScreen = Size(320, 568);

  setUp(() => SasangLocalizations.use(SasangLanguage.korean));

  for (final language in SasangLanguage.values) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'onboarding supports ${language.code} at ${scale}x text scale',
        (tester) async {
          await _useSurface(tester, smallScreen);
          SasangLocalizations.use(language);
          final state = SasangState(_MemoryStorage());
          await tester.pumpWidget(
            _testApp(
              textScale: scale,
              locale: language.locale,
              home: OnboardingScreen(state: state),
              routes: {'/home': (_) => const SizedBox.shrink()},
            ),
          );

          for (var page = 0; page < 5; page += 1) {
            expect(tester.takeException(), isNull);
            if (page < 4) {
              await tester.tap(
                find.byKey(const Key('onboarding-primary-action')),
              );
              await tester.pumpAndSettle();
            }
          }
        },
      );
    }
  }

  testWidgets('region photo sheet fits a small screen at 2x text scale', (
    tester,
  ) async {
    await _useSurface(tester, smallScreen);
    final state = SasangState(_MemoryStorage());
    await tester.pumpWidget(
      _testApp(
        textScale: 2,
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => showRegionPhotoAlbumSheet(
              context: context,
              state: state,
              mode: MapMode.korea,
              region: _region,
              onAdd: () async {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('region-photo-album-sheet')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo date dialog fits a small screen at 2x text scale', (
    tester,
  ) async {
    await _useSurface(tester, smallScreen);
    await tester.pumpWidget(
      _testApp(
        textScale: 2,
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => showPhotoDateDialog(
              context,
              photo: File('assets/icon/app_icon.png'),
              initialDate: DateTime(2026, 11, 22),
              dateFromMetadata: false,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('photo-date-picker')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('export sheet fits a small screen at 2x text scale', (
    tester,
  ) async {
    await _useSurface(tester, smallScreen);
    MapShareFormat? result;
    await tester.pumpWidget(
      _testApp(
        textScale: 2,
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () async {
              result = await showSasangExportFormatPicker(context);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('share-format-sheet-content')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('share-map-image')));
    await tester.pumpAndSettle();
    expect(result, MapShareFormat.image);
  });

  testWidgets('ad banner reserves the same height before and after loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdBannerFrame(child: SizedBox(width: 320, height: 50)),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(AdBannerFrame)).height,
      adBannerReservedHeight,
    );
  });
}

const _region = MapRegion(
  code: '11680',
  name: '강남구',
  englishName: 'Gangnam-gu',
  japaneseName: '江南区',
  simplifiedChineseName: '江南区',
  geometryType: 'Polygon',
  polygonCount: 1,
  bounds: RegionBounds(x: 0, y: 0, width: 10, height: 10),
  pathData: 'M 0 0 L 10 0 L 10 10 Z',
);

MaterialApp _testApp({
  required Widget home,
  required double textScale,
  Locale locale = const Locale('ko'),
  Map<String, WidgetBuilder> routes = const {},
}) => MaterialApp(
  locale: locale,
  supportedLocales: SasangLocalizations.supportedLocales,
  localizationsDelegates: const [
    SasangLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  routes: routes,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

Future<void> _useSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _MemoryStorage extends SasangStorage {
  @override
  Future<void> writeSession({
    required bool hasStarted,
    required bool hasCompletedOnboarding,
    required String languageCode,
  }) async {}
}

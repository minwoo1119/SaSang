import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sasang/features/share/map_share_service.dart';
import 'package:sasang/screens/map_screen.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('SUIT')
      ..addFont(rootBundle.load('assets/fonts/SUIT-Heavy.ttf'));
    await loader.load();
  });

  testWidgets('captures the floating export progress review surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _reviewTheme(),
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: _MapBackdrop()),
              const Positioned(
                left: 24,
                right: 24,
                bottom: 94,
                child: MapExportFloatingProgress(
                  progress: MapExportProgress(MapExportPhase.rendering, .42),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/floating_export_progress.png'),
    );
  });

  testWidgets('captures the Sasang export format sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _reviewTheme(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) => Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: _MapBackdrop()),
                Center(
                  child: CupertinoButton(
                    onPressed: () => showSasangExportFormatPicker(context),
                    child: const Text('내보내기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('내보내기'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Overlay),
      matchesGoldenFile('goldens/adaptive_export_format_picker.png'),
    );
  });
}

ThemeData _reviewTheme({TargetPlatform? platform}) => ThemeData(
  platform: platform,
  fontFamily: 'SUIT',
  cupertinoOverrideTheme: const CupertinoThemeData(
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(fontFamily: 'SUIT'),
      actionTextStyle: TextStyle(fontFamily: 'SUIT'),
      navTitleTextStyle: TextStyle(fontFamily: 'SUIT'),
    ),
  ),
);

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFFAFAFA),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _MapBackdropPainter())),
        const SafeArea(
          minimum: EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(19)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                child: Text(
                  '3개 지역  ·  2%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MapBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE4E4E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(size.width * .18, size.height * .28)
      ..quadraticBezierTo(
        size.width * .55,
        size.height * .12,
        size.width * .76,
        size.height * .35,
      )
      ..quadraticBezierTo(
        size.width * .88,
        size.height * .56,
        size.width * .61,
        size.height * .68,
      )
      ..quadraticBezierTo(
        size.width * .32,
        size.height * .76,
        size.width * .16,
        size.height * .5,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

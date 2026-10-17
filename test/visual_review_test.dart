import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sasang/features/backup/backup_progress_dialog.dart';
import 'package:sasang/features/photos/north_korea_visit_gate.dart';
import 'package:sasang/features/share/export_progress_dialog.dart';
import 'package:sasang/features/share/map_share_service.dart';
import 'package:sasang/screens/map_screen.dart';
import 'package:sasang/widgets/sasang_center_modal.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('SUIT')
      ..addFont(rootBundle.load('assets/fonts/SUIT-Heavy.ttf'));
    final iconLoader = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await Future.wait([loader.load(), iconLoader.load()]);
  });

  const progressCaptures = [
    (name: 'preparing', progress: MapExportProgress(MapExportPhase.preparing)),
    (
      name: 'rendering',
      progress: MapExportProgress(MapExportPhase.rendering, .42),
    ),
    (name: 'saving', progress: MapExportProgress(MapExportPhase.encoding)),
    (name: 'failed', progress: MapExportProgress(MapExportPhase.failed)),
  ];

  for (final capture in progressCaptures) {
    testWidgets('captures export progress ${capture.name}', (tester) async {
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
                ExportProgressDialog(
                  progress: capture.progress,
                  format: MapShareFormat.video,
                  onCancel:
                      capture.progress.phase == MapExportPhase.preparing ||
                          capture.progress.phase == MapExportPhase.rendering
                      ? () {}
                      : null,
                  onRetry: capture.progress.phase == MapExportPhase.failed
                      ? () {}
                      : null,
                  onClose: capture.progress.phase == MapExportPhase.failed
                      ? () {}
                      : null,
                ),
              ],
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/export_progress_${capture.name}.png'),
      );
    });
  }

  testWidgets('captures backup progress', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _reviewTheme(),
        home: const Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: _MapBackdrop()),
              BackupProgressDialog(),
            ],
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/backup_progress.png'),
    );
  });

  testWidgets('captures North Korea confirmation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _reviewTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: _MapBackdrop()),
                Center(
                  child: CupertinoButton(
                    onPressed: () => showSasangCenterConfirmDialog(
                      context,
                      title: '북한 방문 확인 · 1/3',
                      message: northKoreaConfirmationMessage(1),
                      action: '확인',
                    ),
                    child: const Text('북한 선택'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('북한 선택'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Overlay),
      matchesGoldenFile('goldens/north_korea_confirmation.png'),
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

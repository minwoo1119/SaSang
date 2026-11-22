import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _goldenPrecisionTolerance = 0.0001;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  goldenFileComparator = _SasangGoldenFileComparator(
    Uri.parse('test/visual_review_test.dart'),
    precisionTolerance: _goldenPrecisionTolerance,
  );
  await testMain();
}

class _SasangGoldenFileComparator extends LocalFileComparator {
  _SasangGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(
         0 <= precisionTolerance && precisionTolerance <= 1,
         'precisionTolerance must be between 0 and 1',
       ),
       _precisionTolerance = precisionTolerance;

  /// Allows only a 0.01% pixel difference for host rasterizer variance.
  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

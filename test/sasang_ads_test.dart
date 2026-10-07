import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sasang/core/ads/sasang_ads.dart';

void main() {
  test(
    'iOS requests ATT authorization before initializing mobile ads',
    () async {
      final calls = <String>[];
      final ads = SasangAds(
        platform: TargetPlatform.iOS,
        requestTrackingAuthorization: () async => calls.add('tracking'),
        initializeMobileAds: () async => calls.add('ads'),
      );

      final ready = await ads.start();

      expect(calls, ['tracking', 'ads']);
      expect(ready, isTrue);
    },
  );

  test('non-iOS platforms initialize ads without requesting ATT', () async {
    final calls = <String>[];
    final ads = SasangAds(
      platform: TargetPlatform.android,
      requestTrackingAuthorization: () async => calls.add('tracking'),
      initializeMobileAds: () async => calls.add('ads'),
    );

    final ready = await ads.start();

    expect(calls, ['ads']);
    expect(ready, isTrue);
  });

  test('an ATT failure does not block app readiness', () async {
    final ads = SasangAds(
      platform: TargetPlatform.iOS,
      requestTrackingAuthorization: () async => throw StateError('unavailable'),
      initializeMobileAds: () async => fail('ads should not initialize'),
    );

    expect(await ads.start(), isFalse);
  });
}

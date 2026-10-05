import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdPlacement { home, places, more }

String? adUnitIdFor({
  required AdPlacement placement,
  required TargetPlatform platform,
  required bool useTestAds,
}) {
  if (useTestAds) {
    return switch (platform) {
      TargetPlatform.android => 'ca-app-pub-3940256099942544/6300978111',
      TargetPlatform.iOS => 'ca-app-pub-3940256099942544/2934735716',
      _ => null,
    };
  }

  return switch ((platform, placement)) {
    (TargetPlatform.android, AdPlacement.home) =>
      'ca-app-pub-6638972080325593/8388425749',
    (TargetPlatform.android, AdPlacement.places) =>
      'ca-app-pub-6638972080325593/1709240829',
    (TargetPlatform.android, AdPlacement.more) =>
      'ca-app-pub-6638972080325593/5864108254',
    (TargetPlatform.iOS, AdPlacement.home) =>
      'ca-app-pub-6638972080325593/6737134392',
    (TargetPlatform.iOS, AdPlacement.places) =>
      'ca-app-pub-6638972080325593/8050216064',
    (TargetPlatform.iOS, AdPlacement.more) =>
      'ca-app-pub-6638972080325593/2115363102',
    _ => null,
  };
}

class AdBanner extends StatefulWidget {
  const AdBanner({required this.placement, super.key});
  final AdPlacement placement;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final adUnitId = adUnitIdFor(
      placement: widget.placement,
      platform: defaultTargetPlatform,
      useTestAds: kDebugMode,
    );
    if (adUnitId == null) return;
    _ad = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) {
      return Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          '광고',
          style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
        ),
      );
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}

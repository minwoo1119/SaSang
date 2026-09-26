import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdPlacement { home, places, more }

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
    final productionId = switch (widget.placement) {
      AdPlacement.home => 'ca-app-pub-6638972080325593/8388425749',
      AdPlacement.places => 'ca-app-pub-6638972080325593/1709240829',
      AdPlacement.more => 'ca-app-pub-6638972080325593/5864108254',
    };
    _ad = BannerAd(
      size: AdSize.banner,
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111'
          : productionId,
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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

typedef AdsStartupStep = Future<void> Function();

class SasangAds {
  SasangAds({
    TargetPlatform? platform,
    AdsStartupStep? requestTrackingAuthorization,
    AdsStartupStep? initializeMobileAds,
  }) : _platform = platform ?? defaultTargetPlatform,
       _requestTrackingAuthorization =
           requestTrackingAuthorization ?? _requestIosTrackingAuthorization,
       _initializeMobileAds = initializeMobileAds ?? _initializeGoogleMobileAds;

  static const _privacyChannel = MethodChannel('com.sasang.app/privacy');

  final TargetPlatform _platform;
  final AdsStartupStep _requestTrackingAuthorization;
  final AdsStartupStep _initializeMobileAds;
  final Completer<bool> _ready = Completer<bool>();
  bool _started = false;

  Future<bool> get ready => _ready.future;

  void startAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(start()));
  }

  Future<bool> start() {
    if (_started) return ready;
    _started = true;
    unawaited(_start());
    return ready;
  }

  Future<void> _start() async {
    var adsReady = false;
    try {
      if (_platform == TargetPlatform.iOS) {
        await _requestTrackingAuthorization();
      }
      await _initializeMobileAds();
      adsReady = true;
    } on Object {
      // Advertising must never block access to locally stored travel records.
    } finally {
      _ready.complete(adsReady);
    }
  }

  static Future<void> _requestIosTrackingAuthorization() async {
    await _privacyChannel.invokeMethod<int>('requestTrackingAuthorization');
  }

  static Future<void> _initializeGoogleMobileAds() async {
    await MobileAds.instance.initialize();
  }
}

final sasangAds = SasangAds();

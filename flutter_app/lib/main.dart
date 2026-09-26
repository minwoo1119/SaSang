import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'core/storage/sasang_storage.dart';
import 'features/state/sasang_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final state = SasangState(SasangStorage());
  await state.load();
  try {
    await MobileAds.instance.initialize();
  } on Object {
    // Ads must never block access to locally stored travel records.
  }
  runApp(SasangApp(state: state));
}

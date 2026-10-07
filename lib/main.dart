import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/ads/sasang_ads.dart';
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
  runApp(SasangApp(state: state));
  sasangAds.startAfterFirstFrame();
}

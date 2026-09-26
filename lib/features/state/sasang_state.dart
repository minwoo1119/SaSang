import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/storage/sasang_storage.dart';
import '../../models/map_models.dart';

class SasangState extends ChangeNotifier {
  SasangState(this.storage);

  final SasangStorage storage;
  bool hasStarted = false;
  String name = '여행자';
  String? profileImageUri;
  MapMode mode = MapMode.korea;
  String? selectedRegionCode;
  final Map<String, RegionPhoto> regionPhotos = {};

  Future<void> load() async {
    final stored = await storage.read();
    hasStarted = stored.hasStarted;
    name = stored.name;
    profileImageUri = stored.profileImageUri;
    regionPhotos
      ..clear()
      ..addAll(stored.regionPhotos);
    notifyListeners();
  }

  void start() {
    hasStarted = true;
    notifyListeners();
    unawaited(storage.writeSession(true));
  }

  void logout() {
    hasStarted = false;
    notifyListeners();
    unawaited(storage.writeSession(false));
  }

  void setMode(MapMode value) {
    mode = value;
    selectedRegionCode = null;
    notifyListeners();
  }

  void selectRegion(String? code) {
    selectedRegionCode = code;
    notifyListeners();
  }

  void setProfile({String? nextName, String? imageUri, bool setImage = false}) {
    if (nextName != null) name = nextName;
    if (setImage) profileImageUri = imageUri;
    notifyListeners();
    unawaited(storage.writeProfile(name, profileImageUri));
  }

  void setRegionPhoto(MapMode photoMode, String code, RegionPhoto photo) {
    regionPhotos[regionPhotoKey(photoMode, code)] = photo;
    notifyListeners();
    unawaited(storage.writePhotos(regionPhotos));
  }

  void removeRegionPhoto(MapMode photoMode, String code) {
    regionPhotos.remove(regionPhotoKey(photoMode, code));
    notifyListeners();
    unawaited(storage.writePhotos(regionPhotos));
  }

  Future<void> clearAllData() async {
    name = '여행자';
    profileImageUri = null;
    mode = MapMode.korea;
    selectedRegionCode = null;
    regionPhotos.clear();
    hasStarted = false;
    notifyListeners();
    await storage.clearState();
    await storage.writeProfile(name, null);
    await storage.writePhotos(regionPhotos);
    await storage.writeSession(false);
  }
}

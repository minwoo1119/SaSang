import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/storage/sasang_storage.dart';
import '../../models/map_models.dart';

class SasangState extends ChangeNotifier {
  SasangState(this.storage);

  final SasangStorage storage;
  Future<void> _photoWrite = Future.value();
  bool hasStarted = false;
  String name = '여행자';
  String? profileImageUri;
  MapMode mode = MapMode.korea;
  String? selectedRegionCode;
  final Map<String, RegionPhoto> regionPhotos = {};
  final Map<String, RegionPhotoAlbum> regionPhotoAlbums = {};

  Future<void> load() async {
    final stored = await storage.read();
    hasStarted = stored.hasStarted;
    name = stored.name;
    profileImageUri = stored.profileImageUri;
    regionPhotos
      ..clear()
      ..addAll(stored.regionPhotos);
    regionPhotoAlbums
      ..clear()
      ..addAll(stored.regionPhotoAlbums);
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
    final key = regionPhotoKey(photoMode, code);
    final current = regionPhotoAlbums[key];
    if (current == null || current.photos.isEmpty) {
      regionPhotoAlbums[key] = RegionPhotoAlbum.fromLegacy(photo);
    } else {
      final coverId = current.coverPhoto?.id;
      regionPhotoAlbums[key] = RegionPhotoAlbum(
        photos: List.unmodifiable([
          for (final existing in current.photos)
            if (existing.id == coverId) photo else existing,
        ]),
        coverPhotoId: photo.id,
      );
    }
    _syncCoverProjection();
    notifyListeners();
    _persistPhotoAlbums();
  }

  void addRegionPhoto(MapMode photoMode, String code, RegionPhoto photo) {
    final key = regionPhotoKey(photoMode, code);
    final current = regionPhotoAlbums[key];
    regionPhotoAlbums[key] = RegionPhotoAlbum(
      photos: List.unmodifiable([...?current?.photos, photo]),
      coverPhotoId: current?.coverPhoto?.id ?? photo.id,
    );
    _syncCoverProjection();
    notifyListeners();
    _persistPhotoAlbums();
  }

  void setRegionCoverPhoto(MapMode photoMode, String code, String photoId) {
    final key = regionPhotoKey(photoMode, code);
    final current = regionPhotoAlbums[key];
    if (current == null ||
        !current.photos.any((photo) => photo.id == photoId)) {
      return;
    }
    regionPhotoAlbums[key] = RegionPhotoAlbum(
      photos: current.photos,
      coverPhotoId: photoId,
    );
    _syncCoverProjection();
    notifyListeners();
    _persistPhotoAlbums();
  }

  void removePhoto(MapMode photoMode, String code, String photoId) {
    final key = regionPhotoKey(photoMode, code);
    final current = regionPhotoAlbums[key];
    if (current == null) return;
    final nextPhotos = current.photos
        .where((photo) => photo.id != photoId)
        .toList(growable: false);
    if (nextPhotos.isEmpty) {
      regionPhotoAlbums.remove(key);
    } else {
      regionPhotoAlbums[key] = RegionPhotoAlbum(
        photos: nextPhotos,
        coverPhotoId: current.coverPhotoId == photoId
            ? nextPhotos.first.id
            : current.coverPhotoId,
      );
    }
    _syncCoverProjection();
    notifyListeners();
    _persistPhotoAlbums();
  }

  void removeRegionPhoto(MapMode photoMode, String code) {
    regionPhotoAlbums.remove(regionPhotoKey(photoMode, code));
    _syncCoverProjection();
    notifyListeners();
    _persistPhotoAlbums();
  }

  RegionPhotoAlbum? regionAlbum(MapMode photoMode, String code) =>
      regionPhotoAlbums[regionPhotoKey(photoMode, code)];

  void _syncCoverProjection() {
    regionPhotos
      ..clear()
      ..addEntries(
        regionPhotoAlbums.entries
            .where((entry) => entry.value.coverPhoto != null)
            .map((entry) => MapEntry(entry.key, entry.value.coverPhoto!)),
      );
  }

  void _persistPhotoAlbums() {
    final snapshot = Map<String, RegionPhotoAlbum>.unmodifiable(
      regionPhotoAlbums,
    );
    _photoWrite = _photoWrite
        .then((_) => storage.writePhotoAlbums(snapshot))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Failed to persist region photo albums: $error');
        });
    unawaited(_photoWrite);
  }

  Future<void> clearAllData() async {
    name = '여행자';
    profileImageUri = null;
    mode = MapMode.korea;
    selectedRegionCode = null;
    regionPhotos.clear();
    regionPhotoAlbums.clear();
    hasStarted = false;
    notifyListeners();
    await _photoWrite;
    await storage.clearState();
    await storage.writeProfile(name, null);
    await storage.writePhotoAlbums(regionPhotoAlbums);
    await storage.writeSession(false);
  }
}

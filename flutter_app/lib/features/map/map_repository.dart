import 'package:flutter/services.dart';

import '../../models/map_models.dart';

class MapRepository {
  final Map<MapMode, RegionMapAsset> _cache = {};

  Future<RegionMapAsset> load(MapMode mode) async {
    final cached = _cache[mode];
    if (cached != null) return cached;
    final path = mode == MapMode.korea
        ? 'assets/maps/korea/regions.json'
        : 'assets/maps/world/countries.json';
    final asset = RegionMapAsset.fromJsonString(
      await rootBundle.loadString(path),
    );
    _cache[mode] = asset;
    return asset;
  }
}

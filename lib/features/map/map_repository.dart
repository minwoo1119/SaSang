import 'package:flutter/services.dart';

import '../../models/map_models.dart';

class MapRepository {
  final Map<MapMode, Future<RegionMapAsset>> _cache = {};

  Future<RegionMapAsset> load(MapMode mode) =>
      _cache.putIfAbsent(mode, () async {
        final path = mode == MapMode.korea
            ? 'assets/maps/korea/regions.json'
            : 'assets/maps/world/countries.json';
        return RegionMapAsset.fromJsonString(await rootBundle.loadString(path));
      });
}

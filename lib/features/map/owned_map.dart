import '../../models/map_models.dart';

enum OwnedMapGroup { defaultMaps, purchasedMaps }

class OwnedMapItem {
  const OwnedMapItem({
    required this.id,
    required this.name,
    required this.description,
    required this.previewMode,
    required this.group,
    this.mode,
    this.countryCode,
  });

  factory OwnedMapItem.fromMode(MapMode mode) => OwnedMapItem(
    id: mode.storageKey,
    name: mode.label,
    description: mode.description,
    previewMode: mode,
    mode: mode,
    group: OwnedMapGroup.defaultMaps,
  );

  final String id;
  final String name;
  final String description;
  final MapMode previewMode;
  final MapMode? mode;
  final String? countryCode;
  final OwnedMapGroup group;
}

/// Builds the maps that the user can select.
///
/// [purchasedMaps] must contain only maps confirmed as owned by the purchase
/// source. Keeping that filtering outside the UI prevents unowned store items
/// from leaking into the user's library.
List<OwnedMapItem> buildOwnedMapLibrary({
  Iterable<OwnedMapItem> purchasedMaps = const [],
}) {
  final maps = <OwnedMapItem>[...MapMode.values.map(OwnedMapItem.fromMode)];
  final ids = maps.map((item) => item.id).toSet();
  for (final item in purchasedMaps) {
    if (ids.add(item.id)) maps.add(item);
  }
  return List.unmodifiable(maps);
}

import { useCallback } from "react";
import { StyleSheet, View } from "react-native";
import Svg from "react-native-svg";
import koreaMapJson from "../../../assets/maps/korea/regions.json";
import worldMapJson from "../../../assets/maps/world/countries.json";
import type {
  MapMode,
  MapRegion,
  RegionMapAsset,
} from "../models/map.types";
import { useMapUiStore } from "../store/mapUi.store";
import { RegionPath } from "./RegionPath";

const MAP_ASSETS: Record<MapMode, RegionMapAsset> = {
  korea: koreaMapJson as RegionMapAsset,
  world: worldMapJson as RegionMapAsset,
};

type InteractiveRegionMapProps = {
  mode: MapMode;
  visitedRegionCodes?: ReadonlySet<string>;
};

export function InteractiveRegionMap({
  mode,
  visitedRegionCodes = new Set(),
}: InteractiveRegionMapProps) {
  const map = MAP_ASSETS[mode];
  const selectedRegionCode = useMapUiStore((state) => state.selectedRegionCode);
  const selectRegion = useMapUiStore((state) => state.selectRegion);
  const handlePress = useCallback(
    (region: MapRegion) => selectRegion(region.code),
    [selectRegion],
  );

  return (
    <View style={styles.container}>
      <Svg
        accessibilityLabel={
          mode === "korea" ? "대한민국 시군구 지도" : "세계 국가 지도"
        }
        height="100%"
        preserveAspectRatio="xMidYMid meet"
        viewBox={`0 0 ${map.viewBox.width} ${map.viewBox.height}`}
        width="100%"
      >
        {map.regions.map((region) => (
          <RegionPath
            key={region.code}
            onPress={handlePress}
            region={region}
            selected={selectedRegionCode === region.code}
            visited={visitedRegionCodes.has(region.code)}
          />
        ))}
      </Svg>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { height: "100%", width: "100%" },
});

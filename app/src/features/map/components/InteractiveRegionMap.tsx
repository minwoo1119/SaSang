import { useCallback } from "react";
import { StyleSheet, View } from "react-native";
import Svg from "react-native-svg";
import seoulMapJson from "../../../assets/maps/korea/seoul.json";
import type { MapRegion, RegionMapAsset } from "../models/map.types";
import { useMapUiStore } from "../store/mapUi.store";
import { RegionPath } from "./RegionPath";

const seoulMap = seoulMapJson as RegionMapAsset;

type InteractiveRegionMapProps = { visitedRegionCodes?: ReadonlySet<string> };

export function InteractiveRegionMap({
  visitedRegionCodes = new Set(),
}: InteractiveRegionMapProps) {
  const selectedRegionCode = useMapUiStore((state) => state.selectedRegionCode);
  const selectRegion = useMapUiStore((state) => state.selectRegion);
  const handlePress = useCallback(
    (region: MapRegion) => selectRegion(region.code),
    [selectRegion],
  );

  return (
    <View style={styles.container}>
      <Svg
        accessibilityLabel="서울 25개 구 지도"
        height="100%"
        preserveAspectRatio="xMidYMid meet"
        viewBox={`0 0 ${seoulMap.viewBox.width} ${seoulMap.viewBox.height}`}
        width="100%"
      >
        {seoulMap.regions.map((region) => (
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
  container: { aspectRatio: 1.2, width: "100%" },
});

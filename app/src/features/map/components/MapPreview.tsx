import { StyleSheet, View } from "react-native";
import Svg, { Path } from "react-native-svg";
import { MAP_ASSETS } from "../models/mapAssets";
import type { MapMode } from "../models/map.types";

type Props = {
  countryCode?: string;
  mode?: MapMode;
  selected?: boolean;
};

export function MapPreview({ countryCode, mode = "world", selected }: Props) {
  const map = MAP_ASSETS[mode];
  const country = countryCode
    ? MAP_ASSETS.world.regions.find((region) => region.code === countryCode)
    : undefined;
  const regions = country ? [country] : map.regions;
  const padding = country
    ? Math.max(country.bounds.width, country.bounds.height) * 0.12
    : 0;
  const viewBox = country
    ? `${country.bounds.x - padding} ${country.bounds.y - padding} ${country.bounds.width + padding * 2} ${country.bounds.height + padding * 2}`
    : `0 0 ${map.viewBox.width} ${map.viewBox.height}`;

  return (
    <View style={[styles.container, selected && styles.selectedContainer]}>
      <Svg height="100%" preserveAspectRatio="xMidYMid meet" viewBox={viewBox} width="100%">
        {regions.map((region) => (
          <Path
            d={region.path}
            fill={selected ? "#B9DAFF" : "#DCE5ED"}
            key={region.code}
            stroke={selected ? "#007AFF" : "#81909D"}
            strokeWidth={mode === "korea" && !country ? 0.45 : 0.7}
          />
        ))}
      </Svg>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    backgroundColor: "#F4F7F9",
    height: 82,
    justifyContent: "center",
    padding: 9,
    width: "100%",
  },
  selectedContainer: {
    backgroundColor: "#EFF7FF",
  },
});

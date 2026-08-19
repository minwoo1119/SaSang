import { memo } from "react";
import { Path } from "react-native-svg";
import type { MapRegion } from "../models/map.types";

type RegionPathProps = {
  region: MapRegion;
  selected: boolean;
  visited: boolean;
  onPress: (region: MapRegion) => void;
};

export const RegionPath = memo(function RegionPath({
  region,
  selected,
  visited,
  onPress,
}: RegionPathProps) {
  return (
    <Path
      accessibilityLabel={`${region.name}, ${region.code}${visited ? ", 방문함" : ""}`}
      d={region.path}
      fill={selected ? "#171717" : visited ? "#A3A3A3" : "#F5F5F5"}
      onPress={() => onPress(region)}
      stroke={selected ? "#171717" : "#D4D4D4"}
      strokeLinejoin="round"
      strokeWidth={selected ? 1.8 : 0.8}
    />
  );
});

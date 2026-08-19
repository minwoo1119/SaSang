import { memo } from "react";
import { Path } from "react-native-svg";
import type { MapRegion } from "../models/map.types";

type RegionPathProps = {
  region: MapRegion;
  photoFilled: boolean;
  selected: boolean;
  visited: boolean;
  onPress: (region: MapRegion) => void;
};

export const RegionPath = memo(function RegionPath({
  region,
  photoFilled,
  selected,
  visited,
  onPress,
}: RegionPathProps) {
  return (
    <Path
      accessibilityLabel={`${region.name}, ${region.code}${visited ? ", 사진 있음" : ""}`}
      d={region.path}
      fill={photoFilled ? "transparent" : selected ? "#272521" : visited ? "#BBB7AE" : "#EEECE6"}
      onPress={() => onPress(region)}
      stroke={selected ? "#E05A3F" : photoFilled ? "#FFFFFF" : "#C9C5BC"}
      strokeLinejoin="round"
      strokeWidth={selected ? 2.2 : photoFilled ? 1.2 : 0.72}
    />
  );
});

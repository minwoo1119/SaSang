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
      fill={
        photoFilled
          ? "transparent"
          : selected
            ? "#F4F4F5"
            : visited
              ? "#F8FAFC"
              : "#FFFFFF"
      }
      onPress={() => onPress(region)}
      stroke={photoFilled ? "#71717A" : "#D4D4D8"}
      strokeLinejoin="round"
      strokeWidth={photoFilled ? 0.7 : 0.52}
      vectorEffect="non-scaling-stroke"
    />
  );
});

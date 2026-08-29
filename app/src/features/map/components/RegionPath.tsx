import { memo } from "react";
import { Path } from "react-native-svg";
import type { MapMode, MapRegion } from "../models/map.types";

type RegionPathProps = {
  mode: MapMode;
  onPress: (region: MapRegion) => void;
  photoFilled: boolean;
  region: MapRegion;
  selected: boolean;
  visited: boolean;
};

export const RegionPath = memo(function RegionPath({
  mode,
  onPress,
  photoFilled,
  region,
  selected,
  visited,
}: RegionPathProps) {
  const isWorld = mode === "world";

  const strokeColor = photoFilled
    ? isWorld
      ? "#8E8E93"
      : "#71717A"
    : isWorld
      ? "rgba(24, 24, 27, 0.14)"
      : "rgba(24, 24, 27, 0.18)";

  const strokeWidth = photoFilled
    ? isWorld
      ? 0.16
      : 0.55
    : isWorld
      ? 0.11
      : 0.45;

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
      stroke={strokeColor}
      strokeLinejoin="round"
      strokeWidth={strokeWidth}
      vectorEffect="non-scaling-stroke"
    />
  );
});

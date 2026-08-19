import { memo, type ComponentProps, type ComponentType } from "react";
import { Path } from "react-native-svg";
import type { MapRegion } from "../models/map.types";

type WebPathProps = ComponentProps<typeof Path> & { onClick: () => void };
const WebPath = Path as unknown as ComponentType<WebPathProps>;

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
    <WebPath
      accessibilityLabel={`${region.name}, ${region.code}${visited ? ", 사진 있음" : ""}`}
      d={region.path}
      fill={photoFilled ? "transparent" : selected ? "#E8EEF8" : visited ? "#E1E8E3" : "#FAFAF8"}
      onClick={() => onPress(region)}
      stroke={selected ? "#3268C8" : photoFilled ? "#6F746F" : "#9A9D98"}
      strokeLinejoin="round"
      strokeWidth={selected ? 1.15 : photoFilled ? 0.7 : 0.52}
      vectorEffect="non-scaling-stroke"
    />
  );
});

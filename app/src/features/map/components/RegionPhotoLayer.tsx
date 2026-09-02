import { memo } from "react";
import type { ComponentProps } from "react";
import Animated from "react-native-reanimated";
import { ClipPath, Defs, Image as SvgImage, Path } from "react-native-svg";
import type {
  MapMode,
  MapRegion,
  RegionPhoto,
} from "../models/map.types";
import { getRegionPhotoKey } from "../store/mapUi.store";

const AnimatedPath = Animated.createAnimatedComponent(Path);
const AnimatedSvgImage = Animated.createAnimatedComponent(SvgImage);
type AnimatedPathProps = ComponentProps<typeof AnimatedPath>["animatedProps"];
type AnimatedSvgImageProps = ComponentProps<
  typeof AnimatedSvgImage
>["animatedProps"];

type RegionPhotoLayerProps = {
  animatedProps?: AnimatedPathProps;
  mode: MapMode;
  regionPhotos: Readonly<Record<string, RegionPhoto>>;
  regions: readonly MapRegion[];
};

export const RegionPhotoLayer = memo(function RegionPhotoLayer({
  animatedProps,
  mode,
  regionPhotos,
  regions,
}: RegionPhotoLayerProps) {
  const photoRegions = regions.flatMap((region) => {
    const photo = regionPhotos[getRegionPhotoKey(mode, region.code)];
    return photo ? [{ photo, region }] : [];
  });

  if (photoRegions.length === 0) return null;

  const imageAnimatedProps = animatedProps as unknown as AnimatedSvgImageProps;

  return (
    <>
      <Defs>
        {photoRegions.map(({ region }) => (
          <ClipPath id={`photo-${mode}-${region.code}`} key={region.code}>
            <AnimatedPath animatedProps={animatedProps} d={region.path} />
          </ClipPath>
        ))}
      </Defs>
      {photoRegions.map(({ photo, region }) => (
        <AnimatedSvgImage
          animatedProps={imageAnimatedProps}
          clipPath={`url(#photo-${mode}-${region.code})`}
          height={region.bounds.height}
          href={{ uri: photo.uri }}
          key={region.code}
          preserveAspectRatio="xMidYMid slice"
          width={region.bounds.width}
          x={region.bounds.x}
          y={region.bounds.y}
        />
      ))}
    </>
  );
});

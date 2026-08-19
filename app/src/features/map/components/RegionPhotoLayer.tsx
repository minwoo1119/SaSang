import { memo } from "react";
import { ClipPath, Defs, Image as SvgImage, Path } from "react-native-svg";
import type {
  MapMode,
  MapRegion,
  RegionPhoto,
} from "../models/map.types";
import { getRegionPhotoKey } from "../store/mapUi.store";

type RegionPhotoLayerProps = {
  mode: MapMode;
  regionPhotos: Readonly<Record<string, RegionPhoto>>;
  regions: readonly MapRegion[];
};

export const RegionPhotoLayer = memo(function RegionPhotoLayer({
  mode,
  regionPhotos,
  regions,
}: RegionPhotoLayerProps) {
  const photoRegions = regions.flatMap((region) => {
    const photo = regionPhotos[getRegionPhotoKey(mode, region.code)];
    return photo ? [{ photo, region }] : [];
  });

  if (photoRegions.length === 0) return null;

  return (
    <>
      <Defs>
        {photoRegions.map(({ region }) => (
          <ClipPath id={`photo-${mode}-${region.code}`} key={region.code}>
            <Path d={region.path} />
          </ClipPath>
        ))}
      </Defs>
      {photoRegions.map(({ photo, region }) => (
        <SvgImage
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

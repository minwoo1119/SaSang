import koreaMapJson from "../../../assets/maps/korea/regions.json";
import worldMapJson from "../../../assets/maps/world/countries.json";
import type { MapMode, RegionMapAsset } from "./map.types";

export const MAP_ASSETS: Record<MapMode, RegionMapAsset> = {
  korea: koreaMapJson as RegionMapAsset,
  world: worldMapJson as RegionMapAsset,
};

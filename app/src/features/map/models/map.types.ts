export type MapMode = "korea" | "world";
export type RegionCode = string;
export type MapRegion = { code: RegionCode; name: string; path: string };

export type RegionMapAsset = {
  metadata: {
    version: string;
    generatedAt: string;
    source: string;
    license: string;
  };
  viewBox: { width: number; height: number; padding: number };
  regions: MapRegion[];
};

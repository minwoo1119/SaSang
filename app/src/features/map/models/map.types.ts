export type MapMode = "korea" | "world";
export type RegionCode = string;
export type MapRegion = {
  code: RegionCode;
  name: string;
  provinceCode?: string;
  provinceName?: string;
  geometryType: "Polygon" | "MultiPolygon";
  polygonCount: number;
  path: string;
};

export type RegionMapAsset = {
  metadata: {
    version: string;
    generatedAt: string;
    source: string;
    license: string;
    referenceDate: string;
    identifierPolicy: string;
    excludedFeatures: string[];
  };
  viewBox: { width: number; height: number; padding: number };
  regions: MapRegion[];
};

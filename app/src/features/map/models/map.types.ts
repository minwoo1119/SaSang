export type MapMode = "korea" | "world";
export type RegionCode = string;
export type RegionBounds = {
  x: number;
  y: number;
  width: number;
  height: number;
};

export type MapRegion = {
  code: RegionCode;
  name: string;
  englishName?: string;
  provinceCode?: string;
  provinceName?: string;
  geometryType: "Polygon" | "MultiPolygon";
  polygonCount: number;
  bounds: RegionBounds;
  path: string;
};

export type RegionPhoto = {
  id: string;
  uri: string;
  width: number;
  height: number;
  scale: number;
  offsetX: number;
  offsetY: number;
  createdAt: string;
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

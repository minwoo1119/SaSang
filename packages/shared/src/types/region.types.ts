export const REGION_TYPES = ["KOREA_SIGUNGU", "WORLD_COUNTRY"] as const;
export type RegionType = (typeof REGION_TYPES)[number];
export type Region = {
  code: string;
  name: string;
  type: RegionType;
  mapVersion: string;
};
export type MapMetadata = {
  version: string;
  generatedAt: string;
  source: string;
};

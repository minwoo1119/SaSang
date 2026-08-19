import { create } from "zustand";
import type {
  MapMode,
  RegionCode,
  RegionPhoto,
} from "../models/map.types";

export const getRegionPhotoKey = (mode: MapMode, code: RegionCode) =>
  `${mode}:${code}`;

type MapUiState = {
  mode: MapMode;
  regionPhotos: Record<string, RegionPhoto>;
  selectedRegionCode: RegionCode | null;
  removeRegionPhoto: (mode: MapMode, code: RegionCode) => void;
  selectRegion: (code: RegionCode | null) => void;
  setRegionPhoto: (
    mode: MapMode,
    code: RegionCode,
    photo: RegionPhoto,
  ) => void;
  setMode: (mode: MapMode) => void;
};
export const useMapUiStore = create<MapUiState>((set) => ({
  mode: "korea",
  regionPhotos: {},
  selectedRegionCode: null,
  removeRegionPhoto: (mode, code) =>
    set((state) => {
      const regionPhotos = { ...state.regionPhotos };
      delete regionPhotos[getRegionPhotoKey(mode, code)];
      return { regionPhotos };
    }),
  selectRegion: (selectedRegionCode) => set({ selectedRegionCode }),
  setRegionPhoto: (mode, code, photo) =>
    set((state) => ({
      regionPhotos: {
        ...state.regionPhotos,
        [getRegionPhotoKey(mode, code)]: photo,
      },
    })),
  setMode: (mode) => set({ mode, selectedRegionCode: null }),
}));

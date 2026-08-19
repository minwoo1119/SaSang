import { create } from "zustand";
import type { MapMode, RegionCode } from "../models/map.types";

type MapUiState = {
  mode: MapMode;
  selectedRegionCode: RegionCode | null;
  selectRegion: (code: RegionCode | null) => void;
  setMode: (mode: MapMode) => void;
};
export const useMapUiStore = create<MapUiState>((set) => ({
  mode: "korea",
  selectedRegionCode: null,
  selectRegion: (selectedRegionCode) => set({ selectedRegionCode }),
  setMode: (mode) => set({ mode, selectedRegionCode: null }),
}));

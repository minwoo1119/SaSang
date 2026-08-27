import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";
import { appStorage } from "@/services/storage/appStorage";

type LocalSessionState = {
  hasStarted: boolean;
  reset: () => void;
  start: () => void;
};

export const useLocalSessionStore = create<LocalSessionState>()(
  persist(
    (set) => ({
      hasStarted: false,
      reset: () => set({ hasStarted: false }),
      start: () => set({ hasStarted: true }),
    }),
    {
      name: "sasang-local-session",
      storage: createJSONStorage(() => appStorage),
    },
  ),
);

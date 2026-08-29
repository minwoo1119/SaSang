import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";
import { appStorage } from "@/services/storage/appStorage";

type ProfileState = {
  name: string;
  profileImageUri: string | null;
  resetProfile: () => void;
  setName: (name: string) => void;
  setProfileImageUri: (uri: string | null) => void;
};

export const useProfileStore = create<ProfileState>()(
  persist(
    (set) => ({
      name: "여행자",
      profileImageUri: null,
      resetProfile: () => set({ name: "여행자", profileImageUri: null }),
      setName: (name) => set({ name }),
      setProfileImageUri: (profileImageUri) => set({ profileImageUri }),
    }),
    {
      name: "sasang-profile",
      storage: createJSONStorage(() => appStorage),
    },
  ),
);

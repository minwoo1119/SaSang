import Constants from "expo-constants";

type MobileAdsModule = {
  default?: () => {
    initialize: () => Promise<unknown>;
  };
};

declare const require: (moduleName: string) => unknown;

let initializePromise: Promise<unknown> | null = null;

export function initializeMobileAds() {
  if (Constants.appOwnership === "expo") {
    return Promise.resolve();
  }

  if (!initializePromise) {
    try {
      const module = require("react-native-google-mobile-ads") as
        | MobileAdsModule
        | (() => { initialize: () => Promise<unknown> });
      const factory = typeof module === "function" ? module : module.default;
      initializePromise = factory ? factory().initialize() : Promise.resolve();
    } catch {
      initializePromise = Promise.resolve();
    }
  }

  return initializePromise;
}

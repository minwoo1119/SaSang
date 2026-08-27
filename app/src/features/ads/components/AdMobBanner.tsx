import Constants from "expo-constants";
import type { ComponentType, ReactNode } from "react";
import { StyleSheet, View } from "react-native";

type AdMobBannerProps = {
  fallback: ReactNode;
  size: "ANCHORED_ADAPTIVE_BANNER" | "BANNER" | "INLINE_ADAPTIVE_BANNER";
  unitId: string;
};

type GoogleMobileAdsModule = {
  BannerAd: ComponentType<{
    requestOptions?: { requestNonPersonalizedAdsOnly?: boolean };
    size: string;
    unitId: string;
  }>;
  BannerAdSize: Record<AdMobBannerProps["size"], string>;
  TestIds: {
    ADAPTIVE_BANNER: string;
    BANNER: string;
  };
};

declare const require: (moduleName: string) => unknown;

function loadGoogleMobileAds() {
  if (Constants.appOwnership === "expo") return null;

  try {
    return require("react-native-google-mobile-ads") as GoogleMobileAdsModule;
  } catch {
    return null;
  }
}

export function AdMobBanner({ fallback, size, unitId }: AdMobBannerProps) {
  const googleMobileAds = loadGoogleMobileAds();

  if (!googleMobileAds) {
    return <>{fallback}</>;
  }

  const { BannerAd, BannerAdSize, TestIds } = googleMobileAds;
  const resolvedUnitId = __DEV__ ? TestIds.ADAPTIVE_BANNER : unitId;

  return (
    <View style={styles.container}>
      <BannerAd
        requestOptions={{ requestNonPersonalizedAdsOnly: true }}
        size={BannerAdSize[size]}
        unitId={resolvedUnitId}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    justifyContent: "center",
    overflow: "hidden",
    width: "100%",
  },
});

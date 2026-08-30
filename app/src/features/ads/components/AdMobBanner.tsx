import Constants from "expo-constants";
import type { ComponentType, ReactNode } from "react";
import { useState } from "react";
import type { StyleProp, ViewStyle } from "react-native";
import { StyleSheet, View } from "react-native";

type AdMobBannerProps = {
  fallback: ReactNode;
  size: "ANCHORED_ADAPTIVE_BANNER" | "BANNER" | "INLINE_ADAPTIVE_BANNER";
  style?: StyleProp<ViewStyle>;
  unitId: string;
};

type GoogleMobileAdsModule = {
  BannerAd: ComponentType<{
    onAdFailedToLoad?: (error: unknown) => void;
    onAdLoaded?: () => void;
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

export function AdMobBanner({ fallback, size, style, unitId }: AdMobBannerProps) {
  const [adFailed, setAdFailed] = useState(false);
  const googleMobileAds = loadGoogleMobileAds();

  if (!googleMobileAds || adFailed) {
    return <>{fallback}</>;
  }

  const { BannerAd, BannerAdSize, TestIds } = googleMobileAds;
  const testBannerId =
    TestIds?.BANNER ||
    (TestIds as Record<string, string> | undefined)?.ADAPTIVE_BANNER ||
    "ca-app-pub-3940256099942544/6300978111";

  const resolvedUnitId = __DEV__ ? testBannerId : unitId || testBannerId;
  const resolvedSize =
    BannerAdSize && BannerAdSize[size] ? BannerAdSize[size] : "BANNER";

  if (!resolvedUnitId) {
    return <>{fallback}</>;
  }

  return (
    <View style={[styles.container, style]}>
      <BannerAd
        onAdFailedToLoad={(error) => {
          if (__DEV__) {
            console.warn("[AdMob] Banner failed to load:", error);
          }
          setAdFailed(true);
        }}
        requestOptions={{ requestNonPersonalizedAdsOnly: true }}
        size={resolvedSize}
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


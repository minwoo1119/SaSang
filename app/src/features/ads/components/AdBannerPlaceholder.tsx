import type { StyleProp, ViewStyle } from "react-native";
import { StyleSheet, View } from "react-native";
import { ADMOB_AD_UNIT_IDS } from "../models/adMobUnits";
import { AdMobBanner } from "./AdMobBanner";

type AdBannerPlaceholderProps = {
  style?: StyleProp<ViewStyle>;
};

export function AdBannerPlaceholder({ style }: AdBannerPlaceholderProps) {
  return (
    <AdMobBanner
      fallback={<View style={[styles.container, style]} />}
      size="ANCHORED_ADAPTIVE_BANNER"
      style={[styles.container, style]}
      unitId={ADMOB_AD_UNIT_IDS.moreBanner}
    />
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderRadius: 18,
    justifyContent: "center",
    minHeight: 76,
    overflow: "hidden",
    paddingHorizontal: 20,
    paddingVertical: 18,
  },
});

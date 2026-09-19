import type { StyleProp, ViewStyle } from "react-native";
import { StyleSheet, View } from "react-native";
import { ADMOB_AD_UNIT_IDS } from "../models/adMobUnits";
import { AdMobBanner } from "./AdMobBanner";

type AdNativeCardPlaceholderProps = {
  style?: StyleProp<ViewStyle>;
};

export function AdNativeCardPlaceholder({ style }: AdNativeCardPlaceholderProps = {}) {
  return (
    <AdMobBanner
      fallback={
        <View style={[styles.container, style]} />
      }
      size="INLINE_ADAPTIVE_BANNER"
      style={[styles.container, style]}
      unitId={ADMOB_AD_UNIT_IDS.places}
    />
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderRadius: 18,
    minHeight: 88,
    overflow: "hidden",
    paddingHorizontal: 20,
    paddingVertical: 18,
  },
});

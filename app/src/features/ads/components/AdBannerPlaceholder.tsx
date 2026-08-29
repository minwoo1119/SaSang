import type { StyleProp, ViewStyle } from "react-native";
import { StyleSheet, Text, View } from "react-native";
import { ADMOB_AD_UNIT_IDS } from "../models/adMobUnits";
import { AdMobBanner } from "./AdMobBanner";

type AdBannerPlaceholderProps = {
  label?: string;
  style?: StyleProp<ViewStyle>;
};

export function AdBannerPlaceholder({
  label = "AdMob Banner",
  style,
}: AdBannerPlaceholderProps) {
  return (
    <AdMobBanner
      fallback={
        <View accessibilityLabel={label} style={[styles.container, style]}>
          <View style={styles.mark} />
          <Text style={styles.label}>{label}</Text>
        </View>
      }
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
    borderColor: "rgba(0, 0, 0, 0.07)",
    borderRadius: 18,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 10,
    justifyContent: "center",
    minHeight: 76,
    overflow: "hidden",
    paddingHorizontal: 20,
    paddingVertical: 18,
  },
  label: {
    color: "#71717A",
    fontSize: 14,
    fontWeight: "700",
  },
  mark: {
    backgroundColor: "rgba(0, 122, 255, 0.14)",
    borderRadius: 5,
    height: 10,
    width: 10,
  },
});

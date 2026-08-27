import { StyleSheet, Text, View } from "react-native";
import { ADMOB_AD_UNIT_IDS } from "../models/adMobUnits";
import { AdMobBanner } from "./AdMobBanner";

export function AdNativeCardPlaceholder() {
  return (
    <View style={styles.wrapper}>
      <AdMobBanner
        fallback={
          <View accessibilityLabel="AdMob Native" style={styles.container}>
            <View style={styles.thumbnail}>
              <View style={styles.pin} />
            </View>
            <View style={styles.body}>
              <View style={styles.labelRow}>
                <Text style={styles.title}>여행에 어울리는 추천</Text>
                <Text style={styles.badge}>AD</Text>
              </View>
              <Text numberOfLines={1} style={styles.description}>
                Sasang이 고른 여행 정보
              </Text>
            </View>
          </View>
        }
        size="INLINE_ADAPTIVE_BANNER"
        unitId={ADMOB_AD_UNIT_IDS.places}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    color: "#A1A1AA",
    fontSize: 10,
    fontWeight: "900",
  },
  body: {
    flex: 1,
    gap: 3,
    minWidth: 0,
  },
  container: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.07)",
    borderRadius: 16,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 12,
    minHeight: 74,
    padding: 12,
  },
  description: {
    color: "#71717A",
    fontSize: 12,
    fontWeight: "600",
  },
  labelRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 6,
  },
  title: {
    color: "#18181B",
    flex: 1,
    fontSize: 14,
    fontWeight: "800",
  },
  pin: {
    backgroundColor: "#007AFF",
    borderRadius: 10,
    height: 20,
    opacity: 0.14,
    width: 20,
  },
  thumbnail: {
    alignItems: "center",
    backgroundColor: "#F8FBFF",
    borderRadius: 13,
    height: 50,
    justifyContent: "center",
    width: 50,
  },
  wrapper: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.07)",
    borderRadius: 16,
    borderWidth: StyleSheet.hairlineWidth,
    overflow: "hidden",
  },
});

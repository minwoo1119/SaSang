import { StyleSheet, Text, View } from "react-native";

export function AdNativeCardPlaceholder() {
  return (
    <View accessibilityLabel="AdMob Native" style={styles.container}>
      <View style={styles.media}>
        <View style={styles.pin} />
      </View>
      <View style={styles.body}>
        <View style={styles.labelRow}>
          <Text style={styles.badge}>AD</Text>
          <Text style={styles.label}>추천 스팟</Text>
        </View>
        <Text numberOfLines={1} style={styles.title}>
          여행 기록 사이에 자연스럽게 노출될 광고 영역
        </Text>
        <Text numberOfLines={2} style={styles.description}>
          추후 AdMob Native Ad 또는 Medium Rectangle 광고로 교체할 자리입니다.
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    backgroundColor: "rgba(0, 122, 255, 0.1)",
    borderRadius: 7,
    color: "#007AFF",
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 6,
    paddingVertical: 3,
  },
  body: {
    gap: 7,
    padding: 14,
  },
  container: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(24, 24, 27, 0.1)",
    borderRadius: 8,
    borderWidth: 1,
    overflow: "hidden",
  },
  description: {
    color: "#71717A",
    fontSize: 13,
    fontWeight: "600",
    lineHeight: 19,
  },
  label: {
    color: "#71717A",
    fontSize: 12,
    fontWeight: "700",
  },
  labelRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  media: {
    alignItems: "center",
    aspectRatio: 1.9,
    backgroundColor: "#F8FBFF",
    justifyContent: "center",
  },
  pin: {
    backgroundColor: "#007AFF",
    borderRadius: 19,
    height: 38,
    opacity: 0.14,
    width: 38,
  },
  title: {
    color: "#18181B",
    fontSize: 16,
    fontWeight: "800",
  },
});

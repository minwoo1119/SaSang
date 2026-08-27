import { StyleSheet, Text, View } from "react-native";

type AdBannerPlaceholderProps = {
  label?: string;
};

export function AdBannerPlaceholder({
  label = "AdMob Banner",
}: AdBannerPlaceholderProps) {
  return (
    <View accessibilityLabel={label} style={styles.container}>
      <View style={styles.mark} />
      <Text style={styles.label}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.07)",
    borderRadius: 16,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 9,
    height: 62,
    justifyContent: "center",
    overflow: "hidden",
    paddingHorizontal: 14,
  },
  label: {
    color: "#71717A",
    fontSize: 13,
    fontWeight: "700",
  },
  mark: {
    backgroundColor: "rgba(0, 122, 255, 0.14)",
    borderRadius: 5,
    height: 10,
    width: 10,
  },
});

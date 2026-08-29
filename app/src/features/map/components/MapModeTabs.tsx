import { Pressable, StyleSheet, Text, View } from "react-native";
import type { MapMode } from "../models/map.types";

type Props = { value: MapMode; onChange: (mode: MapMode) => void };
const OPTIONS: readonly { label: string; value: MapMode }[] = [
  { label: "국내", value: "korea" },
  { label: "해외", value: "world" },
];

export function MapModeTabs({ value, onChange }: Props) {
  return (
    <View style={styles.container}>
      {OPTIONS.map((option) => {
        const selected = option.value === value;
        return (
          <Pressable
            accessibilityRole="tab"
            accessibilityState={{ selected }}
            key={option.value}
            onPress={() => onChange(option.value)}
            style={({ pressed }) => [
              styles.tab,
              selected && styles.selectedTab,
              pressed && styles.pressed,
            ]}
          >
            <Text style={[styles.label, selected && styles.selectedLabel]}>
              {option.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 22,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 4,
    padding: 4,
  },
  label: { color: "#3F3F46", fontSize: 14, fontWeight: "700" },
  pressed: { opacity: 0.78 },
  selectedLabel: { color: "#007AFF", fontWeight: "800" },
  selectedTab: {
    backgroundColor: "rgba(0, 122, 255, 0.12)",
  },
  tab: {
    alignItems: "center",
    borderRadius: 18,
    height: 36,
    justifyContent: "center",
    minWidth: 58,
    paddingHorizontal: 14,
  },
});

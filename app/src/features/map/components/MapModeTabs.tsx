import { Pressable, StyleSheet, Text, View } from "react-native";
import type { MapMode } from "../models/map.types";

type Props = { value: MapMode; onChange: (mode: MapMode) => void };
const OPTIONS: readonly { label: string; value: MapMode }[] = [
  { label: "대한민국", value: "korea" },
  { label: "세계", value: "world" },
];

export function MapModeTabs({ value, onChange }: Props) {
  return (
    <View accessibilityRole="tablist" style={styles.container}>
      {OPTIONS.map((option) => {
        const selected = option.value === value;
        return (
          <Pressable
            accessibilityRole="tab"
            accessibilityState={{ selected }}
            key={option.value}
            onPress={() => onChange(option.value)}
            style={[styles.tab, selected && styles.selectedTab]}
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
    alignSelf: "center",
    backgroundColor: "#F5F5F5",
    borderRadius: 12,
    flexDirection: "row",
    padding: 4,
  },
  tab: { borderRadius: 9, paddingHorizontal: 24, paddingVertical: 9 },
  selectedTab: { backgroundColor: "#FFFFFF" },
  label: { color: "#737373", fontSize: 14, fontWeight: "500" },
  selectedLabel: { color: "#171717", fontWeight: "700" },
});

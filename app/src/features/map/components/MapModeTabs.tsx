import { Pressable, StyleSheet, Text } from "react-native";
import type { MapMode } from "../models/map.types";
import { MapGlassSurface } from "./MapGlassSurface";

type Props = { value: MapMode; onChange: (mode: MapMode) => void };
const OPTIONS: readonly { label: string; value: MapMode }[] = [
  { label: "대한민국", value: "korea" },
  { label: "세계", value: "world" },
];

export function MapModeTabs({ value, onChange }: Props) {
  return (
    <MapGlassSurface style={styles.container}>
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
    </MapGlassSurface>
  );
}

const styles = StyleSheet.create({
  container: {
    alignSelf: "center",
    borderRadius: 24,
    flexDirection: "row",
    padding: 4,
    overflow: "hidden",
  },
  label: { color: "#71717A", fontSize: 13, fontWeight: "600" },
  pressed: { opacity: 0.72 },
  selectedLabel: { color: "#FFFFFF", fontWeight: "700" },
  selectedTab: { backgroundColor: "#007AFF" },
  tab: {
    alignItems: "center",
    borderRadius: 20,
    minWidth: 82,
    paddingHorizontal: 16,
    paddingVertical: 9,
  },
});

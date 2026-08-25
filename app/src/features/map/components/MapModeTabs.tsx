import { Pressable, StyleSheet, Text } from "react-native";
import type { MapMode } from "../models/map.types";
import { MapGlassSurface } from "./MapGlassSurface";

type Props = { value: MapMode; onChange: (mode: MapMode) => void };
const OPTIONS: readonly { label: string; value: MapMode }[] = [
  { label: "국내", value: "korea" },
  { label: "해외", value: "world" },
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
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 24,
    flexDirection: "row",
    overflow: "hidden",
    padding: 4,
  },
  label: { color: "#3F3F46", fontSize: 14, fontWeight: "700" },
  pressed: { opacity: 0.72 },
  selectedTab: {
    backgroundColor: "rgba(0, 122, 255, 0.12)",
    shadowColor: "#007AFF",
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
  },
  selectedLabel: { color: "#007AFF", fontWeight: "800" },
  tab: {
    alignItems: "center",
    borderRadius: 20,
    minWidth: 68,
    paddingHorizontal: 18,
    paddingVertical: 10,
  },
});

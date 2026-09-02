import { GlassView } from "expo-glass-effect";
import type { PropsWithChildren } from "react";
import type { StyleProp, ViewStyle } from "react-native";
import { StyleSheet } from "react-native";

type MapGlassSurfaceProps = PropsWithChildren<{
  style?: StyleProp<ViewStyle>;
}>;

export function MapGlassSurface({ children, style }: MapGlassSurfaceProps) {
  return (
    <GlassView
      glassEffectStyle="regular"
      style={[styles.surface, style]}
      tintColor="#FFFFFF8C"
    >
      {children}
    </GlassView>
  );
}

const styles = StyleSheet.create({
  surface: {
    backgroundColor: "rgba(255, 255, 255, 0.48)",
    borderColor: "rgba(255, 255, 255, 0.82)",
    borderWidth: StyleSheet.hairlineWidth,
    overflow: "hidden",
    shadowColor: "#111827",
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.08,
    shadowRadius: 16,
  },
});

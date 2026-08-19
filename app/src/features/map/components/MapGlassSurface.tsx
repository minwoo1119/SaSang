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
      tintColor="#FDFCF8CC"
    >
      {children}
    </GlassView>
  );
}

const styles = StyleSheet.create({
  surface: {
    backgroundColor: "rgba(253, 252, 248, 0.88)",
    borderColor: "rgba(255, 255, 255, 0.72)",
    borderWidth: StyleSheet.hairlineWidth,
    shadowColor: "#1D1C19",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.1,
    shadowRadius: 24,
  },
});

import { useState } from "react";
import { Pressable, SafeAreaView, StyleSheet, Text, View } from "react-native";
import { MapModeTabs } from "@/features/map/components/MapModeTabs";
import type { MapMode } from "@/features/map/models/map.types";

export function MapScreen() {
  const [mode, setMode] = useState<MapMode>("korea");
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.brand}>사상</Text>
        <Text style={styles.subtitle}>나의 여행을 지도에 남기다</Text>
      </View>
      <MapModeTabs value={mode} onChange={setMode} />
      <View style={styles.mapPlaceholder}>
        <Text style={styles.mapTitle}>
          {mode === "korea" ? "대한민국" : "세계"}
        </Text>
        <Text style={styles.mapHint}>
          여행 사진으로 채울 지도가 이곳에 표시됩니다.
        </Text>
      </View>
      <Pressable accessibilityRole="button" style={styles.primaryButton}>
        <Text style={styles.primaryButtonText}>지역 선택하기</Text>
      </Pressable>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: "#FFFFFF", paddingHorizontal: 24 },
  header: { paddingBottom: 24, paddingTop: 20 },
  brand: {
    color: "#171717",
    fontSize: 30,
    fontWeight: "700",
    letterSpacing: -1,
  },
  subtitle: { color: "#737373", fontSize: 14, marginTop: 6 },
  mapPlaceholder: { alignItems: "center", flex: 1, justifyContent: "center" },
  mapTitle: { color: "#262626", fontSize: 22, fontWeight: "600" },
  mapHint: { color: "#A3A3A3", fontSize: 14, marginTop: 8 },
  primaryButton: {
    alignItems: "center",
    backgroundColor: "#171717",
    borderRadius: 16,
    marginBottom: 20,
    padding: 17,
  },
  primaryButtonText: { color: "#FFFFFF", fontSize: 16, fontWeight: "600" },
});

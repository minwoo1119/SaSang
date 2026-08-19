import { Pressable, SafeAreaView, StyleSheet, Text, View } from "react-native";
import koreaMapJson from "../assets/maps/korea/regions.json";
import worldMapJson from "../assets/maps/world/countries.json";
import { InteractiveRegionMap } from "@/features/map/components/InteractiveRegionMap";
import { MapModeTabs } from "@/features/map/components/MapModeTabs";
import { useMapUiStore } from "@/features/map/store/mapUi.store";

export function MapScreen() {
  const mode = useMapUiStore((state) => state.mode);
  const setMode = useMapUiStore((state) => state.setMode);
  const selectedRegionCode = useMapUiStore((state) => state.selectedRegionCode);
  const regions = mode === "korea" ? koreaMapJson.regions : worldMapJson.regions;
  const selectedRegion = regions.find(
    ({ code }) => code === selectedRegionCode,
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.brand}>사상</Text>
        <Text style={styles.subtitle}>나의 여행을 지도에 남기다</Text>
      </View>
      <MapModeTabs value={mode} onChange={setMode} />
      <View style={styles.mapArea}>
        <InteractiveRegionMap mode={mode} />
      </View>
      <View style={styles.selectionArea}>
        <Text style={styles.selectionLabel}>선택한 지역</Text>
        <Text style={styles.selectionName}>
          {selectedRegion?.name ?? "지도를 눌러보세요"}
        </Text>
        {selectedRegion ? (
          <Text style={styles.selectionCode}>{selectedRegion.code}</Text>
        ) : null}
      </View>
      <Pressable
        accessibilityRole="button"
        disabled={!selectedRegion}
        style={[styles.primaryButton, !selectedRegion && styles.disabledButton]}
      >
        <Text style={styles.primaryButtonText}>이 지역에 사진 추가</Text>
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
  mapArea: { alignItems: "center", flex: 1, justifyContent: "center" },
  selectionArea: {
    borderTopColor: "#F5F5F5",
    borderTopWidth: 1,
    paddingVertical: 16,
  },
  selectionLabel: { color: "#A3A3A3", fontSize: 12 },
  selectionName: {
    color: "#171717",
    fontSize: 18,
    fontWeight: "600",
    marginTop: 4,
  },
  selectionCode: { color: "#737373", fontSize: 13, marginTop: 3 },
  primaryButton: {
    alignItems: "center",
    backgroundColor: "#171717",
    borderRadius: 16,
    marginBottom: 20,
    padding: 17,
  },
  primaryButtonText: { color: "#FFFFFF", fontSize: 16, fontWeight: "600" },
  disabledButton: { backgroundColor: "#D4D4D4" },
});

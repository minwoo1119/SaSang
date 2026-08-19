import { Image } from "expo-image";
import * as ImagePicker from "expo-image-picker";
import { useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { InteractiveRegionMap } from "@/features/map/components/InteractiveRegionMap";
import { MapGlassSurface } from "@/features/map/components/MapGlassSurface";
import { MapModeTabs } from "@/features/map/components/MapModeTabs";
import { MAP_ASSETS } from "@/features/map/models/mapAssets";
import {
  getRegionPhotoKey,
  useMapUiStore,
} from "@/features/map/store/mapUi.store";

export function MapScreen() {
  const insets = useSafeAreaInsets();
  const [isPickingPhoto, setIsPickingPhoto] = useState(false);
  const mode = useMapUiStore((state) => state.mode);
  const setMode = useMapUiStore((state) => state.setMode);
  const selectedRegionCode = useMapUiStore((state) => state.selectedRegionCode);
  const regionPhotos = useMapUiStore((state) => state.regionPhotos);
  const setRegionPhoto = useMapUiStore((state) => state.setRegionPhoto);
  const removeRegionPhoto = useMapUiStore((state) => state.removeRegionPhoto);
  const map = MAP_ASSETS[mode];
  const selectedRegion = map.regions.find(
    ({ code }) => code === selectedRegionCode,
  );
  const selectedPhoto = selectedRegion
    ? regionPhotos[getRegionPhotoKey(mode, selectedRegion.code)]
    : undefined;
  const photoCount = map.regions.filter(
    ({ code }) => regionPhotos[getRegionPhotoKey(mode, code)],
  ).length;

  const pickPhoto = async () => {
    if (!selectedRegion || isPickingPhoto) return;

    try {
      setIsPickingPhoto(true);
      const result = await ImagePicker.launchImageLibraryAsync({
        allowsEditing: false,
        mediaTypes: ["images"],
        quality: 0.9,
      });
      const asset = result.assets?.[0];
      if (!result.canceled && asset) {
        setRegionPhoto(mode, selectedRegion.code, {
          createdAt: new Date().toISOString(),
          height: asset.height,
          id: asset.assetId ?? `${mode}-${selectedRegion.code}-${Date.now()}`,
          offsetX: 0,
          offsetY: 0,
          scale: 1,
          uri: asset.uri,
          width: asset.width,
        });
      }
    } catch (error: unknown) {
      const message =
        error instanceof Error ? error.message : "사진을 불러오지 못했습니다.";
      Alert.alert("사진을 추가할 수 없어요", message);
    } finally {
      setIsPickingPhoto(false);
    }
  };

  return (
    <View style={styles.container}>
      <View
        style={[
          styles.mapViewport,
          { bottom: insets.bottom + 170, top: insets.top + 104 },
        ]}
      >
        <InteractiveRegionMap mode={mode} />
      </View>

      <View style={[styles.topOverlay, { top: insets.top + 10 }]}>
        <View style={styles.brandRow}>
          <View>
            <Text style={styles.brand}>사상</Text>
            <Text style={styles.tagline}>나의 여행을 지도에 남기다</Text>
          </View>
          <View style={styles.countBadge}>
            <Text style={styles.countNumber}>{photoCount}</Text>
            <Text style={styles.countLabel}>기록</Text>
          </View>
        </View>
        <MapModeTabs onChange={setMode} value={mode} />
      </View>

      <MapGlassSurface
        style={[styles.bottomSheet, { bottom: insets.bottom + 12 }]}
      >
        <View style={styles.regionRow}>
          {selectedPhoto ? (
            <Image source={{ uri: selectedPhoto.uri }} style={styles.thumbnail} />
          ) : (
            <View style={styles.regionMarker}>
              <View style={styles.regionMarkerDot} />
            </View>
          )}
          <View style={styles.regionCopy}>
            <Text style={styles.regionEyebrow}>
              {selectedRegion?.provinceName ??
                (mode === "korea" ? "대한민국" : "세계")}
            </Text>
            <Text numberOfLines={1} style={styles.regionName}>
              {selectedRegion?.name ?? "지역을 선택해 주세요"}
            </Text>
            <Text style={styles.regionCode}>
              {selectedRegion?.code ?? "지도를 탭해 여행 기록을 시작하세요"}
            </Text>
          </View>
          {selectedPhoto && selectedRegion ? (
            <Pressable
              accessibilityLabel="선택 지역 사진 삭제"
              accessibilityRole="button"
              hitSlop={8}
              onPress={() => removeRegionPhoto(mode, selectedRegion.code)}
              style={({ pressed }) => [
                styles.removeButton,
                pressed && styles.pressed,
              ]}
            >
              <Text style={styles.removeText}>삭제</Text>
            </Pressable>
          ) : null}
        </View>

        <Pressable
          accessibilityRole="button"
          accessibilityState={{ disabled: !selectedRegion || isPickingPhoto }}
          disabled={!selectedRegion || isPickingPhoto}
          onPress={pickPhoto}
          style={({ pressed }) => [
            styles.photoButton,
            !selectedRegion && styles.disabledButton,
            pressed && selectedRegion && styles.photoButtonPressed,
          ]}
        >
          {isPickingPhoto ? (
            <ActivityIndicator color="#FFFFFF" />
          ) : (
            <>
              <Text style={styles.photoButtonIcon}>＋</Text>
              <Text style={styles.photoButtonText}>
                {selectedPhoto ? "사진 바꾸기" : "사진 추가"}
              </Text>
            </>
          )}
        </Pressable>
      </MapGlassSurface>
    </View>
  );
}

const styles = StyleSheet.create({
  bottomSheet: {
    borderRadius: 28,
    left: 14,
    padding: 14,
    position: "absolute",
    right: 14,
  },
  brand: {
    color: "#272521",
    fontSize: 26,
    fontWeight: "800",
    letterSpacing: -1.1,
  },
  brandRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 4,
  },
  container: { backgroundColor: "#F8F6F1", flex: 1 },
  countBadge: {
    alignItems: "baseline",
    backgroundColor: "rgba(39, 37, 33, 0.07)",
    borderRadius: 18,
    flexDirection: "row",
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  countLabel: { color: "#777269", fontSize: 11, fontWeight: "600" },
  countNumber: { color: "#272521", fontSize: 14, fontWeight: "800" },
  disabledButton: { backgroundColor: "#BDB9B0" },
  mapViewport: { left: 0, position: "absolute", right: 0 },
  photoButton: {
    alignItems: "center",
    backgroundColor: "#E05A3F",
    borderRadius: 19,
    flexDirection: "row",
    gap: 6,
    height: 50,
    justifyContent: "center",
    marginTop: 12,
  },
  photoButtonIcon: {
    color: "#FFFFFF",
    fontSize: 21,
    fontWeight: "400",
    lineHeight: 23,
  },
  photoButtonPressed: { backgroundColor: "#C94C34" },
  photoButtonText: { color: "#FFFFFF", fontSize: 15, fontWeight: "700" },
  pressed: { opacity: 0.55 },
  regionCode: { color: "#8A857C", fontSize: 11, marginTop: 2 },
  regionCopy: { flex: 1, minWidth: 0 },
  regionEyebrow: {
    color: "#8A857C",
    fontSize: 11,
    fontWeight: "600",
    marginBottom: 1,
  },
  regionMarker: {
    alignItems: "center",
    backgroundColor: "#EEEAE2",
    borderRadius: 18,
    height: 48,
    justifyContent: "center",
    width: 48,
  },
  regionMarkerDot: {
    backgroundColor: "#E05A3F",
    borderRadius: 5,
    height: 10,
    width: 10,
  },
  regionName: {
    color: "#272521",
    fontSize: 18,
    fontWeight: "700",
    letterSpacing: -0.45,
  },
  regionRow: { alignItems: "center", flexDirection: "row", gap: 12 },
  removeButton: { paddingHorizontal: 4, paddingVertical: 10 },
  removeText: { color: "#8A857C", fontSize: 12, fontWeight: "600" },
  tagline: { color: "#777269", fontSize: 11, marginTop: 1 },
  thumbnail: { borderRadius: 18, height: 48, width: 48 },
  topOverlay: {
    gap: 10,
    left: 18,
    position: "absolute",
    right: 18,
  },
});

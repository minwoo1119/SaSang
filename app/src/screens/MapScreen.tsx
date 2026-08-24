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
  const tabBarOffset = insets.bottom + 92;

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
      <View style={styles.mapViewport}>
        <InteractiveRegionMap mode={mode} />
      </View>

      <View
        pointerEvents="box-none"
        style={[styles.topOverlay, { top: insets.top + 8 }]}
      >
        <View style={styles.headerRow}>
          <View>
            <Text style={styles.brand}>사상</Text>
            <Text style={styles.recordCount}>{photoCount}개의 여행 기록</Text>
          </View>
          <MapModeTabs onChange={setMode} value={mode} />
        </View>
      </View>

      {selectedRegion ? (
        <MapGlassSurface
          style={[styles.regionControl, { bottom: tabBarOffset }]}
        >
          {selectedPhoto ? (
            <Image source={{ uri: selectedPhoto.uri }} style={styles.thumbnail} />
          ) : (
            <View style={styles.regionMarker} />
          )}
          <View style={styles.regionCopy}>
            <Text numberOfLines={1} style={styles.regionName}>
              {selectedRegion.name}
            </Text>
            <Text numberOfLines={1} style={styles.regionCode}>
              {selectedRegion.provinceName ??
                (mode === "korea" ? "대한민국" : "세계")}{" "}
              · {selectedRegion.code}
            </Text>
          </View>
          {selectedPhoto ? (
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
          <Pressable
            accessibilityLabel={selectedPhoto ? "지역 사진 바꾸기" : "지역 사진 추가"}
            accessibilityRole="button"
            accessibilityState={{ disabled: isPickingPhoto }}
            disabled={isPickingPhoto}
            onPress={pickPhoto}
            style={({ pressed }) => [
              styles.photoButton,
              pressed && styles.photoButtonPressed,
            ]}
          >
            {isPickingPhoto ? (
              <ActivityIndicator color="#FFFFFF" size="small" />
            ) : (
              <Text style={styles.photoButtonIcon}>＋</Text>
            )}
          </Pressable>
        </MapGlassSurface>
      ) : (
        <MapGlassSurface
          style={[styles.selectionHint, { bottom: tabBarOffset }]}
        >
          <Text style={styles.selectionHintText}>지역을 선택해 기록을 시작하세요</Text>
        </MapGlassSurface>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  brand: {
    color: "#17191D",
    fontSize: 24,
    fontWeight: "800",
    letterSpacing: -0.9,
  },
  container: { backgroundColor: "#F1F2F0", flex: 1 },
  headerRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  mapViewport: StyleSheet.absoluteFillObject,
  photoButton: {
    alignItems: "center",
    backgroundColor: "#17191D",
    borderRadius: 23,
    height: 46,
    justifyContent: "center",
    width: 46,
  },
  photoButtonIcon: {
    color: "#FFFFFF",
    fontSize: 23,
    fontWeight: "400",
    lineHeight: 23,
  },
  photoButtonPressed: { backgroundColor: "#3B3E44" },
  pressed: { opacity: 0.55 },
  recordCount: { color: "#666B73", fontSize: 11, marginTop: 1 },
  regionCode: { color: "#777C84", fontSize: 11, marginTop: 2 },
  regionControl: {
    alignItems: "center",
    borderRadius: 30,
    flexDirection: "row",
    gap: 11,
    left: 12,
    minHeight: 64,
    paddingHorizontal: 10,
    paddingVertical: 9,
    position: "absolute",
    right: 12,
  },
  regionCopy: { flex: 1, minWidth: 0 },
  regionMarker: {
    backgroundColor: "#3268C8",
    borderRadius: 21,
    height: 42,
    width: 42,
  },
  regionName: {
    color: "#17191D",
    fontSize: 16,
    fontWeight: "700",
    letterSpacing: -0.45,
  },
  removeButton: { paddingHorizontal: 4, paddingVertical: 10 },
  removeText: { color: "#777C84", fontSize: 12, fontWeight: "600" },
  selectionHint: {
    alignSelf: "center",
    borderRadius: 22,
    paddingHorizontal: 17,
    paddingVertical: 12,
    position: "absolute",
  },
  selectionHintText: { color: "#4D5158", fontSize: 13, fontWeight: "600" },
  thumbnail: { borderRadius: 21, height: 42, width: 42 },
  topOverlay: {
    left: 16,
    position: "absolute",
    right: 16,
  },
});

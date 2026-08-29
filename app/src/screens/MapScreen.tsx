import { Image } from "expo-image";
import { SymbolView } from "expo-symbols";
import * as ImagePicker from "expo-image-picker";
import { useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Keyboard,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { AdPlaceholderModal } from "@/features/ads/components/AdPlaceholderModal";
import { InteractiveRegionMap } from "@/features/map/components/InteractiveRegionMap";
import { MapGlassSurface } from "@/features/map/components/MapGlassSurface";
import { MapModeTabs } from "@/features/map/components/MapModeTabs";
import { MAP_ASSETS } from "@/features/map/models/mapAssets";
import {
  getRegionPhotoKey,
  useMapUiStore,
} from "@/features/map/store/mapUi.store";
import { trackEvent, trackScreenView } from "@/services/analytics/analytics";
import { saveImageToDevice } from "@/services/storage/localImageStorage";

export function MapScreen() {
  const insets = useSafeAreaInsets();
  const [isAdModalVisible, setIsAdModalVisible] = useState(true);
  const [isPickingPhoto, setIsPickingPhoto] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const mode = useMapUiStore((state) => state.mode);
  const setMode = useMapUiStore((state) => state.setMode);
  const selectRegion = useMapUiStore((state) => state.selectRegion);
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
  const trimmedSearchQuery = searchQuery.trim().toLowerCase();
  const searchResults = useMemo(() => {
    if (trimmedSearchQuery.length === 0) return [];

    return map.regions
      .filter((region) => {
        const provinceName = region.provinceName ?? "";
        const englishName = region.englishName ?? "";
        return `${region.name} ${englishName} ${provinceName} ${region.code}`
          .toLowerCase()
          .includes(trimmedSearchQuery);
      })
      .slice(0, 6);
  }, [map.regions, trimmedSearchQuery]);
  const showSearchResults = trimmedSearchQuery.length > 0;
  const canSubmitSearch = searchResults.length > 0;

  useEffect(() => {
    void trackScreenView("Map");
  }, []);

  useEffect(() => {
    setSearchQuery("");
  }, [mode]);

  const handleSearchResultPress = (code: string, name: string) => {
    selectRegion(code);
    setSearchQuery(name);
    Keyboard.dismiss();
    void trackEvent("region_search_selected", {
      map_mode: mode,
      region_code: code,
    });
  };

  const handleSearchSubmit = () => {
    const [firstResult] = searchResults;
    if (!firstResult) return;
    handleSearchResultPress(firstResult.code, firstResult.name);
  };

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
        const savedUri = await saveImageToDevice(
          asset.uri,
          "photos",
          `${mode}-${selectedRegion.code}`,
        );
        setRegionPhoto(mode, selectedRegion.code, {
          createdAt: new Date().toISOString(),
          height: asset.height,
          id: asset.assetId ?? `${mode}-${selectedRegion.code}-${Date.now()}`,
          offsetX: 0,
          offsetY: 0,
          scale: 1,
          uri: savedUri,
          width: asset.width,
        });
        void trackEvent("region_photo_saved", {
          map_mode: mode,
          region_code: selectedRegion.code,
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

  const handleRemovePhoto = () => {
    if (!selectedRegion) return;

    Alert.alert(
      "사진 삭제",
      `'${selectedRegion.name}'에 등록된 여행 사진을 삭제할까요?`,
      [
        {
          style: "cancel",
          text: "취소",
        },
        {
          onPress: () => {
            removeRegionPhoto(mode, selectedRegion.code);
            void trackEvent("region_photo_removed", {
              map_mode: mode,
              region_code: selectedRegion.code,
            });
          },
          style: "destructive",
          text: "삭제",
        },
      ],
    );
  };

  const closeAdModal = () => {
    setIsAdModalVisible(false);
    void trackEvent("ad_placeholder_closed");
  };

  return (
    <View style={styles.container}>
      <View style={styles.mapViewport}>
        <InteractiveRegionMap
          mode={mode}
          zoomControlsBottom={tabBarOffset + 78}
        />
      </View>

      <View
        pointerEvents="box-none"
        style={[styles.topOverlay, { top: insets.top + 8 }]}
      >
        <View style={styles.headerRow}>
          <View style={styles.brandBlock}>
            <Image
              contentFit="cover"
              source={require("../../assets/images/icon.png")}
              style={styles.brandIcon}
            />
            <View style={styles.brandCopy}>
              <Image
                contentFit="contain"
                source={require("../../assets/images/main-text-design.png")}
                style={styles.brandTextImage}
              />
              <Text style={styles.recordCount}>{photoCount}개의 여행 기록</Text>
            </View>
          </View>
          <MapModeTabs onChange={setMode} value={mode} />
        </View>
        <MapGlassSurface style={styles.searchBar}>
          <TextInput
            autoCapitalize="none"
            autoCorrect={false}
            clearButtonMode="while-editing"
            onSubmitEditing={handleSearchSubmit}
            onChangeText={setSearchQuery}
            placeholder={
              mode === "korea" ? "지역명 또는 코드" : "국가명 또는 코드"
            }
            placeholderTextColor="#8A8A91"
            returnKeyType="search"
            style={styles.searchInput}
            value={searchQuery}
          />
          {searchQuery.length > 0 ? (
            <Pressable
              accessibilityLabel="검색어 지우기"
              accessibilityRole="button"
              hitSlop={8}
              onPress={() => setSearchQuery("")}
              style={({ pressed }) => [
                styles.clearSearchButton,
                pressed && styles.pressed,
              ]}
            >
              <Text style={styles.clearSearchText}>x</Text>
            </Pressable>
          ) : null}
          <Pressable
            accessibilityLabel="지역 검색"
            accessibilityRole="button"
            disabled={!canSubmitSearch}
            hitSlop={8}
            onPress={handleSearchSubmit}
            style={({ pressed }) => [
              styles.searchButton,
              !canSubmitSearch && styles.searchButtonDisabled,
              pressed && styles.searchButtonPressed,
            ]}
          >
            <SymbolView
              fallback={
                <Text
                  style={[
                    styles.searchButtonFallback,
                    !canSubmitSearch && styles.searchButtonFallbackDisabled,
                  ]}
                >
                  ⌕
                </Text>
              }
              name="magnifyingglass"
              size={17}
              tintColor={canSubmitSearch ? "#007AFF" : "#A1A1AA"}
            />
          </Pressable>
        </MapGlassSurface>
        {showSearchResults ? (
          <MapGlassSurface style={styles.searchResults}>
            {searchResults.length > 0 ? (
              searchResults.map((region) => (
                <Pressable
                  accessibilityRole="button"
                  key={region.code}
                  onPress={() =>
                    handleSearchResultPress(region.code, region.name)
                  }
                  style={({ pressed }) => [
                    styles.searchResult,
                    pressed && styles.searchResultPressed,
                  ]}
                >
                  <View style={styles.searchResultMarker} />
                  <View style={styles.searchResultCopy}>
                    <Text numberOfLines={1} style={styles.searchResultName}>
                      {region.name}
                    </Text>
                    <Text numberOfLines={1} style={styles.searchResultMeta}>
                      {region.provinceName ??
                        (mode === "korea" ? "국내" : "해외")}{" "}
                      · {region.code}
                    </Text>
                  </View>
                </Pressable>
              ))
            ) : (
              <Text style={styles.emptySearchResult}>검색 결과 없음</Text>
            )}
          </MapGlassSurface>
        ) : null}
      </View>

      {selectedRegion ? (
        <MapGlassSurface
          style={[styles.regionControl, { bottom: tabBarOffset }]}
        >
          {selectedPhoto ? (
            <Image
              source={{ uri: selectedPhoto.uri }}
              style={styles.thumbnail}
            />
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
              onPress={handleRemovePhoto}
              style={({ pressed }) => [
                styles.removeButton,
                pressed && styles.pressed,
              ]}
            >
              <Text style={styles.removeText}>삭제</Text>
            </Pressable>
          ) : null}
          <Pressable
            accessibilityLabel={
              selectedPhoto ? "지역 사진 바꾸기" : "지역 사진 추가"
            }
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
          <Text style={styles.selectionHintText}>
            지역을 선택해 기록을 시작하세요
          </Text>
        </MapGlassSurface>
      )}
      <AdPlaceholderModal onClose={closeAdModal} visible={isAdModalVisible} />
    </View>
  );
}

const styles = StyleSheet.create({
  brandBlock: {
    alignItems: "center",
    flexDirection: "row",
    gap: 9,
  },
  brandIcon: {
    borderRadius: 8,
    height: 32,
    width: 32,
  },
  brandCopy: {
    gap: 1,
  },
  brandTextImage: {
    height: 27,
    width: 44,
  },
  container: { backgroundColor: "#FAFAFA", flex: 1 },
  headerRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  mapViewport: StyleSheet.absoluteFillObject,
  photoButton: {
    alignItems: "center",
    backgroundColor: "#007AFF",
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
  photoButtonPressed: { backgroundColor: "#0068D9" },
  pressed: { opacity: 0.55 },
  recordCount: { color: "#71717A", fontSize: 11, fontWeight: "700" },
  regionCode: { color: "#71717A", fontSize: 11, marginTop: 2 },
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
    backgroundColor: "#007AFF",
    borderRadius: 21,
    height: 42,
    width: 42,
  },
  regionName: {
    color: "#18181B",
    fontSize: 16,
    fontWeight: "700",
    letterSpacing: -0.45,
  },
  removeButton: { paddingHorizontal: 4, paddingVertical: 10 },
  removeText: { color: "#71717A", fontSize: 12, fontWeight: "600" },
  selectionHint: {
    alignSelf: "center",
    borderRadius: 22,
    paddingHorizontal: 17,
    paddingVertical: 12,
    position: "absolute",
  },
  selectionHintText: { color: "#52525B", fontSize: 13, fontWeight: "600" },
  clearSearchButton: {
    alignItems: "center",
    backgroundColor: "#E4E4E7",
    borderRadius: 11,
    height: 22,
    justifyContent: "center",
    width: 22,
  },
  clearSearchText: {
    color: "#52525B",
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 15,
  },
  emptySearchResult: {
    color: "#71717A",
    fontSize: 13,
    fontWeight: "600",
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  searchBar: {
    alignItems: "center",
    backgroundColor: "rgba(255, 255, 255, 0.96)",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 23,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 10,
    height: 46,
    marginTop: 12,
    paddingHorizontal: 14,
  },
  searchInput: {
    color: "#18181B",
    flex: 1,
    fontSize: 15,
    fontWeight: "600",
    height: 44,
    minWidth: 0,
    padding: 0,
  },
  searchButton: {
    alignItems: "center",
    backgroundColor: "rgba(0, 122, 255, 0.12)",
    borderRadius: 16,
    height: 32,
    justifyContent: "center",
    width: 32,
  },
  searchButtonDisabled: {
    backgroundColor: "#F4F4F5",
  },
  searchButtonFallback: {
    color: "#007AFF",
    fontSize: 17,
    fontWeight: "800",
    lineHeight: 18,
  },
  searchButtonFallbackDisabled: { color: "#A1A1AA" },
  searchButtonPressed: { backgroundColor: "rgba(0, 122, 255, 0.2)" },
  searchResult: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    minHeight: 48,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  searchResultCopy: { flex: 1, minWidth: 0 },
  searchResultMarker: {
    backgroundColor: "#007AFF",
    borderRadius: 4,
    height: 8,
    width: 8,
  },
  searchResultMeta: {
    color: "#71717A",
    fontSize: 11,
    fontWeight: "600",
    marginTop: 2,
  },
  searchResultName: {
    color: "#18181B",
    fontSize: 14,
    fontWeight: "700",
  },
  searchResultPressed: { backgroundColor: "rgba(0, 122, 255, 0.08)" },
  searchResults: {
    backgroundColor: "rgba(255, 255, 255, 0.97)",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 18,
    borderWidth: StyleSheet.hairlineWidth,
    marginTop: 8,
    overflow: "hidden",
  },
  thumbnail: { borderRadius: 21, height: 42, width: 42 },
  topOverlay: {
    left: 16,
    position: "absolute",
    right: 16,
  },
});

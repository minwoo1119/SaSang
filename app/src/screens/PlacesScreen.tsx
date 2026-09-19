import { Image } from "expo-image";
import * as ImagePicker from "expo-image-picker";
import { router } from "expo-router";
import { SymbolView } from "expo-symbols";
import { useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { AdNativeCardPlaceholder } from "@/features/ads/components/AdNativeCardPlaceholder";
import { OwnedMapSelector } from "@/features/map/components/OwnedMapSelector";
import { getOwnedMap } from "@/features/map/models/mapCatalog";
import { MAP_ASSETS } from "@/features/map/models/mapAssets";
import type {
  MapMode,
  MapRegion,
  RegionPhoto,
} from "@/features/map/models/map.types";
import { useMapUiStore } from "@/features/map/store/mapUi.store";
import { PhotoDateModal } from "@/features/photos/components/PhotoDateModal";
import {
  getPhotoTakenDate,
  getRegionPhotoDateKey,
  parsePhotoDate,
  toPhotoDateKey,
} from "@/features/photos/utils/photoDate";
import { trackEvent, trackScreenView } from "@/services/analytics/analytics";
import { saveImageToDevice } from "@/services/storage/localImageStorage";

type SortOrder = "newest" | "oldest";

type PlaceCard = {
  id: string;
  mode: MapMode;
  photo: RegionPhoto;
  region: MapRegion;
};

type PendingReplacement = {
  asset: ImagePicker.ImagePickerAsset;
  dateFromMetadata: boolean;
  initialDate: Date;
  mode: MapMode;
  regionCode: string;
};

export function PlacesScreen() {
  const insets = useSafeAreaInsets();
  const [sortOrder, setSortOrder] = useState<SortOrder>("newest");
  const [selectedCard, setSelectedCard] = useState<PlaceCard | null>(null);
  const [pendingReplacement, setPendingReplacement] =
    useState<PendingReplacement | null>(null);
  const [isSavingPhoto, setIsSavingPhoto] = useState(false);
  const filter = useMapUiStore((state) => state.mode);
  const setFilter = useMapUiStore((state) => state.setMode);
  const regionPhotos = useMapUiStore((state) => state.regionPhotos);
  const setRegionPhoto = useMapUiStore((state) => state.setRegionPhoto);
  const removeRegionPhoto = useMapUiStore((state) => state.removeRegionPhoto);

  useEffect(() => {
    void trackScreenView("Places");
  }, []);

  const cards = useMemo(() => {
    return Object.entries(regionPhotos)
      .reduce<PlaceCard[]>((items, [key, photo]) => {
        const [mode, regionCode] = key.split(":") as [MapMode, string];
        const region = MAP_ASSETS[mode]?.regions.find(
          ({ code }) => code === regionCode,
        );
        if (region) {
          items.push({ id: key, mode, photo, region });
        }
        return items;
      }, [])
      .filter(({ mode }) => mode === filter)
      .sort((a, b) => {
        const dateComparison = getRegionPhotoDateKey(a.photo).localeCompare(
          getRegionPhotoDateKey(b.photo),
        );
        const comparison =
          dateComparison || a.photo.createdAt.localeCompare(b.photo.createdAt);
        return sortOrder === "newest" ? -comparison : comparison;
      });
  }, [filter, regionPhotos, sortOrder]);

  const pickReplacement = async () => {
    if (!selectedCard || isSavingPhoto) return;

    try {
      setIsSavingPhoto(true);
      const result = await ImagePicker.launchImageLibraryAsync({
        allowsEditing: false,
        exif: true,
        mediaTypes: ["images"],
        quality: 0.9,
      });
      const asset = result.assets?.[0];
      if (!result.canceled && asset) {
        const metadataDate = getPhotoTakenDate(asset.exif);
        const now = new Date();
        const dateFromMetadata = metadataDate !== null && metadataDate <= now;
        setPendingReplacement({
          asset,
          dateFromMetadata,
          initialDate: dateFromMetadata ? metadataDate : now,
          mode: selectedCard.mode,
          regionCode: selectedCard.region.code,
        });
        setSelectedCard(null);
      }
    } catch (error: unknown) {
      const message =
        error instanceof Error ? error.message : "사진을 불러오지 못했습니다.";
      Alert.alert("사진을 변경할 수 없어요", message);
    } finally {
      setIsSavingPhoto(false);
    }
  };

  const saveReplacement = async (takenAt: Date) => {
    if (!pendingReplacement || isSavingPhoto) return;

    try {
      setIsSavingPhoto(true);
      const { asset, mode, regionCode } = pendingReplacement;
      const savedUri = await saveImageToDevice(
        asset.uri,
        "photos",
        `${mode}-${regionCode}`,
      );
      setRegionPhoto(mode, regionCode, {
        createdAt: new Date().toISOString(),
        height: asset.height,
        id: asset.assetId ?? `${mode}-${regionCode}-${Date.now()}`,
        offsetX: 0,
        offsetY: 0,
        scale: 1,
        takenAt: toPhotoDateKey(takenAt),
        uri: savedUri,
        width: asset.width,
      });
      setPendingReplacement(null);
      void trackEvent("place_photo_replaced", {
        map_mode: mode,
        region_code: regionCode,
      });
    } catch (error: unknown) {
      const message =
        error instanceof Error ? error.message : "사진을 저장하지 못했습니다.";
      Alert.alert("사진을 변경할 수 없어요", message);
    } finally {
      setIsSavingPhoto(false);
    }
  };

  const deleteSelectedPhoto = () => {
    if (!selectedCard) return;
    const { mode, region } = selectedCard;

    Alert.alert("사진 삭제", `'${region.name}'의 사진을 삭제할까요?`, [
      { style: "cancel", text: "취소" },
      {
        onPress: () => {
          removeRegionPhoto(mode, region.code);
          setSelectedCard(null);
          void trackEvent("place_photo_removed", {
            map_mode: mode,
            region_code: region.code,
          });
        },
        style: "destructive",
        text: "삭제",
      },
    ]);
  };

  return (
    <View style={styles.container}>
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <View style={styles.headerRow}>
          <OwnedMapSelector onChange={setFilter} value={filter} />
          <Pressable
            accessibilityLabel={`날짜 정렬, 현재 ${sortOrder === "newest" ? "최신순" : "오래된순"}`}
            accessibilityRole="button"
            onPress={() =>
              setSortOrder((current) =>
                current === "newest" ? "oldest" : "newest",
              )
            }
            style={({ pressed }) => [
              styles.sortButton,
              pressed && styles.pressed,
            ]}
          >
            <SymbolView
              fallback={<Text style={styles.sortFallback}>↕</Text>}
              name="arrow.up.arrow.down"
              size={13}
              tintColor="#52525B"
            />
            <Text style={styles.sortText}>
              {sortOrder === "newest" ? "최신순" : "오래된순"}
            </Text>
          </Pressable>
        </View>
      </View>

      <ScrollView
        contentContainerStyle={[
          styles.list,
          { paddingBottom: insets.bottom + 110 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {cards.length > 0 ? (
          cards.map((card, index) => (
            <View key={card.id} style={styles.listItem}>
              <PlacePhotoCard
                card={card}
                onPress={() => setSelectedCard(card)}
              />
              {index === 0 ? (
                <AdNativeCardPlaceholder style={styles.adItemMargin} />
              ) : null}
            </View>
          ))
        ) : (
          <EmptyPlacesState filter={filter} />
        )}
      </ScrollView>

      <PhotoManagementModal
        isBusy={isSavingPhoto}
        onClose={() => setSelectedCard(null)}
        onDelete={deleteSelectedPhoto}
        onReplace={pickReplacement}
        selectedCard={selectedCard}
      />
      <PhotoDateModal
        dateFromMetadata={pendingReplacement?.dateFromMetadata ?? false}
        initialDate={pendingReplacement?.initialDate ?? new Date()}
        isSaving={isSavingPhoto}
        onCancel={() => setPendingReplacement(null)}
        onConfirm={saveReplacement}
        photoUri={pendingReplacement?.asset.uri ?? ""}
        visible={pendingReplacement !== null}
      />
    </View>
  );
}

function EmptyPlacesState({ filter }: { filter: MapMode }) {
  const isKorea = filter === "korea";
  const mapName = getOwnedMap(filter).name;
  const subtitleText = isKorea
    ? "지도에서 원하는 시·군·구를 선택하고\n사진을 채워 나만의 여행 지도를 만들어보세요."
    : "지도에서 다녀온 국가를 선택하고\n사진을 채워 세계 여행을 기록해보세요.";

  return (
    <View style={styles.emptyContainer}>
      <View style={styles.emptyState}>
        <Text style={styles.emptyMapName}>{mapName}</Text>
        <Text style={styles.emptyTitle}>아직 여행 기록이 없어요</Text>
        <Text style={styles.emptyDescription}>{subtitleText}</Text>

        <Pressable
          accessibilityRole="button"
          onPress={() => router.push("/map")}
          style={({ pressed }) => [
            styles.ctaButton,
            pressed && styles.ctaButtonPressed,
          ]}
        >
          <Text style={styles.ctaButtonText}>지도에서 사진 추가하기</Text>
        </Pressable>
      </View>

      <AdNativeCardPlaceholder style={styles.emptyAdMargin} />
    </View>
  );
}

function PhotoManagementModal({
  isBusy,
  onClose,
  onDelete,
  onReplace,
  selectedCard,
}: {
  isBusy: boolean;
  onClose: () => void;
  onDelete: () => void;
  onReplace: () => void;
  selectedCard: PlaceCard | null;
}) {
  return (
    <Modal
      animationType="fade"
      onRequestClose={isBusy ? undefined : onClose}
      presentationStyle="overFullScreen"
      transparent
      visible={selectedCard !== null}
    >
      <View style={styles.photoModalBackdrop}>
        <Pressable
          accessibilityLabel="사진 관리 닫기"
          disabled={isBusy}
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        {selectedCard ? (
          <View accessibilityViewIsModal style={styles.photoModalSheet}>
            <Image
              contentFit="cover"
              source={{ uri: selectedCard.photo.uri }}
              style={styles.photoModalPreview}
            />
            <View style={styles.photoModalCopy}>
              <Text numberOfLines={1} style={styles.photoModalTitle}>
                {selectedCard.region.name}
              </Text>
              <Text style={styles.photoModalSubtitle}>사진 관리</Text>
            </View>
            <Pressable
              accessibilityRole="button"
              disabled={isBusy}
              onPress={onReplace}
              style={({ pressed }) => [
                styles.replaceButton,
                pressed && styles.replaceButtonPressed,
              ]}
            >
              {isBusy ? (
                <ActivityIndicator color="#FFFFFF" size="small" />
              ) : (
                <Text style={styles.replaceButtonText}>새 사진으로 변경</Text>
              )}
            </Pressable>
            <View style={styles.photoModalSecondaryActions}>
              <Pressable
                accessibilityRole="button"
                disabled={isBusy}
                onPress={onClose}
                style={({ pressed }) => [
                  styles.photoModalSecondaryButton,
                  pressed && styles.pressed,
                ]}
              >
                <Text style={styles.photoModalCloseText}>닫기</Text>
              </Pressable>
              <Pressable
                accessibilityRole="button"
                disabled={isBusy}
                onPress={onDelete}
                style={({ pressed }) => [
                  styles.photoModalSecondaryButton,
                  pressed && styles.pressed,
                ]}
              >
                <Text style={styles.photoModalDeleteText}>삭제</Text>
              </Pressable>
            </View>
          </View>
        ) : null}
      </View>
    </Modal>
  );
}

function PlacePhotoCard({
  card,
  onPress,
}: {
  card: PlaceCard;
  onPress: () => void;
}) {
  const locationLabel =
    card.region.provinceName ?? (card.mode === "korea" ? "대한민국" : "해외");
  const photoDate =
    parsePhotoDate(getRegionPhotoDateKey(card.photo)) ??
    new Date(card.photo.createdAt);
  const dateLabel = new Intl.DateTimeFormat("ko-KR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(photoDate);

  return (
    <Pressable
      accessibilityLabel={`${card.region.name} 사진 관리`}
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.card, pressed && styles.pressed]}
    >
      <View style={styles.imageFrame}>
        <Image source={{ uri: card.photo.uri }} style={styles.cardImage} />
      </View>
      <View style={styles.cardDivider} />
      <View style={styles.cardBody}>
        <View style={styles.cardTitleRow}>
          <Text numberOfLines={1} style={styles.regionName}>
            {card.region.name}
          </Text>
          <Text style={styles.modeLabel}>
            {card.mode === "korea" ? "국내" : "해외"}
          </Text>
        </View>
        <Text numberOfLines={1} style={styles.locationText}>
          {locationLabel}
        </Text>
        <Text style={styles.dateText}>{dateLabel}</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  adItemMargin: {
    marginBottom: 4,
    marginTop: 12,
  },
  card: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(24, 24, 27, 0.1)",
    borderRadius: 8,
    borderWidth: 1,
    gap: 0,
    overflow: "hidden",
    shadowColor: "#18181B",
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.06,
    shadowRadius: 14,
  },
  cardBody: {
    gap: 4,
    paddingBottom: 13,
    paddingHorizontal: 13,
    paddingTop: 12,
  },
  cardDivider: {
    backgroundColor: "rgba(24, 24, 27, 0.07)",
    height: StyleSheet.hairlineWidth,
  },
  cardImage: {
    backgroundColor: "#F4F4F5",
    height: "100%",
    width: "100%",
  },
  cardTitleRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    justifyContent: "space-between",
  },
  container: {
    backgroundColor: "#FAFAFA",
    flex: 1,
  },
  ctaButton: {
    alignItems: "center",
    backgroundColor: "#007AFF",
    borderRadius: 8,
    flexDirection: "row",
    height: 46,
    justifyContent: "center",
    marginTop: 4,
    paddingHorizontal: 22,
  },
  ctaButtonPressed: {
    opacity: 0.85,
    transform: [{ scale: 0.98 }],
  },
  ctaButtonText: {
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "800",
  },
  dateText: {
    color: "#71717A",
    fontSize: 12,
    fontWeight: "600",
  },
  emptyContainer: {
    gap: 20,
    marginTop: 8,
  },
  emptyAdMargin: {
    marginBottom: 8,
    marginTop: 16,
  },
  emptyDescription: {
    color: "#71717A",
    fontSize: 14,
    fontWeight: "600",
    lineHeight: 21,
    textAlign: "center",
  },
  emptyMapName: {
    color: "#007AFF",
    fontSize: 12,
    fontWeight: "800",
  },
  emptyState: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(24, 24, 27, 0.08)",
    borderRadius: 8,
    borderWidth: StyleSheet.hairlineWidth,
    gap: 10,
    paddingHorizontal: 24,
    paddingVertical: 42,
  },
  emptyTitle: {
    color: "#18181B",
    fontSize: 20,
    fontWeight: "800",
    textAlign: "center",
  },
  header: {
    paddingBottom: 18,
    paddingHorizontal: 16,
  },
  headerRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  imageFrame: {
    aspectRatio: 1.18,
    backgroundColor: "#F4F4F5",
    width: "100%",
  },
  list: {
    gap: 20,
    paddingHorizontal: 16,
  },
  listItem: {
    gap: 16,
  },
  locationText: {
    color: "#52525B",
    fontSize: 14,
    fontWeight: "600",
  },
  sortButton: {
    alignItems: "center",
    backgroundColor: "rgba(255, 255, 255, 0.92)",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 19,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 6,
    height: 38,
    paddingHorizontal: 12,
  },
  sortFallback: { color: "#52525B", fontSize: 14, fontWeight: "800" },
  sortText: { color: "#27272A", fontSize: 13, fontWeight: "800" },
  modeLabel: {
    backgroundColor: "rgba(0, 122, 255, 0.1)",
    borderRadius: 10,
    color: "#007AFF",
    fontSize: 11,
    fontWeight: "800",
    overflow: "hidden",
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  pressed: {
    opacity: 0.78,
  },
  photoModalBackdrop: {
    alignItems: "center",
    backgroundColor: "rgba(0, 0, 0, 0.38)",
    flex: 1,
    justifyContent: "center",
    padding: 20,
  },
  photoModalCloseText: {
    color: "#52525B",
    fontSize: 14,
    fontWeight: "700",
  },
  photoModalCopy: { gap: 3 },
  photoModalDeleteText: {
    color: "#EF4444",
    fontSize: 14,
    fontWeight: "800",
  },
  photoModalPreview: {
    aspectRatio: 1.7,
    backgroundColor: "#F4F4F5",
    borderRadius: 8,
    width: "100%",
  },
  photoModalSecondaryActions: { flexDirection: "row", gap: 8 },
  photoModalSecondaryButton: {
    alignItems: "center",
    backgroundColor: "#F4F4F5",
    borderRadius: 8,
    flex: 1,
    height: 44,
    justifyContent: "center",
  },
  photoModalSheet: {
    backgroundColor: "#FFFFFF",
    borderRadius: 8,
    gap: 15,
    maxWidth: 430,
    padding: 18,
    width: "100%",
  },
  photoModalSubtitle: { color: "#71717A", fontSize: 12, fontWeight: "600" },
  photoModalTitle: { color: "#18181B", fontSize: 20, fontWeight: "800" },
  replaceButton: {
    alignItems: "center",
    backgroundColor: "#007AFF",
    borderRadius: 8,
    height: 48,
    justifyContent: "center",
  },
  replaceButtonPressed: { backgroundColor: "#0068D9" },
  replaceButtonText: { color: "#FFFFFF", fontSize: 15, fontWeight: "800" },
  regionName: {
    color: "#18181B",
    flex: 1,
    fontSize: 16,
    fontWeight: "800",
  },
});

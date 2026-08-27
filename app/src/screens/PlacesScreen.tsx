import { Image } from "expo-image";
import { useEffect, useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { AdNativeCardPlaceholder } from "@/features/ads/components/AdNativeCardPlaceholder";
import { MAP_ASSETS } from "@/features/map/models/mapAssets";
import type {
  MapMode,
  MapRegion,
  RegionPhoto,
} from "@/features/map/models/map.types";
import { useMapUiStore } from "@/features/map/store/mapUi.store";
import { trackScreenView } from "@/services/analytics/analytics";

type PlaceFilter = "korea" | "world";

type PlaceCard = {
  id: string;
  mode: MapMode;
  photo: RegionPhoto;
  region: MapRegion;
};

export function PlacesScreen() {
  const insets = useSafeAreaInsets();
  const [filter, setFilter] = useState<PlaceFilter>("korea");
  const regionPhotos = useMapUiStore((state) => state.regionPhotos);

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
      .sort(
        (a, b) =>
          new Date(b.photo.createdAt).getTime() -
          new Date(a.photo.createdAt).getTime(),
      )
      .filter(({ mode }) => mode === filter);
  }, [filter, regionPhotos]);

  return (
    <View style={styles.container}>
      <View style={[styles.header, { paddingTop: insets.top + 20 }]}>
        <View style={styles.headerRow}>
          <View>
            <Text style={styles.title}>장소</Text>
            <Text style={styles.subtitle}>최근 기록한 여행 사진</Text>
          </View>
          <View style={styles.segmentedControl}>
            <FilterButton
              label="국내"
              onPress={() => setFilter("korea")}
              selected={filter === "korea"}
            />
            <FilterButton
              label="해외"
              onPress={() => setFilter("world")}
              selected={filter === "world"}
            />
          </View>
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
              <PlacePhotoCard card={card} />
              {index === 0 ? <AdNativeCardPlaceholder /> : null}
            </View>
          ))
        ) : (
          <View style={styles.emptySection}>
            <Text style={styles.emptyTitle}>아직 기록한 장소가 없어요</Text>
            <Text style={styles.emptyText}>
              지도에서 지역을 선택하고 사진을 추가하면 이곳에 모입니다.
            </Text>
            <AdNativeCardPlaceholder />
          </View>
        )}
      </ScrollView>
    </View>
  );
}

function FilterButton({
  label,
  onPress,
  selected,
}: {
  label: string;
  onPress: () => void;
  selected: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[styles.filterButton, selected && styles.filterButtonSelected]}
    >
      <Text style={[styles.filterText, selected && styles.filterTextSelected]}>
        {label}
      </Text>
    </Pressable>
  );
}

function PlacePhotoCard({ card }: { card: PlaceCard }) {
  const locationLabel =
    card.region.provinceName ?? (card.mode === "korea" ? "대한민국" : "해외");
  const dateLabel = new Intl.DateTimeFormat("ko-KR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(card.photo.createdAt));

  return (
    <Pressable
      accessibilityRole="button"
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
  dateText: {
    color: "#71717A",
    fontSize: 12,
    fontWeight: "600",
  },
  filterButton: {
    alignItems: "center",
    borderRadius: 18,
    height: 36,
    justifyContent: "center",
    minWidth: 58,
    paddingHorizontal: 14,
  },
  filterButtonSelected: {
    backgroundColor: "rgba(0, 122, 255, 0.12)",
  },
  filterText: {
    color: "#3F3F46",
    fontSize: 14,
    fontWeight: "700",
  },
  filterTextSelected: {
    color: "#007AFF",
    fontWeight: "800",
  },
  emptySection: {
    gap: 14,
  },
  emptyText: {
    color: "#71717A",
    fontSize: 14,
    fontWeight: "600",
    lineHeight: 20,
  },
  emptyTitle: {
    color: "#18181B",
    fontSize: 18,
    fontWeight: "800",
  },
  header: {
    paddingBottom: 18,
    paddingHorizontal: 16,
  },
  imageFrame: {
    aspectRatio: 1.18,
    backgroundColor: "#F4F4F5",
    width: "100%",
  },
  headerRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
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
  regionName: {
    color: "#18181B",
    flex: 1,
    fontSize: 16,
    fontWeight: "800",
  },
  segmentedControl: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 22,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 4,
    padding: 4,
  },
  subtitle: {
    color: "#71717A",
    fontSize: 12,
    fontWeight: "600",
    marginTop: 2,
  },
  title: {
    color: "#18181B",
    fontSize: 26,
    fontWeight: "800",
  },
});

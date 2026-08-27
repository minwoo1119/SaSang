import { Image } from "expo-image";
import { useEffect, useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
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
  photo?: RegionPhoto;
  region: MapRegion;
};

function findSampleRegion(mode: MapMode, code: string) {
  const region = MAP_ASSETS[mode].regions.find((item) => item.code === code);
  if (!region) {
    throw new Error(`Sample region not found: ${mode}:${code}`);
  }
  return region;
}

function samplePhoto(id: string, uri: string, createdAt: string): RegionPhoto {
  return {
    createdAt,
    height: 1000,
    id,
    offsetX: 0,
    offsetY: 0,
    scale: 1,
    uri,
    width: 1200,
  };
}

const sampleCards: PlaceCard[] = [
  {
    id: "sample-korea-seoul",
    mode: "korea",
    photo: samplePhoto(
      "sample-photo-seoul",
      "https://picsum.photos/id/1011/1200/1000",
      "2026-08-20T09:00:00.000Z",
    ),
    region: findSampleRegion("korea", "11000"),
  },
  {
    id: "sample-korea-daegu",
    mode: "korea",
    photo: samplePhoto(
      "sample-photo-daegu",
      "https://picsum.photos/id/1043/1200/1000",
      "2026-08-18T09:00:00.000Z",
    ),
    region: findSampleRegion("korea", "27000"),
  },
  {
    id: "sample-world-japan",
    mode: "world",
    photo: samplePhoto(
      "sample-photo-japan",
      "https://picsum.photos/id/1036/1200/1000",
      "2026-08-16T09:00:00.000Z",
    ),
    region: findSampleRegion("world", "JP"),
  },
  {
    id: "sample-world-france",
    mode: "world",
    photo: samplePhoto(
      "sample-photo-france",
      "https://picsum.photos/id/1067/1200/1000",
      "2026-08-14T09:00:00.000Z",
    ),
    region: findSampleRegion("world", "FR"),
  },
];

export function PlacesScreen() {
  const insets = useSafeAreaInsets();
  const [filter, setFilter] = useState<PlaceFilter>("korea");
  const regionPhotos = useMapUiStore((state) => state.regionPhotos);

  useEffect(() => {
    void trackScreenView("Places");
  }, []);

  const cards = useMemo(() => {
    const photoCards = Object.entries(regionPhotos)
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
          new Date(b.photo?.createdAt ?? 0).getTime() -
          new Date(a.photo?.createdAt ?? 0).getTime(),
      );

    return [...photoCards, ...sampleCards].filter(
      ({ mode }) => mode === filter,
    );
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
        {cards.map((card) => (
          <PlacePhotoCard card={card} key={card.id} />
        ))}
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
  const dateLabel = card.photo
    ? new Intl.DateTimeFormat("ko-KR", {
        day: "numeric",
        month: "long",
        year: "numeric",
      }).format(new Date(card.photo.createdAt))
    : "예시 카드";

  return (
    <Pressable
      accessibilityRole="button"
      style={({ pressed }) => [styles.card, pressed && styles.pressed]}
    >
      <View style={styles.imageFrame}>
        {card.photo ? (
          <Image source={{ uri: card.photo.uri }} style={styles.cardImage} />
        ) : (
          <View style={styles.sampleImage}>
            <View style={styles.sampleMarker} />
            <Text numberOfLines={1} style={styles.sampleImageText}>
              {card.region.name}
            </Text>
          </View>
        )}
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
  sampleImage: {
    alignItems: "center",
    backgroundColor: "#F8FBFF",
    gap: 10,
    height: "100%",
    justifyContent: "center",
    overflow: "hidden",
    paddingHorizontal: 18,
    width: "100%",
  },
  sampleImageText: {
    color: "#007AFF",
    fontSize: 20,
    fontWeight: "800",
    maxWidth: "100%",
  },
  sampleMarker: {
    backgroundColor: "#007AFF",
    borderRadius: 18,
    height: 36,
    opacity: 0.16,
    width: 36,
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

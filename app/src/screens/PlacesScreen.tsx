import { Image } from "expo-image";
import { useMemo, useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { MAP_ASSETS } from "@/features/map/models/mapAssets";
import type { MapMode, MapRegion, RegionPhoto } from "@/features/map/models/map.types";
import { useMapUiStore } from "@/features/map/store/mapUi.store";

type PlaceFilter = "korea" | "world";

type PlaceCard = {
  id: string;
  mode: MapMode;
  photo?: RegionPhoto;
  region: MapRegion;
};

const sampleCards: PlaceCard[] = [
  {
    id: "sample-korea-seoul",
    mode: "korea",
    region: MAP_ASSETS.korea.regions[0],
  },
  {
    id: "sample-korea-second",
    mode: "korea",
    region: MAP_ASSETS.korea.regions[1],
  },
  {
    id: "sample-world-first",
    mode: "world",
    region: MAP_ASSETS.world.regions[0],
  },
];

export function PlacesScreen() {
  const insets = useSafeAreaInsets();
  const [filter, setFilter] = useState<PlaceFilter>("korea");
  const regionPhotos = useMapUiStore((state) => state.regionPhotos);

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

    return [...photoCards, ...sampleCards].filter(({ mode }) => mode === filter);
  }, [filter, regionPhotos]);

  return (
    <View style={styles.container}>
      <View style={[styles.header, { paddingTop: insets.top + 20 }]}>
        <Text style={styles.title}>장소</Text>
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
      {card.photo ? (
        <Image source={{ uri: card.photo.uri }} style={styles.cardImage} />
      ) : (
        <View style={styles.sampleImage}>
          <Text style={styles.sampleImageText}>{card.region.name}</Text>
        </View>
      )}
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
    gap: 10,
  },
  cardBody: {
    gap: 3,
  },
  cardImage: {
    aspectRatio: 1.18,
    backgroundColor: "#F1F5F9",
    borderRadius: 8,
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
    fontSize: 13,
  },
  filterButton: {
    alignItems: "center",
    borderRadius: 8,
    flex: 1,
    height: 36,
    justifyContent: "center",
  },
  filterButtonSelected: {
    backgroundColor: "#FFFFFF",
  },
  filterText: {
    color: "#71717A",
    fontSize: 14,
    fontWeight: "700",
  },
  filterTextSelected: {
    color: "#18181B",
  },
  header: {
    gap: 18,
    paddingBottom: 16,
    paddingHorizontal: 20,
  },
  list: {
    gap: 26,
    paddingHorizontal: 20,
  },
  locationText: {
    color: "#3F3F46",
    fontSize: 14,
    fontWeight: "600",
  },
  modeLabel: {
    color: "#71717A",
    fontSize: 12,
    fontWeight: "700",
  },
  pressed: {
    opacity: 0.78,
  },
  regionName: {
    color: "#18181B",
    flex: 1,
    fontSize: 17,
    fontWeight: "800",
  },
  sampleImage: {
    alignItems: "center",
    aspectRatio: 1.18,
    backgroundColor: "#F1F5F9",
    borderRadius: 8,
    justifyContent: "center",
    overflow: "hidden",
    width: "100%",
  },
  sampleImageText: {
    color: "#94A3B8",
    fontSize: 24,
    fontWeight: "800",
  },
  segmentedControl: {
    backgroundColor: "#F1F5F9",
    borderRadius: 10,
    flexDirection: "row",
    gap: 4,
    padding: 4,
  },
  title: {
    color: "#18181B",
    fontSize: 28,
    fontWeight: "800",
  },
});

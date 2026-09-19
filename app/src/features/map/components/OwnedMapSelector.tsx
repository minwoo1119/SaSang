import { router, type Href } from "expo-router";
import {
  Check,
  ChevronDown,
  Map as MapIcon,
  Plus,
  X,
} from "lucide-react-native";
import { useRef, useState } from "react";
import {
  Animated,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { getOwnedMap, OWNED_MAPS } from "../models/mapCatalog";
import type { MapMode } from "../models/map.types";
import { MapPreview } from "./MapPreview";

type Props = {
  onChange: (mode: MapMode) => void;
  value: MapMode;
};

export function OwnedMapSelector({ onChange, value }: Props) {
  const insets = useSafeAreaInsets();
  const [visible, setVisible] = useState(false);
  const backdropOpacity = useRef(new Animated.Value(0)).current;
  const sheetTranslateY = useRef(new Animated.Value(420)).current;
  const currentMap = getOwnedMap(value);

  const openSelector = () => {
    backdropOpacity.setValue(0);
    sheetTranslateY.setValue(420);
    setVisible(true);

    requestAnimationFrame(() => {
      Animated.sequence([
        Animated.timing(backdropOpacity, {
          duration: 90,
          toValue: 1,
          useNativeDriver: true,
        }),
        Animated.spring(sheetTranslateY, {
          bounciness: 0,
          speed: 18,
          toValue: 0,
          useNativeDriver: true,
        }),
      ]).start();
    });
  };

  const closeSelector = (onClosed?: () => void) => {
    Animated.parallel([
      Animated.timing(backdropOpacity, {
        duration: 150,
        toValue: 0,
        useNativeDriver: true,
      }),
      Animated.timing(sheetTranslateY, {
        duration: 180,
        toValue: 420,
        useNativeDriver: true,
      }),
    ]).start(({ finished }) => {
      if (!finished) return;
      setVisible(false);
      onClosed?.();
    });
  };

  const selectMap = (mode: MapMode) => {
    onChange(mode);
    closeSelector();
  };

  const openStore = () => {
    closeSelector(() => router.push("/map-store" as Href));
  };

  return (
    <>
      <Pressable
        accessibilityLabel={`현재 지도 ${currentMap.name}. 지도 변경`}
        accessibilityRole="button"
        onPress={openSelector}
        style={({ pressed }) => [styles.trigger, pressed && styles.pressed]}
      >
        <MapIcon color="#007AFF" size={16} strokeWidth={2.3} />
        <Text numberOfLines={1} style={styles.triggerText}>
          {currentMap.name}
        </Text>
        <ChevronDown color="#52525B" size={16} strokeWidth={2.4} />
      </Pressable>

      <Modal
        animationType="none"
        onRequestClose={() => closeSelector()}
        presentationStyle="overFullScreen"
        transparent
        visible={visible}
      >
        <View style={styles.modalRoot}>
          <Animated.View
            style={[styles.backdrop, { opacity: backdropOpacity }]}
          >
            <Pressable
              accessibilityLabel="내 지도 닫기"
              onPress={() => closeSelector()}
              style={StyleSheet.absoluteFill}
            />
          </Animated.View>
          <Animated.View
            style={[
              styles.sheet,
              {
                paddingBottom: Math.max(insets.bottom, 16),
                transform: [{ translateY: sheetTranslateY }],
              },
            ]}
          >
            <View style={styles.sheetHeader}>
              <View>
                <Text style={styles.sheetTitle}>내 지도</Text>
                <Text style={styles.sheetSubtitle}>보유한 지도</Text>
              </View>
              <Pressable
                accessibilityLabel="닫기"
                accessibilityRole="button"
                hitSlop={8}
                onPress={() => closeSelector()}
                style={({ pressed }) => [
                  styles.closeButton,
                  pressed && styles.pressed,
                ]}
              >
                <X color="#52525B" size={20} />
              </Pressable>
            </View>

            <View style={styles.mapGrid}>
              {OWNED_MAPS.map((map) => {
                const selected = map.id === value;
                return (
                  <Pressable
                    accessibilityRole="radio"
                    accessibilityState={{ checked: selected }}
                    key={map.id}
                    onPress={() => selectMap(map.id)}
                    style={({ pressed }) => [
                      styles.mapCard,
                      selected && styles.selectedMapCard,
                      pressed && styles.pressed,
                    ]}
                  >
                    <View style={styles.previewWrap}>
                      <MapPreview mode={map.id} selected={selected} />
                      {selected ? (
                        <View style={styles.checkBadge}>
                          <Check color="#FFFFFF" size={13} strokeWidth={3} />
                        </View>
                      ) : null}
                    </View>
                    <Text numberOfLines={1} style={styles.mapName}>
                      {map.name}
                    </Text>
                    <Text numberOfLines={1} style={styles.mapDescription}>
                      {map.description}
                    </Text>
                  </Pressable>
                );
              })}
            </View>

            <Pressable
              accessibilityRole="button"
              onPress={openStore}
              style={({ pressed }) => [
                styles.storeButton,
                pressed && styles.storeButtonPressed,
              ]}
            >
              <Plus color="#007AFF" size={19} strokeWidth={2.5} />
              <Text style={styles.storeButtonText}>새로운 지도 둘러보기</Text>
            </Pressable>
          </Animated.View>
        </View>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    backgroundColor: "rgba(0, 0, 0, 0.3)",
    bottom: 0,
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  checkBadge: {
    alignItems: "center",
    backgroundColor: "#007AFF",
    borderRadius: 11,
    height: 22,
    justifyContent: "center",
    position: "absolute",
    right: 7,
    top: 7,
    width: 22,
  },
  closeButton: {
    alignItems: "center",
    backgroundColor: "#F4F4F5",
    borderRadius: 8,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  mapCard: {
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.09)",
    borderRadius: 8,
    borderWidth: StyleSheet.hairlineWidth,
    flex: 1,
    minWidth: 0,
    overflow: "hidden",
    paddingBottom: 12,
  },
  mapDescription: {
    color: "#71717A",
    fontSize: 11,
    marginTop: 3,
    paddingHorizontal: 11,
  },
  mapGrid: {
    flexDirection: "row",
    gap: 10,
  },
  mapName: {
    color: "#18181B",
    fontSize: 14,
    fontWeight: "800",
    marginTop: 10,
    paddingHorizontal: 11,
  },
  modalRoot: {
    flex: 1,
    justifyContent: "flex-end",
  },
  pressed: { opacity: 0.7 },
  previewWrap: { position: "relative" },
  selectedMapCard: {
    borderColor: "#007AFF",
    borderWidth: 1.5,
  },
  sheet: {
    backgroundColor: "#FAFAFA",
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    gap: 18,
    paddingHorizontal: 18,
    paddingTop: 18,
  },
  sheetHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  sheetSubtitle: {
    color: "#71717A",
    fontSize: 12,
    marginTop: 3,
  },
  sheetTitle: {
    color: "#18181B",
    fontSize: 22,
    fontWeight: "800",
  },
  storeButton: {
    alignItems: "center",
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 122, 255, 0.25)",
    borderRadius: 8,
    borderWidth: 1,
    flexDirection: "row",
    gap: 7,
    height: 50,
    justifyContent: "center",
  },
  storeButtonPressed: { backgroundColor: "#EFF7FF" },
  storeButtonText: {
    color: "#007AFF",
    fontSize: 15,
    fontWeight: "800",
  },
  trigger: {
    alignItems: "center",
    backgroundColor: "rgba(255, 255, 255, 0.92)",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 19,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 7,
    height: 38,
    maxWidth: 168,
    paddingHorizontal: 12,
  },
  triggerText: {
    color: "#27272A",
    flexShrink: 1,
    fontSize: 13,
    fontWeight: "800",
  },
});

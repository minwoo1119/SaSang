import { useCallback, useEffect, useMemo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from "react-native-reanimated";
import Svg, { Path } from "react-native-svg";
import { MAP_ASSETS } from "../models/mapAssets";
import type { MapMode, MapRegion } from "../models/map.types";
import {
  getRegionPhotoKey,
  useMapUiStore,
} from "../store/mapUi.store";
import { MapGlassSurface } from "./MapGlassSurface";
import { RegionPath } from "./RegionPath";
import { RegionPhotoLayer } from "./RegionPhotoLayer";

const MIN_SCALE = 0.85;
const MAX_SCALE = 5;
const SPRING_CONFIG = { damping: 18, stiffness: 180 };

function clamp(value: number, minimum: number, maximum: number) {
  "worklet";
  return Math.min(Math.max(value, minimum), maximum);
}

type InteractiveRegionMapProps = {
  mode: MapMode;
  visitedRegionCodes?: ReadonlySet<string>;
};

export function InteractiveRegionMap({
  mode,
  visitedRegionCodes = new Set(),
}: InteractiveRegionMapProps) {
  const map = MAP_ASSETS[mode];
  const selectedRegionCode = useMapUiStore((state) => state.selectedRegionCode);
  const selectRegion = useMapUiStore((state) => state.selectRegion);
  const regionPhotos = useMapUiStore((state) => state.regionPhotos);
  const scale = useSharedValue(1);
  const startScale = useSharedValue(1);
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const startX = useSharedValue(0);
  const startY = useSharedValue(0);
  const viewportWidth = useSharedValue(0);
  const viewportHeight = useSharedValue(0);

  const photoRegionCodes = useMemo(
    () =>
      new Set(
        map.regions
          .filter((region) => regionPhotos[getRegionPhotoKey(mode, region.code)])
          .map((region) => region.code),
      ),
    [map.regions, mode, regionPhotos],
  );
  const selectedRegion = useMemo(
    () => map.regions.find(({ code }) => code === selectedRegionCode),
    [map.regions, selectedRegionCode],
  );

  const resetViewport = useCallback(() => {
    scale.value = withSpring(1, SPRING_CONFIG);
    translateX.value = withSpring(0, SPRING_CONFIG);
    translateY.value = withSpring(0, SPRING_CONFIG);
  }, [scale, translateX, translateY]);

  useEffect(() => {
    resetViewport();
  }, [mode, resetViewport]);

  const handlePress = useCallback(
    (region: MapRegion) => selectRegion(region.code),
    [selectRegion],
  );

  const panGesture = Gesture.Pan()
    .minDistance(5)
    .onBegin(() => {
      startX.value = translateX.value;
      startY.value = translateY.value;
    })
    .onUpdate((event) => {
      const maxX = viewportWidth.value * Math.max(scale.value - 0.65, 0.24);
      const maxY = viewportHeight.value * Math.max(scale.value - 0.65, 0.24);
      translateX.value = clamp(startX.value + event.translationX, -maxX, maxX);
      translateY.value = clamp(startY.value + event.translationY, -maxY, maxY);
    });

  const pinchGesture = Gesture.Pinch()
    .onBegin(() => {
      startScale.value = scale.value;
    })
    .onUpdate((event) => {
      scale.value = clamp(startScale.value * event.scale, MIN_SCALE, MAX_SCALE);
    })
    .onEnd(() => {
      if (scale.value < 1) {
        scale.value = withSpring(1, SPRING_CONFIG);
        translateX.value = withSpring(0, SPRING_CONFIG);
        translateY.value = withSpring(0, SPRING_CONFIG);
      }
    });

  const mapGesture = Gesture.Simultaneous(panGesture, pinchGesture);
  const animatedMapStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
      { scale: scale.value },
    ],
  }));

  const zoomBy = useCallback(
    (amount: number) => {
      const nextScale = clamp(scale.value + amount, 1, MAX_SCALE);
      scale.value = withSpring(nextScale, SPRING_CONFIG);
      if (nextScale === 1) {
        translateX.value = withSpring(0, SPRING_CONFIG);
        translateY.value = withSpring(0, SPRING_CONFIG);
      }
    },
    [scale, translateX, translateY],
  );

  return (
    <View
      onLayout={({ nativeEvent }) => {
        viewportWidth.value = nativeEvent.layout.width;
        viewportHeight.value = nativeEvent.layout.height;
      }}
      style={styles.container}
    >
      <GestureDetector gesture={mapGesture}>
        <Animated.View style={[styles.map, animatedMapStyle]}>
          <Svg
            accessibilityLabel={
              mode === "korea" ? "대한민국 시군구 지도" : "세계 국가 지도"
            }
            height="100%"
            preserveAspectRatio="xMidYMid meet"
            viewBox={`0 0 ${map.viewBox.width} ${map.viewBox.height}`}
            width="100%"
          >
            <RegionPhotoLayer
              mode={mode}
              regionPhotos={regionPhotos}
              regions={map.regions}
            />
            {map.regions.map((region) => {
              const photoFilled = photoRegionCodes.has(region.code);
              return (
                <RegionPath
                  key={region.code}
                  onPress={handlePress}
                  photoFilled={photoFilled}
                  region={region}
                  selected={selectedRegionCode === region.code}
                  visited={photoFilled || visitedRegionCodes.has(region.code)}
                />
              );
            })}
            {selectedRegion ? (
              <Path
                d={selectedRegion.path}
                fill="transparent"
                pointerEvents="none"
                stroke="#007AFF"
                strokeLinejoin="round"
                strokeWidth={1.45}
                vectorEffect="non-scaling-stroke"
              />
            ) : null}
          </Svg>
        </Animated.View>
      </GestureDetector>

      <MapGlassSurface style={styles.zoomControls}>
        <Pressable
          accessibilityLabel="지도 확대"
          accessibilityRole="button"
          onPress={() => zoomBy(0.6)}
          style={({ pressed }) => [styles.zoomButton, pressed && styles.pressed]}
        >
          <Text style={styles.zoomIcon}>＋</Text>
        </Pressable>
        <View style={styles.separator} />
        <Pressable
          accessibilityLabel="지도 축소"
          accessibilityRole="button"
          onPress={() => zoomBy(-0.6)}
          style={({ pressed }) => [styles.zoomButton, pressed && styles.pressed]}
        >
          <Text style={styles.zoomIcon}>−</Text>
        </Pressable>
        <View style={styles.separator} />
        <Pressable
          accessibilityLabel="지도 위치 초기화"
          accessibilityRole="button"
          onPress={resetViewport}
          style={({ pressed }) => [styles.zoomButton, pressed && styles.pressed]}
        >
          <Text style={styles.resetText}>1:1</Text>
        </Pressable>
      </MapGlassSurface>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, overflow: "hidden", width: "100%" },
  map: { height: "100%", width: "100%" },
  pressed: { backgroundColor: "rgba(39, 37, 33, 0.08)" },
  resetText: { color: "#5F5B54", fontSize: 11, fontWeight: "700" },
  separator: {
    alignSelf: "center",
    backgroundColor: "rgba(39, 37, 33, 0.1)",
    height: StyleSheet.hairlineWidth,
    width: 24,
  },
  zoomButton: {
    alignItems: "center",
    height: 44,
    justifyContent: "center",
    width: 44,
  },
  zoomControls: {
    borderRadius: 24,
    overflow: "hidden",
    position: "absolute",
    right: 12,
    top: 106,
  },
  zoomIcon: {
    color: "#272521",
    fontSize: 23,
    fontWeight: "400",
    lineHeight: 25,
  },
});

import { useCallback, useEffect, useMemo } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";
import Svg, { Path } from "react-native-svg";
import { MAP_ASSETS } from "../models/mapAssets";
import type { MapMode, MapRegion } from "../models/map.types";
import { getRegionPhotoKey, useMapUiStore } from "../store/mapUi.store";
import { MapGlassSurface } from "./MapGlassSurface";
import { RegionPath } from "./RegionPath";
import { RegionPhotoLayer } from "./RegionPhotoLayer";

const MIN_SCALE = 0.85;
const MAX_SCALE = 5;
const SMOOTH_CONFIG = { duration: 160, easing: Easing.out(Easing.quad) };

function clamp(value: number, minimum: number, maximum: number) {
  "worklet";
  return Math.min(Math.max(value, minimum), maximum);
}

type InteractiveRegionMapProps = {
  mode: MapMode;
  visitedRegionCodes?: ReadonlySet<string>;
  zoomControlsBottom?: number;
};

export function InteractiveRegionMap({
  mode,
  visitedRegionCodes = new Set(),
  zoomControlsBottom = 24,
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
          .filter(
            (region) => regionPhotos[getRegionPhotoKey(mode, region.code)],
          )
          .map((region) => region.code),
      ),
    [map.regions, mode, regionPhotos],
  );
  const selectedRegion = useMemo(
    () => map.regions.find(({ code }) => code === selectedRegionCode),
    [map.regions, selectedRegionCode],
  );

  const setInitialViewport = useCallback(
    (targetMode: MapMode, animate = true) => {
      const w = viewportWidth.value || 360;
      const h = viewportHeight.value || 600;

      let targetScale = 1;
      let targetX = 0;
      let targetY = 0;

      if (targetMode === "world") {
        targetScale = 3.4;
        targetX = -w * 0.85;
        targetY = h * 0.15;
      }

      if (animate) {
        scale.value = withTiming(targetScale, SMOOTH_CONFIG);
        translateX.value = withTiming(targetX, SMOOTH_CONFIG);
        translateY.value = withTiming(targetY, SMOOTH_CONFIG);
      } else {
        scale.value = targetScale;
        translateX.value = targetX;
        translateY.value = targetY;
      }
    },
    [scale, translateX, translateY, viewportWidth, viewportHeight],
  );

  const resetViewport = useCallback(() => {
    scale.value = withTiming(1, SMOOTH_CONFIG);
    translateX.value = withTiming(0, SMOOTH_CONFIG);
    translateY.value = withTiming(0, SMOOTH_CONFIG);
  }, [scale, translateX, translateY]);

  useEffect(() => {
    setInitialViewport(mode, true);
  }, [mode, setInitialViewport]);

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
      startX.value = translateX.value;
      startY.value = translateY.value;
    })
    .onUpdate((event) => {
      const nextScale = clamp(
        startScale.value * event.scale,
        MIN_SCALE,
        MAX_SCALE,
      );
      const factor = startScale.value > 0 ? nextScale / startScale.value : 1;
      scale.value = nextScale;
      translateX.value = startX.value * factor;
      translateY.value = startY.value * factor;
    })
    .onEnd(() => {
      if (scale.value < 1) {
        scale.value = withTiming(1, SMOOTH_CONFIG);
        translateX.value = withTiming(0, SMOOTH_CONFIG);
        translateY.value = withTiming(0, SMOOTH_CONFIG);
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
      const currentScale = scale.value;
      const nextScale = clamp(currentScale + amount, 1, MAX_SCALE);
      if (nextScale === currentScale) return;

      if (nextScale === 1) {
        scale.value = withTiming(1, SMOOTH_CONFIG);
        translateX.value = withTiming(0, SMOOTH_CONFIG);
        translateY.value = withTiming(0, SMOOTH_CONFIG);
      } else {
        const factor = nextScale / currentScale;
        const rawNextX = translateX.value * factor;
        const rawNextY = translateY.value * factor;
        const maxX = viewportWidth.value * Math.max(nextScale - 0.65, 0.24);
        const maxY = viewportHeight.value * Math.max(nextScale - 0.65, 0.24);

        scale.value = withTiming(nextScale, SMOOTH_CONFIG);
        translateX.value = withTiming(
          clamp(rawNextX, -maxX, maxX),
          SMOOTH_CONFIG,
        );
        translateY.value = withTiming(
          clamp(rawNextY, -maxY, maxY),
          SMOOTH_CONFIG,
        );
      }
    },
    [scale, translateX, translateY, viewportWidth, viewportHeight],
  );

  return (
    <View
      onLayout={({ nativeEvent }) => {
        const isFirst = viewportWidth.value === 0;
        viewportWidth.value = nativeEvent.layout.width;
        viewportHeight.value = nativeEvent.layout.height;
        if (isFirst) {
          setInitialViewport(mode);
        }
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
                  mode={mode}
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
                strokeWidth={mode === "world" ? 0.9 : 1.45}
                vectorEffect="non-scaling-stroke"
              />
            ) : null}
          </Svg>
        </Animated.View>
      </GestureDetector>

      <MapGlassSurface
        style={[styles.zoomControls, { bottom: zoomControlsBottom }]}
      >
        <Pressable
          accessibilityLabel="지도 확대"
          accessibilityRole="button"
          onPress={() => zoomBy(0.6)}
          style={({ pressed }) => [
            styles.zoomButton,
            pressed && styles.pressed,
          ]}
        >
          <Text style={styles.zoomIcon}>＋</Text>
        </Pressable>
        <View style={styles.separator} />
        <Pressable
          accessibilityLabel="지도 축소"
          accessibilityRole="button"
          onPress={() => zoomBy(-0.6)}
          style={({ pressed }) => [
            styles.zoomButton,
            pressed && styles.pressed,
          ]}
        >
          <Text style={styles.zoomIcon}>−</Text>
        </Pressable>
        <View style={styles.separator} />
        <Pressable
          accessibilityLabel="지도 위치 초기화"
          accessibilityRole="button"
          onPress={resetViewport}
          style={({ pressed }) => [
            styles.zoomButton,
            pressed && styles.pressed,
          ]}
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
  pressed: { backgroundColor: "rgba(0, 122, 255, 0.08)" },
  resetText: { color: "#007AFF", fontSize: 11, fontWeight: "800" },
  separator: {
    alignSelf: "center",
    backgroundColor: "rgba(0, 0, 0, 0.08)",
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
    backgroundColor: "#FFFFFF",
    borderColor: "rgba(0, 0, 0, 0.08)",
    borderRadius: 24,
    borderWidth: StyleSheet.hairlineWidth,
    bottom: 24,
    overflow: "hidden",
    position: "absolute",
    right: 12,
  },
  zoomIcon: {
    color: "#007AFF",
    fontSize: 23,
    fontWeight: "500",
    lineHeight: 25,
  },
});

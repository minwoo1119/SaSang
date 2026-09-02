import { useCallback, useEffect, useMemo, useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  Easing,
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";
import Svg, { G, Path, Rect } from "react-native-svg";
import { MAP_ASSETS } from "../models/mapAssets";
import type { MapMode, MapRegion } from "../models/map.types";
import { getRegionPhotoKey, useMapUiStore } from "../store/mapUi.store";
import { MapGlassSurface } from "./MapGlassSurface";
import { RegionPath } from "./RegionPath";
import { RegionPhotoLayer } from "./RegionPhotoLayer";

const MIN_SCALE = 0.85;
const MAX_SCALE = 5;
const SMOOTH_CONFIG = { duration: 160, easing: Easing.out(Easing.quad) };
const WORLD_INITIAL_REGION_CODE = "KR";

type Point = { x: number; y: number };
type Polygon = Point[];

function clamp(value: number, minimum: number, maximum: number) {
  "worklet";
  return Math.min(Math.max(value, minimum), maximum);
}

function parsePathPolygons(path: string): Polygon[] {
  const tokens = path.match(/[MLZ]|-?\d+(?:\.\d+)?/g) ?? [];
  const polygons: Polygon[] = [];
  let current: Polygon = [];
  let index = 0;

  while (index < tokens.length) {
    const token = tokens[index++];

    if (token === "M" || token === "L") {
      const x = Number(tokens[index++]);
      const y = Number(tokens[index++]);
      if (!Number.isFinite(x) || !Number.isFinite(y)) continue;

      if (token === "M" && current.length > 0) {
        polygons.push(current);
        current = [];
      }
      current.push({ x, y });
    } else if (token === "Z" && current.length > 0) {
      polygons.push(current);
      current = [];
    }
  }

  if (current.length > 0) {
    polygons.push(current);
  }

  return polygons.filter((polygon) => polygon.length >= 3);
}

function containsPoint(polygon: Polygon, point: Point) {
  let inside = false;

  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const pi = polygon[i];
    const pj = polygon[j];
    const crosses =
      pi.y > point.y !== pj.y > point.y &&
      point.x < ((pj.x - pi.x) * (point.y - pi.y)) / (pj.y - pi.y) + pi.x;

    if (crosses) {
      inside = !inside;
    }
  }

  return inside;
}

function isInsideBounds(region: MapRegion, point: Point) {
  return (
    point.x >= region.bounds.x &&
    point.x <= region.bounds.x + region.bounds.width &&
    point.y >= region.bounds.y &&
    point.y <= region.bounds.y + region.bounds.height
  );
}

function getRegionCenter(region: MapRegion) {
  return {
    x: region.bounds.x + region.bounds.width / 2,
    y: region.bounds.y + region.bounds.height / 2,
  };
}

function getWorldMinimumScale(
  viewportWidth: number,
  viewportHeight: number,
  mapWidth: number,
  mapHeight: number,
) {
  "worklet";

  if (viewportWidth <= 0 || viewportHeight <= 0) return 1;

  const fittedScale = Math.min(
    viewportWidth / mapWidth,
    viewportHeight / mapHeight,
  );
  const renderedHeight = mapHeight * fittedScale;

  if (renderedHeight <= 0) return 1;

  return Math.min(Math.max(viewportHeight / renderedHeight, 1), MAX_SCALE);
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
  const [viewportSize, setViewportSize] = useState({ height: 0, width: 0 });

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
  const worldInitialRegion = useMemo(
    () => map.regions.find(({ code }) => code === WORLD_INITIAL_REGION_CODE),
    [map.regions],
  );
  const regionPolygons = useMemo(
    () =>
      map.regions.map((region) => ({
        polygons: parsePathPolygons(region.path),
        region,
      })),
    [map.regions],
  );

  const setInitialViewport = useCallback(
    (targetMode: MapMode, animate = true) => {
      const viewportW = viewportWidth.value;
      const viewportH = viewportHeight.value;
      const fittedScale = Math.min(
        viewportW / map.viewBox.width || 1,
        viewportH / map.viewBox.height || 1,
      );
      let targetScale = 1;
      let targetX = 0;
      let targetY = 0;

      if (targetMode === "world" && worldInitialRegion) {
        const centerX = map.viewBox.width / 2;
        const centerY = map.viewBox.height / 2;
        const targetCenter = getRegionCenter(worldInitialRegion);
        targetScale = getWorldMinimumScale(
          viewportW,
          viewportH,
          map.viewBox.width,
          map.viewBox.height,
        );
        targetX = (centerX - targetCenter.x) * fittedScale * targetScale;
        targetY = (centerY - targetCenter.y) * fittedScale * targetScale;
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
    [
      map.viewBox.height,
      map.viewBox.width,
      scale,
      translateX,
      translateY,
      viewportHeight,
      viewportWidth,
      worldInitialRegion,
    ],
  );

  const resetViewport = useCallback(() => {
    setInitialViewport(mode, true);
  }, [mode, setInitialViewport]);

  useEffect(() => {
    setInitialViewport(mode, true);
  }, [mode, setInitialViewport]);

  const handleMapTap = useCallback(
    (x: number, y: number) => {
      const { height, width } = viewportSize;
      if (width <= 0 || height <= 0) return;

      const fittedScale = Math.min(
        width / map.viewBox.width,
        height / map.viewBox.height,
      );
      const renderedWidth = map.viewBox.width * fittedScale;
      const renderedHeight = map.viewBox.height * fittedScale;
      const contentX = x - (width - renderedWidth) / 2;
      const contentY = y - (height - renderedHeight) / 2;

      if (
        contentX < 0 ||
        contentX > renderedWidth ||
        contentY < 0 ||
        contentY > renderedHeight
      ) {
        selectRegion(null);
        return;
      }

      const centerX = map.viewBox.width / 2;
      const centerY = map.viewBox.height / 2;
      const viewBoxTranslateX = translateX.value / fittedScale;
      const viewBoxTranslateY = translateY.value / fittedScale;
      const basePoint = {
        x: contentX / fittedScale,
        y: contentY / fittedScale,
      };
      const mapPoint = {
        x:
          centerX +
          (basePoint.x - centerX - viewBoxTranslateX) / scale.value,
        y:
          centerY +
          (basePoint.y - centerY - viewBoxTranslateY) / scale.value,
      };

      const match = regionPolygons.find(
        ({ polygons, region }) =>
          isInsideBounds(region, mapPoint) &&
          polygons.some((polygon) => containsPoint(polygon, mapPoint)),
      );

      selectRegion(match?.region.code ?? null);
    },
    [
      map.viewBox.height,
      map.viewBox.width,
      regionPolygons,
      scale,
      selectRegion,
      translateX,
      translateY,
      viewportSize,
    ],
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
      const worldMinimumScale = getWorldMinimumScale(
        viewportWidth.value,
        viewportHeight.value,
        map.viewBox.width,
        map.viewBox.height,
      );
      const minimumScale = mode === "world" ? worldMinimumScale : MIN_SCALE;
      const nextScale = clamp(
        startScale.value * event.scale,
        minimumScale,
        MAX_SCALE,
      );
      const factor = startScale.value > 0 ? nextScale / startScale.value : 1;
      scale.value = nextScale;
      translateX.value = startX.value * factor;
      translateY.value = startY.value * factor;
    })
    .onEnd(() => {
      const worldMinimumScale = getWorldMinimumScale(
        viewportWidth.value,
        viewportHeight.value,
        map.viewBox.width,
        map.viewBox.height,
      );

      if (mode === "world" && scale.value < worldMinimumScale) {
        scale.value = withTiming(worldMinimumScale, SMOOTH_CONFIG);
      } else if (mode !== "world" && scale.value < 1) {
        scale.value = withTiming(1, SMOOTH_CONFIG);
        translateX.value = withTiming(0, SMOOTH_CONFIG);
        translateY.value = withTiming(0, SMOOTH_CONFIG);
      }
    });

  const tapGesture = Gesture.Tap()
    .maxDistance(8)
    .onEnd((event, success) => {
      if (success) {
        runOnJS(handleMapTap)(event.x, event.y);
      }
    });
  const mapGesture = Gesture.Simultaneous(panGesture, pinchGesture, tapGesture);

  const animatedMapStyle = useAnimatedStyle(() => {
    return {
      transform: [
        { translateX: translateX.value },
        { translateY: translateY.value },
        { scale: scale.value },
      ],
    };
  });

  const zoomBy = useCallback(
    (amount: number) => {
      const currentScale = scale.value;
      const worldMinimumScale = getWorldMinimumScale(
        viewportWidth.value,
        viewportHeight.value,
        map.viewBox.width,
        map.viewBox.height,
      );
      const minimumScale = mode === "world" ? worldMinimumScale : 1;
      const nextScale = clamp(currentScale + amount, minimumScale, MAX_SCALE);
      if (nextScale === currentScale) return;

      if (nextScale === minimumScale) {
        setInitialViewport(mode, true);
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
    [
      map.viewBox.height,
      map.viewBox.width,
      mode,
      scale,
      setInitialViewport,
      translateX,
      translateY,
      viewportHeight,
      viewportWidth,
    ],
  );

  return (
    <View
      onLayout={({ nativeEvent }) => {
        const isFirst = viewportWidth.value === 0;
        viewportWidth.value = nativeEvent.layout.width;
        viewportHeight.value = nativeEvent.layout.height;
        setViewportSize({
          height: nativeEvent.layout.height,
          width: nativeEvent.layout.width,
        });
        if (isFirst) {
          setInitialViewport(mode);
        }
      }}
      style={styles.container}
    >
      <GestureDetector gesture={mapGesture}>
        <View style={styles.map}>
          <Animated.View style={[styles.mapContent, animatedMapStyle]}>
            <Svg
              accessibilityLabel={
                mode === "korea" ? "대한민국 시군구 지도" : "세계 국가 지도"
              }
              height="100%"
              preserveAspectRatio="xMidYMid meet"
              viewBox={`0 0 ${map.viewBox.width} ${map.viewBox.height}`}
              width="100%"
            >
              <G>
                <Rect
                  fill="transparent"
                  height={map.viewBox.height}
                  pointerEvents="none"
                  width={map.viewBox.width}
                  x={0}
                  y={0}
                />
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
                      photoFilled={photoFilled}
                      region={region}
                      selected={selectedRegionCode === region.code}
                      visited={
                        photoFilled || visitedRegionCodes.has(region.code)
                      }
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
                    strokeWidth={mode === "world" ? 0.32 : 1.1}
                    vectorEffect="non-scaling-stroke"
                  />
                ) : null}
              </G>
            </Svg>
          </Animated.View>
        </View>
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
  mapContent: { height: "100%", width: "100%" },
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

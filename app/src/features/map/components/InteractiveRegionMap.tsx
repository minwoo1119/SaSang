import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Svg, { G, Path, Rect } from "react-native-svg";
import { MAP_ASSETS } from "../models/mapAssets";
import type { MapMode, MapRegion } from "../models/map.types";
import { getRegionPhotoKey, useMapUiStore } from "../store/mapUi.store";
import { MapGlassSurface } from "./MapGlassSurface";
import { RegionPath } from "./RegionPath";
import { RegionPhotoLayer } from "./RegionPhotoLayer";

const MIN_SCALE = 0.85;
const MAX_SCALE = 5;
const WORLD_INITIAL_REGION_CODE = "KR";

type Point = { x: number; y: number };
type Polygon = Point[];
type ViewBox = { height: number; width: number; x: number; y: number };
type ViewportSize = { height: number; width: number };

function clamp(value: number, minimum: number, maximum: number) {
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
  if (viewportWidth <= 0 || viewportHeight <= 0) return 1;

  const fittedScale = Math.min(
    viewportWidth / mapWidth,
    viewportHeight / mapHeight,
  );
  const renderedHeight = mapHeight * fittedScale;

  if (renderedHeight <= 0) return 1;

  return Math.min(Math.max(viewportHeight / renderedHeight, 1), MAX_SCALE);
}

function getViewBoxScale(viewBox: ViewBox, mapWidth: number) {
  return mapWidth / viewBox.width;
}

function clampViewBox(viewBox: ViewBox, mapWidth: number, mapHeight: number) {
  const width = Math.min(viewBox.width, mapWidth);
  const height = Math.min(viewBox.height, mapHeight);

  return {
    height,
    width,
    x: clamp(viewBox.x, 0, mapWidth - width),
    y: clamp(viewBox.y, 0, mapHeight - height),
  };
}

function getViewBoxForScale(
  currentViewBox: ViewBox,
  nextScale: number,
  mapWidth: number,
  mapHeight: number,
) {
  const centerX = currentViewBox.x + currentViewBox.width / 2;
  const centerY = currentViewBox.y + currentViewBox.height / 2;
  const aspectRatio = currentViewBox.width / currentViewBox.height;
  const width = mapWidth / nextScale;
  const height = width / aspectRatio;

  return clampViewBox(
    {
      height,
      width,
      x: centerX - width / 2,
      y: centerY - height / 2,
    },
    mapWidth,
    mapHeight,
  );
}

function getInitialViewBox(
  mode: MapMode,
  mapWidth: number,
  mapHeight: number,
  viewport: ViewportSize,
  initialRegion?: MapRegion,
) {
  if (
    mode !== "world" ||
    viewport.width <= 0 ||
    viewport.height <= 0 ||
    !initialRegion
  ) {
    return { height: mapHeight, width: mapWidth, x: 0, y: 0 };
  }

  const viewportRatio = viewport.width / viewport.height;
  const mapRatio = mapWidth / mapHeight;
  const targetCenter = getRegionCenter(initialRegion);

  if (viewportRatio < mapRatio) {
    const width = mapHeight * viewportRatio;
    return clampViewBox(
      {
        height: mapHeight,
        width,
        x: targetCenter.x - width / 2,
        y: 0,
      },
      mapWidth,
      mapHeight,
    );
  }

  const height = mapWidth / viewportRatio;
  return clampViewBox(
    {
      height,
      width: mapWidth,
      x: 0,
      y: targetCenter.y - height / 2,
    },
    mapWidth,
    mapHeight,
  );
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
  const [viewportSize, setViewportSize] = useState<ViewportSize>({
    height: 0,
    width: 0,
  });
  const [viewBox, setViewBox] = useState<ViewBox>({
    height: map.viewBox.height,
    width: map.viewBox.width,
    x: 0,
    y: 0,
  });
  const viewBoxRef = useRef(viewBox);
  const startViewBoxRef = useRef(viewBox);
  const viewportSizeRef = useRef(viewportSize);

  const updateViewBox = useCallback((nextViewBox: ViewBox) => {
    viewBoxRef.current = nextViewBox;
    setViewBox(nextViewBox);
  }, []);

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
    (targetMode: MapMode, size = viewportSize) => {
      updateViewBox(
        getInitialViewBox(
          targetMode,
          map.viewBox.width,
          map.viewBox.height,
          size,
          worldInitialRegion,
        ),
      );
    },
    [
      map.viewBox.height,
      map.viewBox.width,
      updateViewBox,
      viewportSize,
      worldInitialRegion,
    ],
  );

  const resetViewport = useCallback(() => {
    setInitialViewport(mode);
  }, [mode, setInitialViewport]);

  useEffect(() => {
    setInitialViewport(mode);
  }, [mode, setInitialViewport]);

  const handleMapTap = useCallback(
    (x: number, y: number) => {
      const { height, width } = viewportSize;
      if (width <= 0 || height <= 0) return;

      const currentViewBox = viewBoxRef.current;
      const fittedScale = Math.min(
        width / currentViewBox.width,
        height / currentViewBox.height,
      );
      const renderedWidth = currentViewBox.width * fittedScale;
      const renderedHeight = currentViewBox.height * fittedScale;
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

      const mapPoint = {
        x: currentViewBox.x + contentX / fittedScale,
        y: currentViewBox.y + contentY / fittedScale,
      };

      const match = regionPolygons.find(
        ({ polygons, region }) =>
          isInsideBounds(region, mapPoint) &&
          polygons.some((polygon) => containsPoint(polygon, mapPoint)),
      );

      selectRegion(match?.region.code ?? null);
    },
    [regionPolygons, selectRegion, viewportSize],
  );

  const panGesture = Gesture.Pan()
    .runOnJS(true)
    .minDistance(5)
    .onBegin(() => {
      startViewBoxRef.current = viewBoxRef.current;
    })
    .onUpdate((event) => {
      const startViewBox = startViewBoxRef.current;
      const fittedScale = Math.min(
        viewportSize.width / startViewBox.width,
        viewportSize.height / startViewBox.height,
      );
      if (!Number.isFinite(fittedScale) || fittedScale <= 0) return;

      updateViewBox(
        clampViewBox(
          {
            ...startViewBox,
            x: startViewBox.x - event.translationX / fittedScale,
            y: startViewBox.y - event.translationY / fittedScale,
          },
          map.viewBox.width,
          map.viewBox.height,
        ),
      );
    });

  const pinchGesture = Gesture.Pinch()
    .runOnJS(true)
    .onBegin(() => {
      startViewBoxRef.current = viewBoxRef.current;
    })
    .onUpdate((event) => {
      const startViewBox = startViewBoxRef.current;
      const startScale = getViewBoxScale(startViewBox, map.viewBox.width);
      const minimumScale =
        mode === "world"
          ? getWorldMinimumScale(
              viewportSize.width,
              viewportSize.height,
              map.viewBox.width,
              map.viewBox.height,
            )
          : MIN_SCALE;
      const nextScale = clamp(
        startScale * event.scale,
        minimumScale,
        MAX_SCALE,
      );
      updateViewBox(
        getViewBoxForScale(
          startViewBox,
          nextScale,
          map.viewBox.width,
          map.viewBox.height,
        ),
      );
    })
    .onEnd(() => {
      if (
        mode !== "world" &&
        getViewBoxScale(viewBoxRef.current, map.viewBox.width) < 1
      ) {
        resetViewport();
      }
    });

  const tapGesture = Gesture.Tap()
    .maxDistance(8)
    .onEnd((event, success) => {
      if (success) {
        handleMapTap(event.x, event.y);
      }
    });
  const mapGesture = Gesture.Simultaneous(panGesture, pinchGesture, tapGesture);

  const zoomBy = useCallback(
    (amount: number) => {
      const currentViewBox = viewBoxRef.current;
      const currentScale = getViewBoxScale(currentViewBox, map.viewBox.width);
      const minimumScale =
        mode === "world"
          ? getWorldMinimumScale(
              viewportSize.width,
              viewportSize.height,
              map.viewBox.width,
              map.viewBox.height,
            )
          : 1;
      const nextScale = clamp(currentScale + amount, minimumScale, MAX_SCALE);
      if (nextScale === currentScale) return;

      if (nextScale === minimumScale) {
        resetViewport();
      } else {
        updateViewBox(
          getViewBoxForScale(
            currentViewBox,
            nextScale,
            map.viewBox.width,
            map.viewBox.height,
          ),
        );
      }
    },
    [
      map.viewBox.height,
      map.viewBox.width,
      mode,
      resetViewport,
      updateViewBox,
      viewportSize,
    ],
  );

  return (
    <View
      onLayout={({ nativeEvent }) => {
        const nextViewportSize = {
          height: nativeEvent.layout.height,
          width: nativeEvent.layout.width,
        };
        const currentViewportSize = viewportSizeRef.current;
        if (
          currentViewportSize.height === nextViewportSize.height &&
          currentViewportSize.width === nextViewportSize.width
        ) {
          return;
        }

        viewportSizeRef.current = nextViewportSize;
        setViewportSize(nextViewportSize);
        updateViewBox(
          getInitialViewBox(
            mode,
            map.viewBox.width,
            map.viewBox.height,
            nextViewportSize,
            worldInitialRegion,
          ),
        );
      }}
      style={styles.container}
    >
      <GestureDetector gesture={mapGesture}>
        <View style={styles.map}>
          <Svg
            accessibilityLabel={
              mode === "korea" ? "대한민국 시군구 지도" : "세계 국가 지도"
            }
            height="100%"
            preserveAspectRatio="xMidYMid meet"
            viewBox={`${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`}
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
                  strokeWidth={mode === "world" ? 0.32 : 1.1}
                  vectorEffect="non-scaling-stroke"
                />
              ) : null}
            </G>
          </Svg>
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

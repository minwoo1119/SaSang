import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Platform, Pressable, StyleSheet, Text, View } from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Svg, { G, Path, Rect } from "react-native-svg";
import { MAP_ASSETS } from "../models/mapAssets";
import type { MapMode, MapRegion } from "../models/map.types";
import { getRegionPhotoKey, useMapUiStore } from "../store/mapUi.store";
import { MapGlassSurface } from "./MapGlassSurface";
import { RegionPath } from "./RegionPath";
import { RegionPhotoLayer } from "./RegionPhotoLayer";

const WORLD_INITIAL_REGION_CODE = "KR";
const MAX_SCALE = 12;

type Point = { x: number; y: number };
type Polygon = Point[];
type RegionPolygons = { polygons: Polygon[]; region: MapRegion };
type ViewBox = { height: number; width: number; x: number; y: number };
type ViewportSize = { height: number; width: number };

function clamp(value: number, minimum: number, maximum: number) {
  return Math.min(Math.max(value, minimum), maximum);
}

function getFullViewBox(width: number, height: number): ViewBox {
  return { height, width, x: 0, y: 0 };
}

function getRegionCenter(region: MapRegion | undefined, fallback: ViewBox) {
  if (!region) {
    return {
      x: fallback.x + fallback.width / 2,
      y: fallback.y + fallback.height / 2,
    };
  }

  return {
    x: region.bounds.x + region.bounds.width / 2,
    y: region.bounds.y + region.bounds.height / 2,
  };
}

function clampViewBox(viewBox: ViewBox, mapWidth: number, mapHeight: number) {
  const width = viewBox.width;
  const height = viewBox.height;
  const minX = width >= mapWidth ? (mapWidth - width) / 2 : 0;
  const maxX = width >= mapWidth ? minX : mapWidth - width;
  const minY = height >= mapHeight ? (mapHeight - height) / 2 : 0;
  const maxY = height >= mapHeight ? minY : mapHeight - height;

  return {
    height,
    width,
    x: clamp(viewBox.x, minX, maxX),
    y: clamp(viewBox.y, minY, maxY),
  };
}

function expandViewBoxToAspect(viewBox: ViewBox, aspectRatio: number) {
  const currentAspectRatio = viewBox.width / viewBox.height;
  if (!Number.isFinite(aspectRatio) || aspectRatio <= 0) return viewBox;

  if (currentAspectRatio < aspectRatio) {
    const width = viewBox.height * aspectRatio;
    return {
      ...viewBox,
      width,
      x: viewBox.x - (width - viewBox.width) / 2,
    };
  }

  const height = viewBox.width / aspectRatio;
  return {
    ...viewBox,
    height,
    y: viewBox.y - (height - viewBox.height) / 2,
  };
}

function getInitialViewBox(
  mode: MapMode,
  mapWidth: number,
  mapHeight: number,
  viewport: ViewportSize,
  initialRegion?: MapRegion,
) {
  const fullViewBox = getFullViewBox(mapWidth, mapHeight);
  if (
    viewport.width <= 0 ||
    viewport.height <= 0 ||
    mapWidth <= 0 ||
    mapHeight <= 0
  ) {
    return fullViewBox;
  }

  const viewportRatio = viewport.width / viewport.height;
  if (mode !== "world") {
    return clampViewBox(
      expandViewBoxToAspect(fullViewBox, viewportRatio),
      mapWidth,
      mapHeight,
    );
  }

  const mapRatio = mapWidth / mapHeight;
  const center = getRegionCenter(initialRegion, fullViewBox);

  if (viewportRatio < mapRatio) {
    const width = mapHeight * viewportRatio;
    return clampViewBox(
      {
        height: mapHeight,
        width,
        x: center.x - width / 2,
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
      y: center.y - height / 2,
    },
    mapWidth,
    mapHeight,
  );
}

function getViewBoxScale(viewBox: ViewBox, mapWidth: number) {
  return mapWidth / viewBox.width;
}

function getViewBoxForScale(
  sourceViewBox: ViewBox,
  scale: number,
  mapWidth: number,
  mapHeight: number,
) {
  const aspectRatio = sourceViewBox.width / sourceViewBox.height;
  const width = mapWidth / scale;
  const height = width / aspectRatio;
  const centerX = sourceViewBox.x + sourceViewBox.width / 2;
  const centerY = sourceViewBox.y + sourceViewBox.height / 2;

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

function findRegionAtPoint(
  point: Point,
  regionPolygons: readonly RegionPolygons[],
) {
  return regionPolygons.find(
    ({ polygons, region }) =>
      isInsideBounds(region, point) &&
      polygons.some((polygon) => containsPoint(polygon, point)),
  );
}

function getMapPointFromScreenPoint(
  point: Point,
  viewBox: ViewBox,
  viewport: ViewportSize,
) {
  return {
    x: viewBox.x + (point.x / viewport.width) * viewBox.width,
    y: viewBox.y + (point.y / viewport.height) * viewBox.height,
  };
}

function getKoreaTapSampleOffsets() {
  return [
    { weight: 5, x: 0, y: 0 },
    { weight: 2, x: 5, y: 0 },
    { weight: 2, x: -5, y: 0 },
    { weight: 2, x: 0, y: 5 },
    { weight: 2, x: 0, y: -5 },
    { weight: 1, x: 8, y: 8 },
    { weight: 1, x: 8, y: -8 },
    { weight: 1, x: -8, y: 8 },
    { weight: 1, x: -8, y: -8 },
  ] as const;
}

function findKoreaRegionFromTapArea(
  point: Point,
  viewBox: ViewBox,
  viewport: ViewportSize,
  regionPolygons: readonly RegionPolygons[],
) {
  const scores = new Map<string, { region: MapRegion; score: number }>();

  for (const offset of getKoreaTapSampleOffsets()) {
    const mapPoint = getMapPointFromScreenPoint(
      { x: point.x + offset.x, y: point.y + offset.y },
      viewBox,
      viewport,
    );
    const match = findRegionAtPoint(mapPoint, regionPolygons);

    if (!match) continue;

    const current = scores.get(match.region.code);
    scores.set(match.region.code, {
      region: match.region,
      score: (current?.score ?? 0) + offset.weight,
    });
  }

  let bestMatch: { region: MapRegion; score: number } | undefined;
  for (const match of scores.values()) {
    if (!bestMatch || match.score > bestMatch.score) {
      bestMatch = match;
    }
  }

  return bestMatch?.region;
}

type InteractiveRegionMapProps = {
  mode: MapMode;
  onMapInteraction?: () => void;
  visitedRegionCodes?: ReadonlySet<string>;
  zoomControlsBottom?: number;
};

export function InteractiveRegionMap({
  mode,
  onMapInteraction,
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
  const [viewBox, setViewBox] = useState<ViewBox>(() =>
    getFullViewBox(map.viewBox.width, map.viewBox.height),
  );
  const viewportSizeRef = useRef(viewportSize);
  const viewBoxRef = useRef(viewBox);
  const startViewBoxRef = useRef(viewBox);

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
  const initialViewBox = useMemo(
    () =>
      getInitialViewBox(
        mode,
        map.viewBox.width,
        map.viewBox.height,
        viewportSize,
        worldInitialRegion,
      ),
    [
      map.viewBox.height,
      map.viewBox.width,
      mode,
      viewportSize,
      worldInitialRegion,
    ],
  );
  const regionPolygons = useMemo(
    () =>
      map.regions.map((region) => ({
        polygons: parsePathPolygons(region.path),
        region,
      })),
    [map.regions],
  );

  const updateViewBox = useCallback((nextViewBox: ViewBox) => {
    viewBoxRef.current = nextViewBox;
    setViewBox(nextViewBox);
  }, []);

  const resetViewport = useCallback(() => {
    updateViewBox(initialViewBox);
  }, [initialViewBox, updateViewBox]);

  useEffect(() => {
    updateViewBox(initialViewBox);
  }, [initialViewBox, updateViewBox]);

  const handleMapTap = useCallback(
    (x: number, y: number) => {
      onMapInteraction?.();
      const viewport = viewportSizeRef.current;
      if (
        viewport.width <= 0 ||
        viewport.height <= 0 ||
        x < 0 ||
        x > viewport.width ||
        y < 0 ||
        y > viewport.height
      ) {
        selectRegion(null);
        return;
      }

      const currentViewBox = viewBoxRef.current;
      const mapPoint = getMapPointFromScreenPoint(
        { x, y },
        currentViewBox,
        viewport,
      );
      const matchedRegion =
        mode === "korea" && Platform.OS === "android"
          ? findKoreaRegionFromTapArea(
              { x, y },
              currentViewBox,
              viewport,
              regionPolygons,
            )
          : findRegionAtPoint(mapPoint, regionPolygons)?.region;

      selectRegion(matchedRegion?.code ?? null);
    },
    [mode, onMapInteraction, regionPolygons, selectRegion],
  );

  const panGesture = Gesture.Pan()
    .minDistance(5)
    .runOnJS(true)
    .onBegin(() => {
      onMapInteraction?.();
      startViewBoxRef.current = viewBoxRef.current;
    })
    .onUpdate((event) => {
      const startViewBox = startViewBoxRef.current;
      const viewport = viewportSizeRef.current;
      if (viewport.width <= 0 || viewport.height <= 0) return;

      updateViewBox(
        clampViewBox(
          {
            ...startViewBox,
            x:
              startViewBox.x -
              (event.translationX / viewport.width) * startViewBox.width,
            y:
              startViewBox.y -
              (event.translationY / viewport.height) * startViewBox.height,
          },
          map.viewBox.width,
          map.viewBox.height,
        ),
      );
    });

  const pinchGesture = Gesture.Pinch()
    .runOnJS(true)
    .onBegin(() => {
      onMapInteraction?.();
      startViewBoxRef.current = viewBoxRef.current;
    })
    .onUpdate((event) => {
      const startViewBox = startViewBoxRef.current;
      const startScale = getViewBoxScale(startViewBox, map.viewBox.width);
      const minimumScale = getViewBoxScale(initialViewBox, map.viewBox.width);
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
    });

  const tapGesture = Gesture.Tap()
    .maxDistance(8)
    .runOnJS(true)
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
      const minimumScale = getViewBoxScale(initialViewBox, map.viewBox.width);
      const nextScale = clamp(currentScale + amount, minimumScale, MAX_SCALE);
      if (nextScale === currentScale) return;

      updateViewBox(
        getViewBoxForScale(
          currentViewBox,
          nextScale,
          map.viewBox.width,
          map.viewBox.height,
        ),
      );
    },
    [
      initialViewBox,
      map.viewBox.height,
      map.viewBox.width,
      updateViewBox,
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
          currentViewportSize.width === nextViewportSize.width &&
          currentViewportSize.height === nextViewportSize.height
        ) {
          return;
        }

        viewportSizeRef.current = nextViewportSize;
        setViewportSize(nextViewportSize);
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
            preserveAspectRatio="none"
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

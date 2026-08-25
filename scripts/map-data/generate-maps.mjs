import { readFileSync } from "node:fs";
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const KOREA_INPUT = new URL(
  "./sources/korea-sigungu-2025-2q.geojson",
  import.meta.url,
);
const WORLD_INPUT = new URL(
  "./sources/natural-earth-admin0-5.1.2.geojson",
  import.meta.url,
);
const KOREA_CODES = JSON.parse(
  readFileSync(
    new URL("./sources/korea-official-code-map-2025.json", import.meta.url),
    "utf8",
  ),
).regions;
const KOREA_OUTPUT = new URL(
  "../../app/src/assets/maps/korea/regions.json",
  import.meta.url,
);
const WORLD_OUTPUT = new URL(
  "../../app/src/assets/maps/world/countries.json",
  import.meta.url,
);

const MERGED_METROPOLITAN_CITY_CODES = new Set([
  "26",
  "27",
  "28",
  "29",
  "30",
  "31",
]);

const shouldDissolveMergedGeometry = (config) =>
  Boolean(config.mergeByProvinceCodes || config.mergeCityDistricts);

export const MAP_CONFIGS = {
  korea: {
    viewBox: { width: 360, height: 520, padding: 12 },
    codePattern: /^\d{5}$/,
    regionProperties: KOREA_CODES,
    mergeByProvinceCodes: MERGED_METROPOLITAN_CITY_CODES,
    mergeCityDistricts: true,
    metadata: {
      version: "sgis-sigungu-2025-2q-v3",
      generatedAt: "2025-06-30T00:00:00.000Z",
      source:
        "https://www.data.go.kr/data/15129688/fileData.do (bnd_sigungu_00_2025_2Q)",
      license: "이용허락범위 제한 없음",
      referenceDate: "2025 Q2",
      identifierPolicy:
        "Official five-digit legal-district prefix from code.go.kr; Busan, Daegu, Incheon, Gwangju, Daejeon, and Ulsan are represented by their five-digit metropolitan-city codes; non-metropolitan cities split into districts named '{city} {district-gu}' are represented by the parent city code with shared district boundaries dissolved",
      excludedFeatures: [],
    },
  },
  world: {
    viewBox: { width: 720, height: 360, padding: 10 },
    codePattern: /^[A-Z]{2}$/,
    regionProperties: null,
    metadata: {
      version: "natural-earth-admin0-5.1.2-110m-v1",
      generatedAt: "2026-05-13T00:00:00.000Z",
      source:
        "https://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_countries.zip",
      license: "CC0-1.0 / public domain",
      referenceDate: "Natural Earth 5.1.2",
      identifierPolicy:
        "ISO 3166-1 alpha-2 (ISO_A2_EH); features without an ISO code are excluded",
      excludedFeatures: ["Turkish Republic of Northern Cyprus", "Somaliland"],
    },
  },
};

function polygonsFromGeometry(geometry) {
  if (geometry.type === "Polygon") return [geometry.coordinates];
  if (geometry.type === "MultiPolygon") return geometry.coordinates;
  throw new Error(`Unsupported geometry type: ${geometry.type}`);
}

function pointKey([x, y]) {
  return `${x},${y}`;
}

function edgeKey(start, end) {
  const startKey = pointKey(start);
  const endKey = pointKey(end);
  return startKey < endKey ? `${startKey}|${endKey}` : `${endKey}|${startKey}`;
}

function dissolvePolygons(polygons) {
  const edgesByKey = new Map();
  for (const polygon of polygons) {
    for (const ring of polygon) {
      for (let index = 0; index < ring.length - 1; index += 1) {
        const start = ring[index];
        const end = ring[index + 1];
        if (pointKey(start) === pointKey(end)) continue;
        const key = edgeKey(start, end);
        const edges = edgesByKey.get(key) ?? [];
        edges.push({ start, end });
        edgesByKey.set(key, edges);
      }
    }
  }

  const exteriorEdges = [...edgesByKey.values()]
    .filter((edges) => edges.length === 1)
    .map(([edge]) => edge);
  const unused = new Set(exteriorEdges.map((_, index) => index));
  const edgesFromPoint = new Map();
  for (const [index, edge] of exteriorEdges.entries()) {
    const startKey = pointKey(edge.start);
    const edges = edgesFromPoint.get(startKey) ?? [];
    edges.push(index);
    edgesFromPoint.set(startKey, edges);
  }

  const rings = [];
  while (unused.size > 0) {
    const firstIndex = unused.values().next().value;
    const firstEdge = exteriorEdges[firstIndex];
    unused.delete(firstIndex);

    const ring = [firstEdge.start, firstEdge.end];
    const ringStartKey = pointKey(firstEdge.start);
    let cursorKey = pointKey(firstEdge.end);

    while (cursorKey !== ringStartKey) {
      const nextIndex = (edgesFromPoint.get(cursorKey) ?? []).find((index) =>
        unused.has(index),
      );
      if (nextIndex === undefined) {
        throw new Error("Unable to dissolve adjacent map polygons.");
      }
      const nextEdge = exteriorEdges[nextIndex];
      unused.delete(nextIndex);
      ring.push(nextEdge.end);
      cursorKey = pointKey(nextEdge.end);
    }

    rings.push(ring);
  }

  return rings.map((ring) => [ring]);
}

function formatNumber(value) {
  return Number(value.toFixed(2)).toString();
}

function mergedFeature(code, properties, polygons, config) {
  const coordinates = shouldDissolveMergedGeometry(config)
    ? dissolvePolygons(polygons)
    : polygons;
  return {
    geometry: {
      type: coordinates.length === 1 ? "Polygon" : "MultiPolygon",
      coordinates:
        coordinates.length === 1 ? coordinates[0] : coordinates,
    },
    properties,
  };
}

function normalizeFeatures(source, config) {
  const normalized = source.features.map(({ geometry, properties }) => ({
    geometry,
    properties: config.regionProperties?.[properties.code] ?? properties,
  }));

  let features = normalized;
  if (config.mergeByProvinceCodes) {
    const merged = new Map();
    const retained = [];
    for (const feature of features) {
      const { provinceCode, provinceName } = feature.properties;
      if (!config.mergeByProvinceCodes.has(provinceCode)) {
        retained.push(feature);
        continue;
      }
      const code = `${provinceCode}000`;
      const current = merged.get(code) ?? {
        polygons: [],
        properties: { code, name: provinceName },
      };
      current.polygons.push(...polygonsFromGeometry(feature.geometry));
      merged.set(code, current);
    }
    features = [
      ...retained,
      ...[...merged.entries()].map(([code, { properties, polygons }]) =>
        mergedFeature(code, properties, polygons, config),
      ),
    ];
  }

  if (!config.mergeCityDistricts) return features;

  const cityMerged = new Map();
  const cityRetained = [];
  for (const feature of features) {
    const { code, name, provinceCode, provinceName } = feature.properties;
    const cityMatch = /^(.+시)\s+.+구$/.exec(name);
    if (!cityMatch) {
      cityRetained.push(feature);
      continue;
    }
    const cityName = cityMatch[1];
    const cityCode = `${code.slice(0, 4)}0`;
    const current = cityMerged.get(cityCode) ?? {
      polygons: [],
      properties: {
        code: cityCode,
        name: cityName,
        provinceCode,
        provinceName,
      },
    };
    current.polygons.push(...polygonsFromGeometry(feature.geometry));
    cityMerged.set(cityCode, current);
  }
  return [
    ...cityRetained,
    ...[...cityMerged.entries()].map(([code, { properties, polygons }]) =>
      mergedFeature(code, properties, polygons, config),
    ),
  ];
}

export function generateMap(source, config) {
  if (source.type !== "FeatureCollection") {
    throw new Error("Map source must be a GeoJSON FeatureCollection.");
  }
  const includedFeatures = normalizeFeatures(source, config).filter(
    ({ properties }) => config.codePattern.test(properties.code),
  );
  const points = includedFeatures.flatMap(({ geometry }) =>
    polygonsFromGeometry(geometry).flat(2),
  );
  const minX = Math.min(...points.map(([x]) => x));
  const maxX = Math.max(...points.map(([x]) => x));
  const minY = Math.min(...points.map(([, y]) => y));
  const maxY = Math.max(...points.map(([, y]) => y));
  const { width, height, padding } = config.viewBox;
  const scale = Math.min(
    (width - padding * 2) / (maxX - minX),
    (height - padding * 2) / (maxY - minY),
  );
  const originX = (width - (maxX - minX) * scale) / 2;
  const originY = (height - (maxY - minY) * scale) / 2;
  const project = ([x, y]) => [
    originX + (x - minX) * scale,
    originY + (maxY - y) * scale,
  ];
  const regions = includedFeatures
    .map(({ geometry, properties }) => {
      if (
        typeof properties.code !== "string" ||
        typeof properties.name !== "string" ||
        properties.name.length === 0
      ) {
        throw new Error("Every region requires a code and name.");
      }
      const polygons = polygonsFromGeometry(geometry);
      const projectedPoints = polygons.flat(2).map(project);
      const projectedXs = projectedPoints.map(([x]) => x);
      const projectedYs = projectedPoints.map(([, y]) => y);
      const bounds = {
        x: Number(Math.min(...projectedXs).toFixed(2)),
        y: Number(Math.min(...projectedYs).toFixed(2)),
        width: Number(
          (Math.max(...projectedXs) - Math.min(...projectedXs)).toFixed(2),
        ),
        height: Number(
          (Math.max(...projectedYs) - Math.min(...projectedYs)).toFixed(2),
        ),
      };
      const path = polygons
        .flatMap((polygon) => polygon)
        .map(
          (ring) =>
            ring
              .map((coordinate, index) => {
                const [x, y] = project(coordinate);
                return `${index === 0 ? "M" : "L"}${formatNumber(x)} ${formatNumber(y)}`;
              })
              .join(" ") + " Z",
        )
        .join(" ");
      return {
        code: properties.code,
        name: properties.name,
        ...(properties.provinceCode
          ? {
              provinceCode: properties.provinceCode,
              provinceName: properties.provinceName,
            }
          : {}),
        geometryType: geometry.type,
        polygonCount: polygons.length,
        bounds,
        path,
      };
    })
    .sort((left, right) => left.code.localeCompare(right.code));
  if (new Set(regions.map(({ code }) => code)).size !== regions.length) {
    throw new Error("Duplicate region codes are not allowed.");
  }
  return {
    notice: "THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
    metadata: config.metadata,
    viewBox: config.viewBox,
    regions,
  };
}

async function load(url) {
  return JSON.parse(await readFile(url, "utf8"));
}

async function main() {
  const [koreaSource, worldSource] = await Promise.all([
    load(KOREA_INPUT),
    load(WORLD_INPUT),
  ]);
  await Promise.all([
    writeFile(
      KOREA_OUTPUT,
      `${JSON.stringify(generateMap(koreaSource, MAP_CONFIGS.korea))}\n`,
      "utf8",
    ),
    writeFile(
      WORLD_OUTPUT,
      `${JSON.stringify(generateMap(worldSource, MAP_CONFIGS.world))}\n`,
      "utf8",
    ),
  ]);
  console.log("Generated Korea and world map assets.");
}

if (process.argv[1] === fileURLToPath(import.meta.url)) await main();

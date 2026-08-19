import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const DEFAULT_INPUT = new URL(
  "./sources/seoul-municipalities-2015.geojson",
  import.meta.url,
);
const DEFAULT_OUTPUT = new URL(
  "../../app/src/assets/maps/korea/seoul.json",
  import.meta.url,
);

export const VIEWBOX = { width: 360, height: 300, padding: 12 };

function ringsFromGeometry(geometry) {
  if (geometry.type === "Polygon") return geometry.coordinates;
  if (geometry.type === "MultiPolygon") return geometry.coordinates.flat();
  throw new Error(`Unsupported geometry type: ${geometry.type}`);
}

function formatNumber(value) {
  return Number(value.toFixed(2)).toString();
}

export function generateSeoulMap(source) {
  if (source.type !== "FeatureCollection" || source.features.length !== 25) {
    throw new Error("Seoul source must contain exactly 25 district features.");
  }

  const coordinates = source.features.flatMap((feature) =>
    ringsFromGeometry(feature.geometry).flatMap((ring) => ring),
  );
  const longitudes = coordinates.map(([longitude]) => longitude);
  const latitudes = coordinates.map(([, latitude]) => latitude);
  const bounds = {
    minX: Math.min(...longitudes),
    maxX: Math.max(...longitudes),
    minY: Math.min(...latitudes),
    maxY: Math.max(...latitudes),
  };
  const scale = Math.min(
    (VIEWBOX.width - VIEWBOX.padding * 2) / (bounds.maxX - bounds.minX),
    (VIEWBOX.height - VIEWBOX.padding * 2) / (bounds.maxY - bounds.minY),
  );
  const renderedWidth = (bounds.maxX - bounds.minX) * scale;
  const renderedHeight = (bounds.maxY - bounds.minY) * scale;
  const originX = (VIEWBOX.width - renderedWidth) / 2;
  const originY = (VIEWBOX.height - renderedHeight) / 2;
  const project = ([longitude, latitude]) => [
    originX + (longitude - bounds.minX) * scale,
    originY + (bounds.maxY - latitude) * scale,
  ];

  const regions = source.features
    .map((feature) => {
      const code = feature.properties.SIG_CD;
      const name = feature.properties.SIG_KOR_NM;
      if (typeof code !== "string" || typeof name !== "string") {
        throw new Error("Every district requires SIG_CD and SIG_KOR_NM.");
      }
      const path = ringsFromGeometry(feature.geometry)
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
      return { code, name, path };
    })
    .sort((a, b) => a.code.localeCompare(b.code));

  if (new Set(regions.map(({ code }) => code)).size !== regions.length) {
    throw new Error("Duplicate district codes are not allowed.");
  }

  return {
    notice: "THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
    metadata: {
      version: "seoul-juso-2015-v1",
      generatedAt: "2015-12-31T00:00:00.000Z",
      source: "https://github.com/southkorea/seoul-maps/tree/master/juso/2015",
      license: "Apache-2.0",
    },
    viewBox: VIEWBOX,
    regions,
  };
}

async function main() {
  const source = JSON.parse(await readFile(DEFAULT_INPUT, "utf8"));
  await writeFile(
    DEFAULT_OUTPUT,
    `${JSON.stringify(generateSeoulMap(source), null, 2)}\n`,
    "utf8",
  );
  console.log(`Generated ${DEFAULT_OUTPUT.pathname}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) await main();

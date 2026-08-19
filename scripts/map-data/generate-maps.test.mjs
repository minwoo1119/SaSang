import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { generateMap, MAP_CONFIGS } from "./generate-maps.mjs";

const load = async (name) =>
  JSON.parse(
    await readFile(new URL(`./sources/${name}`, import.meta.url), "utf8"),
  );
const koreaSource = await load("korea-sigungu-2025-2q.geojson");
const worldSource = await load("natural-earth-admin0-5.1.2.geojson");

function assertValidMap(map, codePattern) {
  assert.ok(map.regions.length > 0);
  assert.equal(
    new Set(map.regions.map(({ code }) => code)).size,
    map.regions.length,
  );
  for (const region of map.regions) {
    assert.match(region.code, codePattern);
    assert.ok(region.name.length > 0);
    assert.match(region.path, /^M/);
    assert.match(region.path, / Z$/);
    assert.ok(region.polygonCount >= 1);
    assert.ok(["Polygon", "MultiPolygon"].includes(region.geometryType));
    if (region.geometryType === "MultiPolygon") {
      assert.ok(region.polygonCount > 1);
    }
  }
}

test("generates every Korea district with a stable five-digit code", () => {
  const result = generateMap(koreaSource, MAP_CONFIGS.korea);
  assert.equal(result.regions.length, 252);
  assertValidMap(result, /^\d{5}$/);
  assert.equal(
    result.regions.find(({ name }) => name === "강남구")?.code,
    "11680",
  );
  assert.equal(
    result.regions.find(({ name }) => name === "종로구")?.code,
    "11110",
  );
  assert.ok(result.regions.some(({ geometryType }) => geometryType === "MultiPolygon"));
  assert.deepEqual(
    result.regions.map(({ geometryType, polygonCount }) => ({
      geometryType,
      polygonCount,
    })),
    koreaSource.features
      .map(({ geometry, properties }) => ({
        code: MAP_CONFIGS.korea.regionProperties[properties.code].code,
        geometryType: geometry.type,
        polygonCount:
          geometry.type === "MultiPolygon" ? geometry.coordinates.length : 1,
      }))
      .sort((left, right) => left.code.localeCompare(right.code))
      .map(({ geometryType, polygonCount }) => ({ geometryType, polygonCount })),
  );
});

test("generates world countries with ISO alpha-2 codes", () => {
  const result = generateMap(worldSource, MAP_CONFIGS.world);
  assert.equal(result.regions.length, 175);
  assertValidMap(result, /^[A-Z]{2}$/);
  assert.ok(result.regions.some(({ geometryType }) => geometryType === "MultiPolygon"));
  assert.deepEqual(result.metadata.excludedFeatures, [
    "Turkish Republic of Northern Cyprus",
    "Somaliland",
  ]);
});

test("generation is deterministic", () => {
  assert.deepEqual(
    generateMap(koreaSource, MAP_CONFIGS.korea),
    generateMap(koreaSource, MAP_CONFIGS.korea),
  );
  assert.deepEqual(
    generateMap(worldSource, MAP_CONFIGS.world),
    generateMap(worldSource, MAP_CONFIGS.world),
  );
});

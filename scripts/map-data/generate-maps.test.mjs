import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { generateMap, MAP_CONFIGS } from "./generate-maps.mjs";

const load = (name) =>
  JSON.parse(
    readFileSync(new URL(`./sources/${name}`, import.meta.url), "utf8"),
  );
const koreaSource = load("korea-sigungu-2025-2q.geojson");
const worldSource = load("natural-earth-admin0-5.1.2.geojson");

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
    assert.ok(Number.isFinite(region.bounds.x));
    assert.ok(Number.isFinite(region.bounds.y));
    assert.ok(region.bounds.width > 0);
    assert.ok(region.bounds.height > 0);
    assert.ok(["Polygon", "MultiPolygon"].includes(region.geometryType));
    if (region.geometryType === "MultiPolygon") {
      assert.ok(region.polygonCount > 1);
    }
  }
}

test("generates every Korea district with a stable five-digit code", () => {
  const result = generateMap(koreaSource, MAP_CONFIGS.korea);
  assert.equal(result.regions.length, 185);
  assertValidMap(result, /^\d{5}$/);
  assert.equal(
    result.regions.find(({ name }) => name === "강남구")?.code,
    "11680",
  );
  assert.equal(
    result.regions.find(({ name }) => name === "종로구")?.code,
    "11110",
  );
  const mergedCities = [
    ["26000", "부산광역시", "MultiPolygon", 218],
    ["27000", "대구광역시", "MultiPolygon", 9],
    ["28000", "인천광역시", "MultiPolygon", 695],
    ["29000", "광주광역시", "MultiPolygon", 5],
    ["30000", "대전광역시", "MultiPolygon", 3],
    ["31000", "울산광역시", "MultiPolygon", 447],
  ];
  for (const [code, name, geometryType, polygonCount] of mergedCities) {
    const city = result.regions.find((region) => region.code === code);
    assert.equal(city?.name, name);
    assert.equal(city?.geometryType, geometryType);
    assert.equal(city?.polygonCount, polygonCount);
  }
  assert.equal(
    result.regions.filter(({ provinceCode }) =>
      ["26", "27", "28", "29", "30", "31"].includes(provinceCode),
    ).length,
    0,
  );
  const mergedDistrictCities = [
    ["41110", "수원시", "MultiPolygon", 3],
    ["41130", "성남시", "MultiPolygon", 2],
    ["41170", "안양시", "Polygon", 1],
    ["41190", "부천시", "MultiPolygon", 2],
    ["41270", "안산시", "MultiPolygon", 26],
    ["41280", "고양시", "MultiPolygon", 3],
    ["41460", "용인시", "MultiPolygon", 4],
    ["43110", "청주시", "MultiPolygon", 3],
    ["44130", "천안시", "MultiPolygon", 2],
    ["47110", "포항시", "MultiPolygon", 290],
    ["48120", "창원시", "MultiPolygon", 62],
    ["52110", "전주시", "MultiPolygon", 2],
  ];
  for (const [code, name, geometryType, polygonCount] of mergedDistrictCities) {
    const city = result.regions.find((region) => region.code === code);
    assert.equal(city?.name, name);
    assert.equal(city?.geometryType, geometryType);
    assert.equal(city?.polygonCount, polygonCount);
  }
  assert.deepEqual(
    result.regions
      .filter(({ name }) => /시 .*구$/.test(name))
      .map(({ name }) => name),
    [],
  );
  assert.ok(
    result.regions.some(({ geometryType }) => geometryType === "MultiPolygon"),
  );
});

test("generates world countries with ISO alpha-2 codes", () => {
  const result = generateMap(worldSource, MAP_CONFIGS.world);
  assert.equal(result.regions.length, 175);
  assertValidMap(result, /^[A-Z]{2}$/);
  assert.ok(
    result.regions.some(({ geometryType }) => geometryType === "MultiPolygon"),
  );
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

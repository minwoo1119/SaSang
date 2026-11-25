import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { generateMap, MAP_CONFIGS } from "./generate-maps.mjs";

const load = (name) =>
  JSON.parse(
    readFileSync(new URL(`./sources/${name}`, import.meta.url), "utf8"),
  );
const koreaSource = load("korea-sigungu-2025-2q.geojson");
const koreaLocalizations = load("korea-region-localizations.json");
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
    assert.ok(Number.isFinite(region.anchor.x));
    assert.ok(Number.isFinite(region.anchor.y));
    assert.ok(region.anchorBounds.width > 0);
    assert.ok(region.anchorBounds.height > 0);
    assert.ok(region.anchorBounds.width <= region.bounds.width);
    assert.ok(region.anchorBounds.height <= region.bounds.height);
    assert.ok(["Polygon", "MultiPolygon"].includes(region.geometryType));
    if (region.geometryType === "MultiPolygon") {
      assert.ok(region.polygonCount > 1);
    }
  }
}

test("generates every Korea district with a stable five-digit code", () => {
  const result = generateMap(koreaSource, MAP_CONFIGS.korea);
  assert.equal(result.regions.length, 161);
  assertValidMap(result, /^\d{5}$/);
  assert.equal(
    result.regions.find(({ name }) => name === "서울특별시")?.code,
    "11000",
  );
  const mergedCities = [
    ["11000", "서울특별시"],
    ["26000", "부산광역시"],
    ["27000", "대구광역시"],
    ["28000", "인천광역시"],
    ["29000", "광주광역시"],
    ["30000", "대전광역시"],
    ["31000", "울산광역시"],
  ];
  for (const [code, name] of mergedCities) {
    const city = result.regions.find((region) => region.code === code);
    assert.equal(city?.name, name);
  }
  assert.equal(
    result.regions.filter(({ provinceCode }) =>
      ["11", "26", "27", "28", "29", "30", "31"].includes(provinceCode),
    ).length,
    0,
  );
  const mergedDistrictCities = [
    ["41110", "수원시"],
    ["41130", "성남시"],
    ["41170", "안양시"],
    ["41190", "부천시"],
    ["41270", "안산시"],
    ["41280", "고양시"],
    ["41460", "용인시"],
    ["43110", "청주시"],
    ["44130", "천안시"],
    ["47110", "포항시"],
    ["48120", "창원시"],
    ["52110", "전주시"],
  ];
  for (const [code, name] of mergedDistrictCities) {
    const city = result.regions.find((region) => region.code === code);
    assert.equal(city?.name, name);
  }
  assert.deepEqual(
    result.regions
      .filter(({ name }) => /구$/.test(name))
      .map(({ name }) => name),
    [],
  );
  assert.ok(
    result.regions.some(({ geometryType }) => geometryType === "MultiPolygon"),
  );
  assert.ok(
    result.regions.reduce(
      (total, { polygonCount }) => total + polygonCount,
      0,
    ) < 3000,
  );
  assert.equal(result.metadata.version, "sgis-sigungu-2025-2q-v7");
  assert.equal(result.metadata.localizationVersion, "2026-11-23");
});

test("generates complete multilingual names for every Korea region", () => {
  const result = generateMap(koreaSource, MAP_CONFIGS.korea);
  assert.equal(
    Object.keys(koreaLocalizations.regions).length,
    result.regions.length,
  );
  assert.deepEqual(
    Object.keys(koreaLocalizations.regions).sort(),
    result.regions.map(({ code }) => code).sort(),
  );

  for (const region of result.regions) {
    assert.ok(region.englishName?.length > 0, `${region.code} English name`);
    assert.ok(region.japaneseName?.length > 0, `${region.code} Japanese name`);
    assert.ok(
      region.simplifiedChineseName?.length > 0,
      `${region.code} Simplified Chinese name`,
    );
    if (region.provinceCode) {
      assert.ok(
        region.englishProvinceName?.length > 0,
        `${region.code} English province name`,
      );
      assert.ok(
        region.japaneseProvinceName?.length > 0,
        `${region.code} Japanese province name`,
      );
      assert.ok(
        region.simplifiedChineseProvinceName?.length > 0,
        `${region.code} Simplified Chinese province name`,
      );
    }
  }

  const yangpyeong = result.regions.find(({ code }) => code === "41830");
  assert.deepEqual(
    {
      englishName: yangpyeong?.englishName,
      japaneseName: yangpyeong?.japaneseName,
      simplifiedChineseName: yangpyeong?.simplifiedChineseName,
      englishProvinceName: yangpyeong?.englishProvinceName,
    },
    {
      englishName: "Yangpyeong-gun",
      japaneseName: "楊平郡",
      simplifiedChineseName: "杨平郡",
      englishProvinceName: "Gyeonggi-do",
    },
  );
  assert.equal(
    result.regions.find(({ code }) => code === "48820")?.japaneseName,
    "固城郡",
  );
  assert.equal(
    result.regions.find(({ code }) => code === "51820")?.japaneseName,
    "高城郡",
  );
  assert.equal(
    result.regions.find(({ code }) => code === "48820")?.simplifiedChineseName,
    "固城郡",
  );
  assert.equal(
    result.regions.find(({ code }) => code === "51820")?.simplifiedChineseName,
    "高城郡",
  );
});

test("generates world countries with ISO alpha-2 codes", () => {
  const result = generateMap(worldSource, MAP_CONFIGS.world);
  assert.equal(result.regions.length, 175);
  assertValidMap(result, /^[A-Z]{2}$/);
  assert.equal(result.regions.find(({ code }) => code === "US")?.name, "미국");
  assert.equal(result.regions.find(({ code }) => code === "JP")?.name, "일본");
  assert.equal(
    result.regions.find(({ code }) => code === "US")?.englishName,
    "United States of America",
  );
  assert.equal(
    result.regions.find(({ code }) => code === "JP")?.englishName,
    "Japan",
  );
  assert.equal(
    result.regions.find(({ code }) => code === "US")?.japaneseName,
    "アメリカ合衆国",
  );
  assert.equal(
    result.regions.find(({ code }) => code === "JP")?.simplifiedChineseName,
    "日本",
  );
  assert.ok(
    result.regions.some(({ geometryType }) => geometryType === "MultiPolygon"),
  );
  assert.deepEqual(result.metadata.excludedFeatures, [
    "Turkish Republic of Northern Cyprus",
    "Somaliland",
  ]);
  assert.equal(result.projection.geographic, true);
  const france = result.regions.find(({ code }) => code === "FR");
  assert.ok(france.anchor.x > 350 && france.anchor.x < 380);
  assert.ok(france.anchor.y > 70 && france.anchor.y < 100);
  assert.ok(france.anchorBounds.width < france.bounds.width / 3);
  const unitedStates = result.regions.find(({ code }) => code === "US");
  assert.ok(unitedStates.anchorBounds.width < unitedStates.bounds.width);
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

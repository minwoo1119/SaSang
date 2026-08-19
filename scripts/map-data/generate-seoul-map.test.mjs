import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { generateSeoulMap } from "./generate-seoul-map.mjs";

const source = JSON.parse(
  await readFile(
    new URL("./sources/seoul-municipalities-2015.geojson", import.meta.url),
    "utf8",
  ),
);

test("generates all 25 Seoul districts with stable codes and SVG paths", () => {
  const result = generateSeoulMap(source);
  assert.equal(result.regions.length, 25);
  assert.equal(new Set(result.regions.map(({ code }) => code)).size, 25);
  for (const region of result.regions) {
    assert.match(region.code, /^11\d{3}$/);
    assert.match(region.path, /^M/);
    assert.match(region.path, / Z$/);
  }
});

test("is deterministic for the same source", () => {
  assert.deepEqual(generateSeoulMap(source), generateSeoulMap(source));
});

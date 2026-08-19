import { readFile, writeFile } from "node:fs/promises";
import { basename } from "node:path";

function readDbf(buffer) {
  const recordCount = buffer.readUInt32LE(4);
  const headerLength = buffer.readUInt16LE(8);
  const recordLength = buffer.readUInt16LE(10);
  const fields = [];
  for (let offset = 32; buffer[offset] !== 0x0d; offset += 32) {
    const end = buffer.indexOf(0, offset);
    fields.push({
      name: buffer.toString("ascii", offset, end),
      length: buffer[offset + 16],
    });
  }
  return Array.from({ length: recordCount }, (_, index) => {
    let offset = headerLength + index * recordLength + 1;
    const row = {};
    for (const field of fields) {
      row[field.name] = buffer
        .toString("utf8", offset, offset + field.length)
        .replace(/\0/g, "")
        .trim();
      offset += field.length;
    }
    return row;
  });
}

function signedArea(ring) {
  let area = 0;
  for (let index = 0; index < ring.length - 1; index += 1) {
    area +=
      ring[index][0] * ring[index + 1][1] -
      ring[index + 1][0] * ring[index][1];
  }
  return area / 2;
}

function pointSegmentDistanceSquared(point, start, end) {
  const dx = end[0] - start[0];
  const dy = end[1] - start[1];
  if (dx === 0 && dy === 0) {
    return (point[0] - start[0]) ** 2 + (point[1] - start[1]) ** 2;
  }
  const ratio = Math.max(
    0,
    Math.min(
      1,
      ((point[0] - start[0]) * dx + (point[1] - start[1]) * dy) /
        (dx * dx + dy * dy),
    ),
  );
  const projectedX = start[0] + ratio * dx;
  const projectedY = start[1] + ratio * dy;
  return (point[0] - projectedX) ** 2 + (point[1] - projectedY) ** 2;
}

function simplifyOpenLine(points, toleranceSquared) {
  if (points.length <= 2) return points;
  let maxDistance = 0;
  let splitIndex = 0;
  for (let index = 1; index < points.length - 1; index += 1) {
    const distance = pointSegmentDistanceSquared(
      points[index],
      points[0],
      points.at(-1),
    );
    if (distance > maxDistance) {
      maxDistance = distance;
      splitIndex = index;
    }
  }
  if (maxDistance <= toleranceSquared) return [points[0], points.at(-1)];
  return [
    ...simplifyOpenLine(points.slice(0, splitIndex + 1), toleranceSquared).slice(
      0,
      -1,
    ),
    ...simplifyOpenLine(points.slice(splitIndex), toleranceSquared),
  ];
}

function simplifyRing(ring, tolerance) {
  if (tolerance === 0 || ring.length <= 5) return ring;
  const open = ring.slice(0, -1);
  const anchor = open.reduce(
    (best, point, index) => (point[0] < open[best][0] ? index : best),
    0,
  );
  const opposite = open.reduce((best, point, index) => {
    const dx = point[0] - open[anchor][0];
    const dy = point[1] - open[anchor][1];
    const bestDx = open[best][0] - open[anchor][0];
    const bestDy = open[best][1] - open[anchor][1];
    return dx * dx + dy * dy > bestDx * bestDx + bestDy * bestDy
      ? index
      : best;
  }, 0);
  const rotated = [...open.slice(anchor), ...open.slice(0, anchor)];
  const split = (opposite - anchor + open.length) % open.length;
  const first = simplifyOpenLine(
    rotated.slice(0, split + 1),
    tolerance * tolerance,
  );
  const second = simplifyOpenLine(
    [...rotated.slice(split), rotated[0]],
    tolerance * tolerance,
  );
  const simplified = [...first.slice(0, -1), ...second];
  if (simplified.length >= 4) return simplified;
  const quarter = Math.max(1, Math.floor(rotated.length / 4));
  return [
    rotated[0],
    rotated[quarter],
    rotated[Math.min(quarter * 2, rotated.length - 1)],
    rotated[Math.min(quarter * 3, rotated.length - 1)],
    rotated[0],
  ];
}

function ringsToGeometry(rings) {
  const polygons = [];
  for (const ring of rings) {
    if (signedArea(ring) < 0 || polygons.length === 0) polygons.push([ring]);
    else polygons.at(-1).push(ring);
  }
  return polygons.length === 1
    ? { type: "Polygon", coordinates: polygons[0] }
    : { type: "MultiPolygon", coordinates: polygons };
}

function readShp(buffer, tolerance) {
  const geometries = [];
  for (let offset = 100; offset < buffer.length; ) {
    const contentLength = buffer.readUInt32BE(offset + 4) * 2;
    const contentOffset = offset + 8;
    const shapeType = buffer.readUInt32LE(contentOffset);
    if (shapeType !== 5) throw new Error(`Unsupported SHP shape type: ${shapeType}`);
    const partCount = buffer.readUInt32LE(contentOffset + 36);
    const pointCount = buffer.readUInt32LE(contentOffset + 40);
    const partIndexes = Array.from({ length: partCount }, (_, index) =>
      buffer.readUInt32LE(contentOffset + 44 + index * 4),
    );
    const pointsOffset = contentOffset + 44 + partCount * 4;
    const points = Array.from({ length: pointCount }, (_, index) => [
      buffer.readDoubleLE(pointsOffset + index * 16),
      buffer.readDoubleLE(pointsOffset + index * 16 + 8),
    ]);
    const rings = partIndexes.map((start, index) =>
      simplifyRing(
        points.slice(start, partIndexes[index + 1] ?? pointCount),
        tolerance,
      ),
    );
    geometries.push(ringsToGeometry(rings));
    offset = contentOffset + contentLength;
  }
  return geometries;
}

function argument(name) {
  const index = process.argv.indexOf(`--${name}`);
  if (index === -1 || !process.argv[index + 1]) {
    throw new Error(`Missing --${name} argument.`);
  }
  return process.argv[index + 1];
}

async function main() {
  const shpPath = argument("shp");
  const dbfPath = argument("dbf");
  const outputPath = argument("output");
  const codeField = argument("code-field");
  const nameField = argument("name-field");
  const tolerance = Number(argument("tolerance"));
  const [shp, dbf] = await Promise.all([readFile(shpPath), readFile(dbfPath)]);
  const geometries = readShp(shp, tolerance);
  const rows = readDbf(dbf);
  if (geometries.length !== rows.length) {
    throw new Error("SHP and DBF record counts do not match.");
  }
  const features = rows
    .map((properties, index) => ({
      type: "Feature",
      properties: {
        code: properties[codeField],
        name: properties[nameField],
      },
      geometry: geometries[index],
    }))
    .sort((left, right) => left.properties.code.localeCompare(right.properties.code));
  await writeFile(
    outputPath,
    `${JSON.stringify({ type: "FeatureCollection", features })}\n`,
    "utf8",
  );
  console.log(`Prepared ${features.length} features from ${basename(shpPath)}.`);
}

await main();

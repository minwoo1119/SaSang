# Map data preprocessing

Sasang renders committed, lightweight SVG path assets. The Expo app never parses
SHP or GeoJSON at runtime.

```bash
pnpm map:generate
pnpm map:test
```

`generate-maps.mjs` normalizes both Polygon and MultiPolygon features into a
shared view box, sorts regions by stable code, rounds coordinates consistently,
and writes deterministic JSON. Generated files contain the marker
`THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.`

## Korea

- Geometry: National Data Center SGIS nationwide sigungu boundary,
  `bnd_sigungu_00_2025_2Q`, reference date 2025 Q2.
- Identifier: official five-digit legal-district prefix from the Ministry of
  the Interior and Safety Administrative Standard Code system, snapshot joined
  at 2025-06-30. SGIS statistical codes are retained only as source join keys.
- Input: `sources/korea-sigungu-2025-2q.geojson`.
- Output: `app/src/assets/maps/korea/regions.json`.

Seoul, Busan, Daegu, Incheon, Gwangju, Daejeon, and Ulsan are merged to their
special/metropolitan-city region. Non-metropolitan cities that are split into
district features, such as Suwon, Cheongju, and Changwon, are also merged to
the parent city region. Shared district boundaries are dissolved during
generation so the app renders only the merged city outlines.

The large source SHP is converted outside the mobile runtime with
`prepare-shapefile.mjs`. A 250-meter deterministic Douglas-Peucker tolerance is
applied while preserving every source ring and its Polygon/MultiPolygon type.

## World

- Geometry: Natural Earth 1:110m Admin-0 Countries, version 5.1.2.
- Identifier: `ISO_A2_EH` (ISO 3166-1 alpha-2).
- Input: `sources/natural-earth-admin0-5.1.2.geojson`.
- Output: `app/src/assets/maps/world/countries.json`.

Natural Earth features without a valid ISO alpha-2 code are not assigned an
invented code. `Turkish Republic of Northern Cyprus` and `Somaliland` are
therefore excluded and recorded in the generated asset metadata.

The old Seoul 2015 source and generator remain only as a regression fixture;
the app does not import the Seoul-only generated asset.

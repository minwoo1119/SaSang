# Map data notices

## Korea sigungu boundaries

- Dataset: 국가데이터처_SGIS 행정구역 통계 및 경계_20250630
- Geometry file: `bnd_sigungu_00_2025_2Q`
- Reference date: 2025 Q2
- Provider: 국가데이터처 통계지리정보서비스 (SGIS)
- Source: https://www.data.go.kr/data/15129688/fileData.do
- Terms shown by the provider: 무료, 이용허락범위 제한 없음
- Coordinate system of source SHP: EPSG:5179

Official five-digit district identifiers are based on the Ministry of the
Interior and Safety Administrative Standard Code system:
https://www.code.go.kr/stdcode/regCodeL.do

The committed GeoJSON is a deterministic, simplified preprocessing input. It is
not loaded by the app.

## Korea administrative-name localizations

`sources/korea-region-localizations.json` is a reviewed, code-keyed name table.
It does not import third-party geometry.

- English names: V-World administrative-boundary properties, republished by
  `KnellBalm/kr-admin-geojson` from public data released on 2023-07-29. The
  source requires attribution to the National Spatial Information Portal.
- Japanese names: Wikidata Japanese labels, retrieved 2026-11-23 and available
  under CC0 1.0. Same-named Goseong counties are resolved by province and
  stable five-digit code.
- Simplified Chinese names: Korea level-2 labels from
  `JayMuShui/chinese-global-compliant-geodata`, updated 2025-06-13 and released
  under the MIT License. The upstream translation follows the Chinese place-name
  handbook and Korean official Hanja notation.

English source:
https://github.com/KnellBalm/kr-admin-geojson/blob/main/sig.geojson

Japanese source:
https://www.wikidata.org/

Simplified Chinese source:
https://github.com/JayMuShui/chinese-global-compliant-geodata/blob/main/src/geojson/countries/as/kor/global/kor-level-2.json

MIT License

Copyright (c) 2025 JayMuShui

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## World country boundaries

- Dataset: Natural Earth Admin-0 Countries, 1:110m
- Version: 5.1.2
- Source: https://www.naturalearthdata.com/downloads/110m-cultural-vectors/
- Direct archive: https://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_countries.zip
- License: public domain / CC0 1.0
- Boundary policy: Natural Earth's default de facto viewpoint

Natural Earth attribution is not legally required, but is retained here for
provenance: Made with Natural Earth.

## Seoul regression fixture

The 2015 Seoul source is retained only to exercise the original proof-of-concept
generator test. It is not production map data and is not imported by the app.

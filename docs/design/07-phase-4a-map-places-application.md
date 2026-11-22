# Phase 4-A 지도 및 장소 적용 기록

## 범위

Phase 4-A는 지도 상단 Floating Control, 검색창, 확대/축소 Control, 선택 지역 안내와 장소 목록의 필터·정렬·사진 카드에 Phase 2에서 확정한 Semantic Token을 적용한다. Full-screen Map, Floating Overlay 위치, 지도 렌더링, 사진 클리핑, 선택·정렬 및 데이터 로직은 유지한다.

Phase 3의 별도 구현 산출물이 현재 `dev`에 존재하지 않으므로, 이미 검증되어 병합된 `SasangSurface`, `MapModeSelector`와 Semantic Token API만 재사용했다. 새로운 공통 컴포넌트 체계나 Phase 4-B 이후 UI는 이 작업에서 만들지 않았다.

## 적용한 토큰

| UI | 기존 값 | 적용 토큰 | 영향 |
|---|---|---|---|
| 지도 Overlay 외곽 여백 | 16 | `SasangSemanticSpacing.mapOverlayInset` | 위치 변화 없음 |
| 지도 Control 간격 | 8, 12 | `small`, `medium` | 간격 변화 없음 |
| 검색창 Radius | 23 | `SasangSemanticRadii.search` | 기존 Pill 형태 유지 |
| 검색 Placeholder | `#8E8E93`, 14sp | `tertiaryTextAccessible` + body 14sp | 작은 텍스트 대비 개선 |
| 지도 요약/배지 강조색 | `#007AFF` | `accentText` | 작은 텍스트 대비 개선 |
| Floating Control | 화면별 `Container` | `SasangSurface(blur: true)` | 기존 Floating 그림자와 Blur 유지, 중복 제거 |
| 확대/축소 Control Radius | 24 | `radiusSelectionCard` | 외형 변화 없음 |
| 확대/축소 Divider | 임의 Divider | `hairlineWidth`, `divider` | 역할 명시, 배치 변화 없음 |
| 장소 사진 카드 Radius | 8 | `radius.media` | 승인된 8dp 예외 유지 |
| 장소 사진 카드 Shadow | 강한 Floating | `elevation.low` | 사진보다 장식이 앞서지 않도록 완화 |
| 장소 사진 카드 Border | 임의 Overlay Border | `border.subtle` | 정적 콘텐츠 역할 반영 |
| 장소 카드 제목 | 16sp w800 | `optionTitle` 16/22 w700 | 중복 강조 완화 |
| 장소 카드 보조/날짜 | 화면별 색상 | `supporting`, `caption` | 위계 및 대비 정리 |
| 장소 빈 상태 Card | radius 20 + Floating Shadow | `contentCard` 22 + `elevation.low` | 구조 유지, 정적 패널 역할 반영 |

## 보존한 예외와 구조

- 장소 사진 카드의 8dp Radius는 변경하지 않았다.
- 지도 검색창은 `radius.control = 16`을 사용하지 않고 Pill 형태를 유지했다.
- 선택 지역 Control의 30dp 실루엣, 썸네일, 추가 버튼과 Overlay 위치를 유지했다.
- 지도와 여행 사진의 렌더링·클리핑·확대/축소 변환 로직을 변경하지 않았다.
- 지도 선택 Bottom Sheet의 콘텐츠 구성은 변경하지 않았다.
- 장소 정렬, 지도 모드 전환, 사진 앨범 진입 로직을 변경하지 않았다.

## 검증 기준선

- `test/goldens/map_floating_controls.png`: 지도 상단 Floating Control
- `test/goldens/map_search_and_zoom_controls.png`: 검색창과 실제 `RegionMapView` 확대/축소 Control
- `test/goldens/places_photo_card.png`: 장소 사진 카드와 정렬 Control

Golden Test의 장소 사진은 실제 파일과 디코딩 환경의 비결정성을 제거하기 위해 고정된 회색 테스트 Surface로 대체했다. 실제 지도 및 사진 데이터의 렌더링 정확성은 기존 지도 회귀 테스트와 iOS/Android 실행 캡처로 보완한다.

## 스크린샷

- `docs/pr-screenshots/17/golden-map-before.png`: Phase 2-B 지도 Floating 기준선
- `docs/pr-screenshots/17/golden-map-after.png`: Phase 4-A 지도 Floating 결과
- `docs/pr-screenshots/17/golden-places-after.png`: Phase 4-A 장소 카드 Golden
- `docs/pr-screenshots/17/ios-map-after.png`: iOS Simulator 실행 결과
- `docs/pr-screenshots/17/android-map-after.png`: Android Emulator 실행 결과
- `docs/pr-screenshots/17/android-places-before.png`: `origin/dev` 장소 빈 상태 기준선
- `docs/pr-screenshots/17/android-places-after.png`: Android 장소 빈 상태 실행 결과

## 회귀 위험

- `MapModeSelector`는 지도와 장소에서 함께 사용되므로 두 플랫폼에서 Bottom Sheet 진입 및 모드 전환을 확인해야 한다.
- Blur Surface는 플랫폼 렌더러에 따라 픽셀 차이가 발생할 수 있어 Golden은 고정 테스트 플랫폼에서 비교한다.
- 장소 카드의 Shadow 변경은 레이아웃에는 영향을 주지 않지만 밝은 배경에서 경계 인지가 달라질 수 있다.
- 큰 글자 설정에서 필터와 정렬 Control의 폭이 증가할 수 있다. 기존 최대 폭과 말줄임 정책은 유지했다.

## 다음 단계 제한

Phase 4-B의 지역 사진 관리 Bottom Sheet, 사진 캐러셀, 사진 날짜 선택 UI는 이 작업에 포함하지 않는다. 사용자 승인 후 별도 Issue와 PR에서 진행한다.

# 화면별 예외 규칙

예외는 디자인 시스템을 우회하는 허가가 아니라 제품 구조나 플랫폼 동작을 보존하기 위한 좁은
계약이다. 새 예외는 기존 토큰/컴포넌트로 해결되지 않는 이유, 적용 범위, 회귀 테스트를 같은 PR에
기록한다.

## 승인된 예외

| 영역 | 예외 | 이유/경계 |
|---|---|---|
| Full-screen Map | 지도 아래 별도 고정 toolbar로 변경하지 않음 | 지도와 사진이 주 콘텐츠 |
| Floating Overlay | 위치 계약과 독립 hit target 유지 | 지도 제스처와 정보 문맥 보존 |
| 지도 검색 | `radius.control` 대신 `SasangSemanticRadii.search` pill | 기존 검색 silhouette 보존 |
| 장소 사진 카드 | `SasangSemanticRadii.media` 8dp | 사진 중심 카드의 승인된 차이 |
| 내 지도 | 2열 map preview와 sticky 상점 footer | 구매 지도 확장과 비교 구조 |
| 지역 사진 | 보유 사진 carousel 310dp | swipe와 사진 중심 경험; 작은 화면은 body scroll |
| 날짜 | `CupertinoDatePicker` 내부 배율 최대 1.5 | 320dp 폭 wheel overflow 방지; 주변 문구는 scale 2.0 유지 |
| 내보내기 선택 | 이미지/영상 두 행과 9:16 preview | 결과 형식의 직접 비교 |
| 법적 문서 | `legalBody` 16sp/1.68 | 일반 body와 다른 장문 가독성 |
| LicensePage | Flutter 표준 `LicensePage` 유지 | 라이선스 기능 재구현 위험 방지 |
| 플랫폼 UI | system share, ATT, picker, alert 내부 | 플랫폼 권한·접근성 동작 우선 |
| 지도 painter/export renderer | geometry, stroke, frame, encoding 수치 | UI token이 아닌 렌더링 도메인 계약 |
| 온보딩 illustration | 의미 있는 illustration 내부 고유색/크기 | 일반 UI surface/텍스트에는 확장 금지 |

Bottom Sheet surface는 예외 없이 흰색 `SasangSemanticColors.surface`를 사용한다. 검색 pill이나
장소 radius 8 예외를 다른 입력/카드에 복제하지 않는다.

## 레이아웃 계약과 시각 토큰 구분

하단 바 높이, 지도 overlay overlap, zoom offset, 사진 aspect ratio, safe area 보정은 기능적
레이아웃 계약일 수 있다. 이런 값은 color/radius/spacing token으로 억지로 바꾸지 않되 이름 있는
layout constant와 테스트를 우선한다.

## 검사 예외 표기

새 raw 값이 정말 필요한 경우 같은 줄 또는 바로 위 줄에 구체적인 이유를 남긴다.

```dart
// sasang-design-exception: 지도 선택선은 확대 배율과 역비례하는 렌더링 도메인 값이다.
final strokeWidth = 1.6 / zoom;
```

`// sasang-design-exception: 예외`처럼 의미 없는 설명은 허용하지 않는다. 예외가 공통 의미로 두 번
이상 등장하면 토큰 또는 이름 있는 도메인 상수로 승격한다.

## 기존 부채 baseline

`tool/design_style_baseline.txt`는 Phase 6 시점의 기존 raw style을 동결한 목록이다. 목록에 있다는
사실은 승인된 디자인이라는 뜻이 아니다. 수정하는 화면에서는 가능한 범위의 baseline 항목을 줄인다.
새 항목을 통과시키려고 `--update-baseline`을 실행하지 않는다. baseline 추가가 불가피하면 PR에
추가된 항목과 이유를 명시하고 디자인 문서/테스트를 함께 갱신한다.

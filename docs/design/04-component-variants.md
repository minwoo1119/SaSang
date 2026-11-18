# Sasang 컴포넌트 Variant 제안

## 1. 공통 구현 전략

새 컴포넌트를 화면마다 만들지 않고 현재 구현을 다음 순서로 확장한다.

1. `SasangSurface`, `SasangPrimaryButton`, `showSasangSheet`, `SasangCenterModal`에 의미 Variant를 추가한다.
2. `MapModeSelector`, `RegionPhotoAlbumSheet`, `MapScreen`의 도메인 구조는 유지하고 공통 shell/token만 주입한다.
3. 표준 Flutter/Cupertino 컴포넌트는 래퍼로 호출 경로와 semantic variant를 통합한다.
4. 화면 전용 레이아웃은 공통화 이익이 명확할 때만 추출한다.

## 2. Floating Control

### Variant

| Variant | 기존 대응 | 용도 | 규격 |
|---|---|---|---|
| `compactPill` | 기록 요약, 지도 선택, 정렬 | 짧은 상태/선택 | 높이 38, pill, 좌우 12 |
| `icon` | 공유 | 단일 icon action | 시각 38, hit 44, pill |
| `search` | 지도 검색 | 입력/검색 | 높이 46, radius control |
| `stack` | 확대/축소/1:1 | 관련 icon action 묶음 | 각 44, radius selection |
| `contextBar` | 선택 지역 control | 현재 선택+다음 행동 | 최소 56, content에 따라 확장 |
| `navigation` | 하단 nav | 주 화면 전환 | 높이 66, radius 34 |

### 상태

- 기본: `surface` 94~96%, floating border/elevation.
- 선택: accent content 또는 선택 label. 표면 전체를 파란색으로 바꾸지 않는다.
- 눌림: pressed opacity 토큰, 지도 제스처로 event가 전파되지 않음.
- 비활성: content 45%, action 차단, semantics disabled.
- 오류: Floating Control 자체 오류보다 인접 inline message/Information Dialog를 사용한다.

### 보존과 개선

- 버튼 삭제나 하단 고정 전환은 금지한다.
- 여러 Control을 하나의 거대한 toolbar로 합치지 않는다.
- 가까운 컨트롤의 elevation과 border는 같은 토큰을 사용해 “여러 장의 카드” 인상을 줄인다.

```text
Before: [요약]     [공유] [지도▼]   각기 다른 표면 규칙
After : [요약]     [공유] [지도▼]   같은 높이·border·shadow, 기능은 동일
```

## 3. Selection Card

### Variant

| Variant | 기존 대응 | 보존 구조 |
|---|---|---|
| `mapPreview` | 내 지도 2열 카드 | 2열, 지도 preview, 이름/설명 |
| `language` | 온보딩 언어 | 한 줄 label, 선택 semantic |
| `format` | 사진/영상 내보내기 | 9:16 결과 preview, 제목/설명 |

### 상태

- 기본: white surface, subtle border, elevation 없음.
- 선택: accent 72% border 1.25 + accentSoft 배경 또는 selected label 중 최대 두 신호.
- 눌림: 180ms border/surface 전환.
- 비활성: content 45%, preview 유지, 선택 불가 이유가 있으면 supporting text.
- 오류: destructive border + inline supporting text. 체크 아이콘 자동 추가 금지.

`mapPreview`의 24dp radius와 2열 배치는 유지한다. `format`은 현재 Bottom Sheet의 행 구조를 유지하므로 카드형 grid로 바꾸지 않는다.

## 4. Content Card

### Variant

| Variant | 기존 대응 | Radius/Elevation | 설명 |
|---|---|---|---|
| `photo` | 장소 카드 | 8 / low | 사진 면적 우선, 즉시 변경 보류 |
| `product` | 지도 상점 카드 | 22 / none | preview+설명+가격 |
| `information` | 앱 상세 정보 | 22 / none | key/value 또는 navigation rows |
| `editorPhoto` | 지역 앨범 사진 | 24 / photo | 사진 편집/대표 상태 |

### 상태

- 기본: 역할별 radius 유지, 정적 카드는 border만 사용.
- 눌림: 전체 카드 pressed state, 내부 중복 ripple/splash 없음.
- 선택: Content Card 자체보다 Selection Card variant를 사용한다.
- 비활성: 상점 미출시처럼 badge와 CTA 중 하나만 주요 상태 신호로 사용한다.
- 오류: 이미지 로드 실패 시 subtle surface+재시도 action. 깨진 이미지 아이콘만 노출하지 않는다.

### 상품 카드 단순화 예

```text
Before                    After
┌─ preview ─────────┐     ┌─ preview ─────────┐
│                   │     │                   │
├───────────────────┤     ├───────────────────┤
│ 이름 [출시 예정]  │     │ 이름              │
│ 설명              │     │ 설명 · 출시 예정  │
│ 가격              │     │ 가격              │
└───────────────────┘     └───────────────────┘
```

구체적인 콘텐츠 삭제 여부는 상품 정책 확정 후 결정하며 이 문서는 상태 강조 중복만 줄이도록 제안한다.

## 5. Settings Section

기존 더보기 그룹형 카드 구조를 유지한다.

### 구성

- `groupLabel`: 14/20 w700
- `surface`: radius 20, subtle border, shadow 없음
- `row`: 최소 56(현재 60에서 검토), 좌우 16~18, 내용에 따라 높이 증가
- `divider`: 행 콘텐츠 inset과 정렬
- row 종류: `navigation`, `value`, `action`, `destructiveAction`, `loadingAction`

### 상태

- 기본: primary text, navigation만 chevron.
- 눌림: row 단위 subtle pressed overlay.
- 비활성/로딩: content 45% 또는 progress, 중복 탭 차단.
- 파괴: destructive text, chevron 없음, 실행 전 Destructive Dialog.
- 오류: 카드 전체를 빨갛게 하지 않고 해당 row 아래 supporting message 또는 Information Dialog.

`SasangChevronRow`와 `_MoreMenuRow`는 장기적으로 같은 row primitive를 공유하되, Phase 1에서 바로 하나의 public widget로 합치지 않는다. 먼저 시각 토큰과 상태 API를 맞춘다.

## 6. Bottom Sheet

### 공통 Shell

- background `color.canvas`
- radius 28
- scrim 28%
- safe area 반영
- handle 36×5, `#D4D4D8`, 상단 9~10
- header 좌우 20, 제목 `type.sheetTitle`
- close 시각 34~36, hit 44, radius pill, `surfaceSubtle`
- compact sheet는 화면 사방 8 여백, library sheet는 화면 하단/좌우에 붙을 수 있음

### Variant별 계약

| Variant | Body | Footer | 높이/스크롤 | 유지 사항 |
|---|---|---|---|---|
| `library` | 2열 map preview grid | 상점 링크 sticky | 최대 74%, body scroll | 2열 구조, 구매 지도 확장 |
| `exportChoice` | image/video 결과 행 | 없음 | content-fit | 두 형식, 9:16 preview |
| `regionPhotos` | photo carousel 또는 compact empty | 날짜/대표/삭제 inline | 상태별, carousel swipe | 사진 중심/대표/날짜 |
| `datePicker` | photo+selected date+system picker | 취소/저장 | content-fit, 작은 화면 scroll | 시스템 picker와 메타 설명 |
| `productDetail` | preview+description+price | primary 상태 action | content-fit | 상점 문맥 위 상세 |

### 상태

- 로딩: body skeleton 또는 spinner, header/close 유지.
- 빈 상태: `regionPhotos`에서 310dp 빈 carousel을 180~220dp compact action panel로 줄이는 안을 우선 실험한다. 사진 보유 상태 carousel 310은 유지한다.
- 오류: body inline error+재시도; 치명적이면 Information Dialog.
- 비활성: 개별 action만 비활성, sheet 전체 opacity 금지.

```text
지역 사진 없음

Before                         Proposal
┌──────────────────────┐       ┌──────────────────────┐
│                      │       │  사진 추가            │
│        ( + )         │ 310   │  앨범에서 선택하기    │ 180~220
│      사진 추가       │       │             [추가]   │
│                      │       └──────────────────────┘
└──────────────────────┘

사진 보유 상태의 310dp carousel은 유지한다.
```

## 7. Dialog

### 공통 API 개념

```text
showSasangDialog(
  variant: information | confirmation | destructive | progress,
  title,
  message,
  primaryAction,
  secondaryAction?,
  progress?,
)
```

이는 제안 API이며 현재 코드를 이번 단계에서 변경하지 않는다.

### Variant

| Variant | 표현 | Action | 사례 |
|---|---|---|---|
| `information` | platform alert 우선 | 확인 1개 | 공유 기록 없음, 백업 실패 |
| `confirmation` | platform alert 또는 공통 semantic wrapper | 취소+확인 | 로그아웃, 백업 시작 |
| `destructive` | 명시적 destructive action | 취소+빨간 동사 | 데이터 삭제 |
| `progress` | Toss 스타일 custom center modal | 기본적으로 action 없음, 필요 시 취소 | 내보내기/백업 진행 |

### 상태/규칙

- action label은 “확인”보다 “백업 파일 만들기”, “데이터 지우기”처럼 결과를 쓴다.
- 2열 버튼이 큰 글꼴/긴 번역에서 잘리면 세로 배치한다.
- destructive는 기본 focus를 취소에 둔다.
- progress는 제목, 현재 단계, determinate/indeterminate indicator, 접근성 live region을 제공한다.
- 시스템 dialog를 유지하더라도 직접 `showCupertinoDialog` 호출은 semantic wrapper를 통해 관리한다.

## 8. Button

### Variant

| Variant | Surface/Content | 기본 높이 | Radius | 용도 |
|---|---|---:|---:|---|
| `primary` | accent/white | 52 | 16 | 핵심 완료 행동 |
| `secondary` | surfaceSubtle/textPrimary | 52 | 16 | 취소/보조 행동 |
| `tertiary` | transparent/accent | 최소 44 | 16 또는 없음 | 링크형 행동 |
| `destructive` | destructive/white 또는 transparent/destructive | 52 | 16 | 위험 작업 |
| `icon` | variant surface/icon | 시각 34~44, hit 44 | pill | close/share 등 |

### 상태

- 기본, pressed, disabled, loading, error-result를 지원한다.
- loading 시 label 폭을 유지하고 spinner로 레이아웃이 흔들리지 않게 한다.
- disabled는 surface와 content를 함께 변화시키되 텍스트 대비를 유지한다.
- error는 버튼을 지속적으로 빨갛게 만들지 않고 결과 메시지로 전달한다. destructive variant만 기본 red.
- 아이콘은 행동 이해를 보완할 때만 사용한다. CTA 양끝 아이콘을 장식으로 추가하지 않는다.

현재 `SasangPrimaryButton`은 유지하면서 secondary/destructive variant 또는 별도 작은 wrapper를 추가하는 경로가 적합하다. 전면 재작성은 필요하지 않다.

## 9. Empty State

### Variant

| Variant | 표현 | 사례 |
|---|---|---|
| `inline` | 제목+설명+text action | 검색 결과 없음 |
| `panel` | subtle surface+제목+설명+button | 장소 첫 기록 |
| `sheetAction` | compact panel/row+primary action | 지역 사진 없음 |
| `blocking` | Information Dialog | 공유할 기록 없음 |

### 상태/규칙

- 아이콘은 의미가 추가될 때만 사용하며 기본 필수 요소가 아니다.
- 제목과 설명이 같은 의미를 반복하지 않는다.
- 한 개의 명확한 다음 행동만 강조한다.
- panel 자체와 내부 action 모두에 강한 그림자를 적용하지 않는다.
- 빈 영역을 채우기 위해 고정 높이를 과도하게 키우지 않는다.
- 오류 상태와 빈 상태를 분리한다. 오류는 원인/재시도를 제공한다.

## 10. 플랫폼 공통 적용

| 영역 | 공통 | iOS | Android |
|---|---|---|---|
| Tokens | 색/글꼴 역할/간격/radius/state | system red/gesture | system red/back/focus |
| Sheet | shell/header/body 계약 | Cupertino 감속감 | Material route semantics 유지 |
| Dialog | semantic variants | Cupertino alert 허용 | 접근성 focus/back 처리 |
| Date | 정보 구조/CTA | CupertinoDatePicker | 현행 picker 유지 또는 별도 승인 |
| Motion | duration/intent | reduce motion | animator duration scale 존중 |
| Blur | floating identity | backdrop blur | 성능 저하 시 opaque fallback |

외형을 픽셀 단위로 완전히 동일하게 만드는 것이 목표가 아니다. 같은 역할과 계층, 같은 브랜드 인상을 보장하는 것이 목표다.

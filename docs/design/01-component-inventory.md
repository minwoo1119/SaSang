# Sasang UI 컴포넌트 인벤토리

## 1. 목적

현재 Flutter UI에서 반복되는 디자인 값과 컴포넌트의 실제 사용 상태를 정리한다. 이 문서는 “현 상태의 사실”을 기록하며 새 디자인 사양을 확정하지 않는다. 화면별 평가는 [`00-current-ui-audit.md`](00-current-ui-audit.md)를 따른다.

## 2. 현재 디자인 토큰

### 색상

| 역할 | 값 | 정의/사용 | 감사 |
|---|---:|---|---|
| 기본 배경 | `#FAFAFA` | `SasangColors.background` | 지도 외 기본 scaffold |
| 페이지 배경 | `#F7F7F8` | `pageBackground` | 더보기·정보·상점 |
| 카드 | `#FFFFFF` | `card` | 전 화면 |
| 기본 테두리 | `#E9E9ED` | `border` | 카드/행 |
| 본문 ink | `#18181B` | `ink` | 제목/본문 |
| 보조 텍스트 | `#71717A` | `secondary` | 설명/메타 |
| accent | `#007AFF` | `accent` | 선택/CTA/링크 |
| divider | `#12000000` | `divider` | 약한 구분선 |
| overlay border | `#1A000000` | `SasangOverlayStyle.border` | 떠 있는 표면 |
| 비토큰 보조색 | `#52525B`, `#8E8E93`, `#B4B4BA`, `#C4C4C8` 등 | 여러 파일에 직접 선언 | 회색 단계 의미가 불명확 |

### 간격, 반경, 그림자

| 분류 | 현재 공용 값 | 실제 예외 |
|---|---|---|
| spacing | 4, 8, 12, 16, 24, 32 | 5, 6, 7, 9, 10, 11, 13, 14, 17, 18, 20, 22, 26, 28, 30, 36, 40 |
| radius | pill 999, sheet 30, selection 24, action 24, content 22 | 카드 8/19/20, 시트 28, 버튼 8/15/16/17/18/19, 모달 30, nav 34 |
| overlay shadow | `#1718181B` blur 18/y6 + `#0A18181B` blur 3/y1 | Surface blur20/y7, nav blur18/y8, modal blur28/y12, 앨범 blur24/y10 |

### 타이포그래피

공용 정의는 시트 제목 22/w800, 시트 설명 14/1.45, 옵션 제목 16/w800, 옵션 설명 13/1.4뿐이다. 화면 제목은 21~30, 본문은 11~16, 메타는 10~14로 각 파일에서 직접 정의된다. 동일 계층의 예: 시트 제목이 사진 날짜 21, 사진 앨범 22, 공유 22, 상품 상세 23으로 갈린다.

## 3. 컴포넌트 목록

| 역할 | 파일/위젯 | 현재 값 | 사용 화면 | 불일치·평가 | 위험 |
|---|---|---|---|---|---|
| 앱 테마 | `core/theme/sasang_theme.dart` / `SasangTheme` | Material3 off, Cupertino transition, splash 없음 | 전체 | 색 토큰은 안정적이나 typography/theme component 규칙이 적음 | 전역 변경 영향 큼 |
| 기본 표면 | `widgets/sasang_ui.dart` / `SasangSurface` | radius 기본 18, border .6, blur 18, shadow | 지도 share/zoom | 지도 overlay의 기반으로 적합 | blur 성능과 contrast |
| 주 버튼 | `SasangPrimaryButton` | 높이 52, radius 15, 좌우 18, 15/w800 | 상점, 날짜, 온보딩(56) | 토큰 action radius 24와 불일치 | 번역 길이/disabled contrast |
| 텍스트 버튼 | `SasangTextButton` | 14/w700, 패딩 12×8 | 날짜 취소 | 버튼 높이 고정 없음 | 터치 영역이 부모에 의존 |
| chevron 행 | `SasangChevronRow` | 높이 52, 좌우 16, 15/w700 | 제한적 | 더보기는 별도 60행 구현 | 행 규격 이중화 |
| 공용 시트 | `showSasangSheet` | margin 8, padding 20/10/20/20, radius 28, barrier 28% | 상점 상세, 공유, 앨범 | 토큰 sheet 30과 다름 | 긴 콘텐츠/키보드 |
| 지도 선택 시트 | `_OwnedMapSheet` | top radius 30, max 74%, 별도 header/footer | 지도/장소 필터 | 공용 시트와 다른 계열 | 구매 지도 증가 |
| 날짜 모달 | `showPhotoDateDialog` | margin 8, radius 28, 자체 레이아웃 | 사진 날짜 | 공용 시트를 재사용하지 않음 | 작은 기기 overflow |
| 커스텀 중앙 모달 | `SasangCenterModal` | 폭 82%/max360, radius30, padding30, shadow | 백업 | 시각적으로 과장, Cupertino 확인과 다름 | 큰 글꼴/긴 버튼 |
| 시스템 확인창 | `showSasangConfirmDialog` | `CupertinoAlertDialog` 기본 | 로그아웃/삭제 | 백업/공유 알림과 불일치 | 커스텀화 시 접근성 손실 |
| 하단 내비게이션 | `HomeShell` | 높이66, 좌우18, bottom14+, radius34 | 지도/장소/더보기 | Floating 구조는 유지 대상 | overlay 위치와 결합 |
| 탭 아이템 | `_TabItem` | icon23, label12/w800 | 하단 nav | 선택 색만 변화 | 긴 번역 폭 |
| 지도 상단 요약 | `MapTopBar` | 높이38, radius19, text11/13 | 지도 | 정보 밀도는 좋으나 overlay 수 과다 | 지도 가림 |
| 지도 선택 pill | `MapModeSelector` | 높이38, max168, radius999, text13 | 지도/장소 | 정렬 pill과 유사하지만 별도 구현 | 긴 지도명 |
| 정렬 pill | `_SortButton` | 높이38, radius19, icon13, text13 | 장소 | 현재 방향을 아이콘이 표현 못함 | 상태 지속성 없음/미확인 |
| 지도 검색 | `MapSearchBar` | 높이46, 좌우10, text14 | 지도 | overlay 체계와 일치 | 결과 패널과 지도 가림 |
| 확대 도구 | `RegionMapView` / `_ZoomButton` | 표면 radius24, 각 44×44, 3단 | 지도 | 큰 터치 영역, 유지 대상 | 하단 nav와 위치 결합 |
| 지역 컨트롤 | `MapScreen._regionControl` | 좌우24, padding10×9, title16, thumb42 | 지도 | 지도 문맥을 유지하는 핵심 | 작은 화면 너비 |
| 지도 painter | `RegionMapPainter` | world stroke .18, korea .52, accent 선택선 | 지도 | 제품 고유 핵심 | 좌표/성능/MultiPolygon |
| 더보기 섹션 | `MoreScreen._section` | radius19, border.8, row min60 | 더보기 | 모든 그룹 카드화 | 정보 밀도 |
| 정보 문서 | `_DocumentBody`, `_DocumentSection` | title28, section18, body16/1.68 | 약관/개인정보 | 앱바 제목 중복 | 법적 가독성 |
| 앱 정보 그룹 | `_AppInfoBody`, `_InfoRow` | radius22, row min62 | 앱 정보 | 제품 소개가 큰 편 | 비동기 버전 로드 |
| 라이선스 | Flutter `showLicensePage` | SDK 기본 | 라이선스 | 앱 스타일 불일치 허용 가능 | 재작성 위험 매우 큼 |
| 상점 제품 카드 | `_ProductCard` | radius22, 높이244, preview104 | 지도 상점 | 카드 내부 정보/배지 과밀 | 텍스트 배율/상품 증가 |
| 장소 카드 | `PlacesScreen` inline | radius8, image ratio1.18, shadow | 장소 | 다른 콘텐츠 카드와 반경 불일치 | 이미지 목록 성능 |
| 사진 앨범 시트 | `RegionPhotoAlbumSheet` | header22, carousel310 | 사진 | 사진 중심 구조는 강점 | 빈/보유 상태 공유 |
| 사진 카드 | `_AlbumPhotoCard` | radius24/20, padding5, tilt+shadow | 앨범 | 장식이 중첩됨 | 가로/세로 비율 |
| 사진 추가 카드 | `_AddPhotoCard` | radius24, 높이 부모310, +54 | 빈 앨범 | 과장된 빈 상태 | PageView 높이 결합 |
| 공유 시트 헤더 | `_ShareSheetContent` | handle34×5, title22, close34 | 공유 | 다른 시트 헤더와 닫기 규격 다름 | 다국어 줄바꿈 |
| 공유 형식 행 | `_ExportFormatRow` | min84, preview42×62, title16 | 공유 형식 | chevron/미리보기 강조 중복 | 형식 식별성 |
| 온보딩 언어 옵션 | PR #10 `_LanguageOption` | 높이58, radius17, 선택 border1.4 | 온보딩 | 선택 강조 4중 | PR 미병합 |
| 온보딩 비주얼 | PR #10 `_VisualCard` | 270×250, radius32, shadow blur28/y12 | 온보딩 기능 소개 | 과장된 카드 표현 | 작은 화면/큰 글꼴 |

## 4. 같은 역할의 스타일 충돌

### 4.1 확인 및 경고

| 사례 | 구현 | 차이 |
|---|---|---|
| 백업 확인 | `SasangCenterModal` | 30 반경, 큰 제목 23, 2열 채움 버튼, 강한 그림자 |
| 로그아웃/삭제 | `CupertinoAlertDialog` | SDK 기본 작은 중앙 경고, 텍스트 액션 |
| 공유 빈 상태/백업 실패 | 직접 `CupertinoAlertDialog` | 공용 함수조차 사용하지 않는 변형 |

동일한 “사용자 확인/알림” 역할이 중요도 기준이 아니라 기능별 구현 시점에 따라 갈린다. 후속 설계에서는 정보 알림, 일반 확인, 파괴 확인의 의미 기준으로 계층을 정해야 한다.

### 4.2 Bottom Sheet

| 계열 | 반경/여백 | 핸들 | 닫기 |
|---|---|---|---|
| `showSasangSheet` | 전체 28, 사방 8 | 콘텐츠별 34×5 또는 없음 | 34 원형/36 원형/36 radius8 |
| `_OwnedMapSheet` | 상단 30, 화면 가장자리 | 36×5 | 최소 44, 배경 없음 |
| `showPhotoDateDialog` | 전체 28, 사방 8 | 없음 | 없음, 하단 취소 |

Full-height contextual sheet와 compact modal sheet의 구분은 합리적이지만, 헤더와 닫기 규칙은 역할보다 화면별로 다르다.

### 4.3 버튼

- Primary: 48/52/56 높이, radius 15.
- Modal actions: 높이는 Cupertino 기본, radius 16.
- Empty state: 높이 52, radius 16, 우측 화살표.
- Pills: 높이 38, radius 19/999.
- Close: 34/36/44, radius 8/17/18/원형 없음.
- Photo add: 54 원형.

버튼 종류 자체보다 역할 이름과 규격의 연결이 문서화되지 않은 것이 핵심 문제다.

### 4.4 콘텐츠 카드

- 장소 카드 radius 8
- 더보기 그룹 radius 19
- 빈 상태 radius 20
- 앱 정보/상점 radius 22
- 지도 선택/사진 radius 24
- 온보딩 비주얼 radius 32

사진을 더 또렷하게 보이게 하는 장소 카드의 작은 반경은 의도일 수 있지만, 현재 코드에는 그 근거가 없다. 동일한 흰 배경+테두리+그림자를 무조건 적용하지 말고 카드가 실제 그룹 경계를 만드는지부터 판단해야 한다.

## 5. 구조 의존 관계

```text
HomeShell (IndexedStack + Floating Bottom Navigation)
├─ MapScreen (Full-screen Map)
│  ├─ RegionMapView / RegionMapPainter
│  ├─ MapTopBar + MapModeSelector
│  ├─ MapSearchBar / Results
│  ├─ Floating Region Control
│  └─ Bottom Sheets
│     ├─ RegionPhotoAlbumSheet
│     ├─ PhotoDateDialog
│     └─ Share format/destination
├─ PlacesScreen
│  ├─ MapModeSelector → OwnedMapSheet
│  ├─ SortButton
│  └─ Place cards → RegionPhotoAlbumSheet
└─ MoreScreen
   ├─ Section cards
   ├─ InfoDetailScreen / MapStoreScreen
   └─ Confirm dialogs
```

가장 큰 회귀 결합은 `HomeShell`의 66 높이 하단 바와 지도 overlay 위치 계산(`sasangBottomBarTopOffset`, `sasangMapOverlayBottomOffset`, `sasangZoomControlsBottomOffset`)이다. 시각 개선 시 이 수치를 독립적으로 바꾸면 안 된다.

## 6. 보존/통합 판단표

| 분류 | 판단 | 이유 |
|---|---|---|
| Full-screen Map | 보존 | 제품의 주 콘텐츠이며 사진 클리핑을 가장 크게 보여 줌 |
| Floating Region Control | 보존 | 지도 문맥을 잃지 않고 다음 행동을 연결 |
| Contextual Bottom Sheet | 보존 | 사진/공유/지도 선택의 흐름에 적합 |
| Floating Bottom Navigation | 보존, 충돌 검증 | 3개 핵심 영역 전환이 명확하나 overlay와 결합 |
| 지도 overlay 개수 | 축소/그룹화 검토 | 지도 가시 면적과 시각 초점 침해 |
| 확인창 계열 | 통합 필요 | 같은 역할의 표현이 기능별로 다름 |
| 시트 헤더/닫기 | 통합 필요 | 34/36/44 및 반경 규칙이 분산 |
| 카드/그림자 | 사용 기준 축소 | 보조 화면에서 중첩 강조 발생 |
| LicensePage | 우선 보존 | 표준 기능 재구현 위험이 큼 |
| 온보딩 큰 비주얼 카드 | 단순화 검토 | 실제 기능보다 장식이 앞섬 |

## 7. 후속 설계 시 검증 체크리스트

- 지도 확대/이동/지역 탭이 모든 overlay 주변에서 동작하는가.
- 하단 바, 지역 컨트롤, 줌 도구가 safe area와 겹치지 않는가.
- 사진 없는 상태와 여러 장 상태가 같은 시트 높이 변경을 견디는가.
- 한국어/영어/일본어/중국어 및 접근성 글꼴 배율에서 제목과 2열 버튼이 잘리지 않는가.
- destructive/disabled/selected 상태가 색상 이외 수단으로도 구분되는가.
- 변경된 카드/그림자 수가 사진과 지도의 시각 우선순위를 강화하는가.
- SDK 기본 컴포넌트를 대체했다면 스크린리더, 포커스, 키보드, 플랫폼 동작을 보존했는가.

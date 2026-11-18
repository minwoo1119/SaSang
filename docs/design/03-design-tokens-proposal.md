# Sasang 디자인 토큰 제안

## 1. 적용 원칙

- 토큰 이름은 시각값(`gray500`, `radius24`)보다 의미(`textSecondary`, `radiusSelection`)를 우선한다.
- 현재의 화이트·블루 팔레트를 유지한다.
- 표의 “현재값”은 Phase 1 감사에서 확인한 대표값이며 화면별 예외가 있으면 함께 적는다.
- “최종값”은 Phase 2-A 제안값이다. Flutter 적용은 별도 승인 이후 진행한다.
- 값 변경이 없는 토큰도 현재 의도가 유지되어야 한다는 의미로 포함한다.

## 2. Semantic Color

| 토큰 이름 | 현재 코드 값 | 제안 최종값 | 적용 컴포넌트 | 변경 이유 | 기존 UI 영향 |
|---|---|---|---|---|---|
| `color.canvas` | `#FAFAFA` | `#FAFAFA` | 기본 scaffold, 페이지 배경 | 브랜드 중립 배경 유지 | 없음 |
| `color.canvasSubtle` | `#F7F7F8` | `#F7F7F8` | 더보기, 정보, 상점 | 계층이 이미 안정적 | 없음 |
| `color.surface` | `#FFFFFF` | `#FFFFFF` | 카드, floating, dialog | 사진과 지도 대비 유지 | 없음 |
| `color.surfaceSubtle` | `#F4F4F5`, `#F6F8FB`, `#F4F7F9` | `#F4F4F5` | close 배경, disabled/empty 보조면 | 유사 직접값 통합 | 빈 상태/preview의 푸른 기운 감소 |
| `color.textPrimary` | `#18181B` | `#18181B` | 제목, 핵심 본문 | 현재 대비 유지 | 없음 |
| `color.textSecondary` | `#71717A`, 일부 `#52525B` | `#52525B` | 본문 설명, 지역 보조 정보 | 작은 글자 대비 강화 | 기존 보조 텍스트가 약간 진해짐 |
| `color.textTertiary` | `#8E8E93`, `#B4B4BA`, `#C4C4C8` | `#8E8E93` | caption, 비핵심 icon | 회색 단계 축소 | 아주 옅은 chevron이 선명해짐 |
| `color.tertiaryTextAccessible` | 별도 값 없음; `#8E8E93` 사용 시 white 대비 약 3.26:1 | `#636366`(white 대비 약 5.99:1) | 14sp 미만 tertiary 일반 텍스트 | WCAG AA 4.5:1 확보 | 새/이전 텍스트만 진해지며 기존 화면 변화 없음 |
| `color.accent` | `#007AFF` | `#007AFF` | CTA, 선택, 링크 | Sasang의 블루 정체성 | 없음 |
| `color.accentText` | 별도 값 없음; `#007AFF`의 white 대비 약 4.02:1 | `#0066CC`(white 대비 약 5.57:1) | 작은 링크/강조 일반 텍스트 | WCAG AA 4.5:1 확보 | 새/이전 작은 텍스트만 더 어두워짐 |
| `color.accentSoft` | `#EAF4FF`, `#EAF3FF`, `#1A007AFF` | `#EAF4FF` | 선택 배경, 아이콘 보조면 | 선택 보조색 통합 | 미세 색 차이 제거 |
| `color.borderSubtle` | `#E9E9ED`, divider `#12000000` | `#E9E9ED` | 정적 카드, divider | 밝은 배경의 안정적 구분 | divider가 필요한 곳은 opacity variant 사용 |
| `color.borderFloating` | `#1A000000` | `#1A000000` | 지도 floating surface | 지도 위 경계 유지 | 없음 |
| `color.borderSelected` | accent alpha 72%, 100% 혼재 | `#007AFF` 72% | selection card | 사진/미리보기와 경쟁 완화 | 선택선이 약간 부드러움 |
| `color.destructive` | `CupertinoColors.systemRed` | 플랫폼 system red semantic | 삭제/초기화 | 플랫폼 대비·접근성 유지 | 외형은 플랫폼별 미세 차이 |
| `color.destructiveText` | 별도 값 없음; system red `#FF3B30`의 white 대비 약 3.55:1 | `#D70015`(white 대비 약 5.38:1) | 작은 파괴적 action 텍스트 | WCAG AA 4.5:1 확보 | 새/이전 작은 텍스트만 더 어두워짐 |
| `color.scrimSheet` | black 28~30% | black 28% | Bottom Sheet | 값 통합 | 거의 없음 |
| `color.scrimDialog` | black 34%(0x57) 및 SDK 기본 | black 34% 목표 | custom dialog/progress | 중앙 모달 초점 유지 | 시스템 dialog 내부 scrim은 SDK 우선 |
| `color.disabledSurface` | `#E4E4E7` | `#E4E4E7` | disabled button | 현재 상태 인지 유지 | 없음 |
| `color.disabledContent` | 명시 없음/SDK 기본 | `#8E8E93` | disabled text/icon | 비활성 의미 명시 | 일부 버튼 텍스트가 회색으로 보임 |
| `color.errorSoft` | 없음 | system red 10% | field/inline error 배경 | 오류를 destructive action과 구분 | 신규 상태에만 영향 |

## 3. Typography

공통 글꼴은 플랫폼 기본 sans-serif를 사용한다. 한국어/일본어/중국어에는 강한 음수 자간을 적용하지 않고, 영문도 같은 토큰을 사용한다. 행간은 Flutter `height` 환산 시 실제 font metrics를 골든 테스트로 확인한다.

| 토큰 이름 | 현재 코드 값 | 제안 최종값 | 적용 컴포넌트 | 변경 이유 | 기존 UI 영향 |
|---|---|---|---|---|---|
| `type.display` | 온보딩 27, 더보기 30, 문서 28 | 28/34, w800, letter -0.4(KO 0 권장) | 온보딩/브랜드 강조만 | w800을 브랜드 강조에 제한 | 더보기는 `pageTitle`로 내려감 |
| `type.pageTitle` | 24/26/28/30, w700~800 혼재 | 28/34, w700 | 더보기, 문서 본문 제목 | 모든 제목의 w800 강제 방지 | 더보기 30→28 후보, 기존 화면은 이번 단계 미적용 |
| `type.navTitle` | 17/w700 | 17/22, w700 | Cupertino nav bar | 표준 계층 유지 | 없음 |
| `type.sheetTitle` | 21/22/23 | 22/28, w800 | 5종 Bottom Sheet | 1dp 차이 제거 | 날짜 +1, 상품 -1 |
| `type.sectionTitle` | 15/18 | 18/24, w700 | 문서/상점 큰 섹션 | 주요 섹션 통일 | 더보기의 작은 group label은 별도 토큰 |
| `type.groupLabel` | 더보기 15/w700, map group 12 | 14/20, w700 | 설정 그룹, 분류 레이블 | 콘텐츠 제목과 구분 | 더보기 15→14 |
| `type.optionTitle` | 15/16 | 16/22, w700 | 선택 행, 카드 제목 | w800 과강조 완화 | 공유/장소 제목이 조금 가벼워짐 |
| `type.body` | 일반 설명 14/15, 일부 본문 16 | 15/23, w400 | 일반 설명과 앱 본문 | 모바일 가독성과 밀도 균형 | 법적 문서는 영향 없음 |
| `type.legalBody` | 법적 문서 16/line 1.68 | 16/line 1.68, w400 | 개인정보 처리방침, 이용약관 | 일반 본문과 분리해 법적 가독성 보존 | 기존 법적 문서 값 유지 |
| `type.bodyStrong` | 15/16 w600~700 | 15/22, w700 | 설정 행, 중요한 값 | 역할 명시 | 더보기 행 16→15 가능 |
| `type.supporting` | 13/14 | 13/19, w400~600 | sheet 설명, 날짜, 지역 보조 | 값 통합 | 미세 행간 정리 |
| `type.caption` | 10/11/12 | 12/16, w600 | count, badge, 날짜 | 10/11의 과소 크기 완화 | 상점 badge와 지도 count가 커짐 |
| `type.micro` | 지도 통계 11, 제품 badge 10 | 11/14, w700, 제한 사용 | 공간 제한 지도 통계만 | caption으로 올리기 어려운 예외 | 제품 badge는 caption으로 이동 |
| `type.button` | 14/15/16 w700~800 | 15/20, w700 | primary/secondary/destructive | 버튼 계층 통합 | w800→700로 다소 차분해짐 |
| `type.tabLabel` | 12/w800 | 12/16, w700 | 하단 nav | 과한 굵기 완화 | 탭이 조금 덜 무거움 |

## 4. Spacing

모든 간격을 8dp 배수로 강제하지 않는다. 4dp 기본 리듬과 관계 밀도를 기준으로 한다.

| 토큰 이름 | 현재 코드 값 | 제안 최종값 | 적용 컴포넌트 | 변경 이유 | 기존 UI 영향 |
|---|---|---|---|---|---|
| `space.optical` | 2, 3 산발적 | 2 | divider/아이콘 광학 보정만 | 임의 미세값 제한 | 거의 없음 |
| `space.xs` | 4/5/6/7 | 4 | title 내부, badge | 기본 최소 리듬 | 5~7 값 정리 |
| `space.close` | 5/6/7 | 6 | 제목-설명, 메타 행 | 가까운 관계 표현 | 미세 조정 |
| `space.sm` | 8/9/10 | 8 | 아이콘-텍스트, action gap | 반복값 통합 | 9/10 감소 |
| `space.md` | 11/12/13/14 | 12 | 행 내부, 카드 소간격 | 중간 리듬 | 미세 조정 |
| `space.lg` | 16/17/18 | 16 | 화면/카드 기본 패딩 | 가장 빈번한 패딩 통합 | 일부 1~2dp 감소 |
| `space.sheet` | 20 | 20 | sheet 좌우/하단 | 유형별 적정 밀도 | 없음 |
| `space.xl` | 22/24/26/28 | 24 | 문서 좌우, 주요 블록 | 큰 간격 축소 | 일부 화면 여백 정돈 |
| `space.2xl` | 30/32/36 | 32 | 섹션 간 | 일관된 큰 리듬 | 36→32 |
| `space.3xl` | 40 | 40 | 브랜드/문서 큰 분리 | 의도적 큰 간격 유지 | 없음 |
| `inset.mapOverlay` | 16 | 16 | 지도 상단/좌우 | 지도 도구 정렬 기준 | 없음 |
| `inset.page` | 16/22/24 | 20 기본, 유형 예외 16/24 | 일반 페이지 | 22 같은 중간값 제거 | 더보기 좌우 22→20 제안 |
| `inset.document` | 24 | 24 | 약관/정보 | 긴 글 가독성 | 없음 |

## 5. Corner Radius

| 토큰 이름 | 현재 코드 값 | 제안 최종값 | 적용 컴포넌트 | 변경 이유 | 기존 UI 영향 |
|---|---|---|---|---|---|
| `radius.media` | 장소 8, close 8 | 8 | 사진 중심 장소 카드/작은 preview | 이미지 모서리 예외 보존 | 장소 카드 즉시 변경 없음 |
| `radius.compact` | 10/11/12/14 | 12 | badge, 작은 preview | 작은 요소 통합 | 미세 변화 |
| `radius.control` | 15/16/17/18 | 16 | 일반 버튼과 입력 컨테이너 | 컨트롤 값 통합 | primary 15→16 |
| `radius.search` | 지도 검색 및 selector의 pill 형태 | `radius.pill` | 지도 검색창, 지도 선택/정렬 pill | 검색창을 일반 control 16으로 평탄화하지 않음 | 기존 pill 외형 유지 |
| `radius.settingsGroup` | 19 | 20 | 더보기/정보 그룹 | 그룹형 카드 정체성 유지 | 거의 없음 |
| `radius.contentCard` | 20/22 | 22 | 상품/정보/empty container | 기존 토큰 유지 | 빈 카드 20→22 가능 |
| `radius.selectionCard` | 24 | 24 | 지도 선택, 사진 카드 | 선택 가능한 큰 단위 | 없음 |
| `radius.sheet` | 28/30 | 28 | floating/attached sheet 외곽 | 공통 shell 통합 | 지도 library 30→28 |
| `radius.dialog` | 30 | 28 | custom dialog/progress | 시트와 같은 곡률 계열, 과장 완화 | 중앙 카드가 조금 단정해짐 |
| `radius.nav` | 34 | 34 | Floating Bottom Navigation | 고유 silhouette 보존 | 없음 |
| `radius.pill` | 19/999 | full (`999`) | 38 높이 pill, badge | 높이에 종속된 완전 원형 | 외형 거의 동일 |

## 6. Border

| 토큰 이름 | 현재 코드 값 | 제안 최종값 | 적용 컴포넌트 | 변경 이유 | 기존 UI 영향 |
|---|---|---|---|---|---|
| `border.hairline` | .5/.6 | 0.5 logical 또는 device hairline | nav/divider | 플랫폼 픽셀 정렬 | 거의 없음 |
| `border.subtle` | .6/.7/.8 | 0.75 | 정적 카드 | 유사값 통합 | 육안 변화 미미 |
| `border.floating` | .6 | 0.75 | 지도 overlay | 지도 위 경계 안정 | 미세 선명화 |
| `border.selected` | 1/1.2/1.4 | 1.25 | selection card | 상태 강조 통합 | 온보딩 1.4→1.25 |
| `border.focus` | 명시 없음 | 2 | keyboard/accessibility focus | Android/키보드 접근성 | 신규 상태 |
| `divider.inset` | padding 16/18 | component별 16 또는 20 | settings/list | shell padding과 정렬 | 일부 divider 길이 변화 |

## 7. Elevation / Shadow

Flutter 구현 시 토큰은 한 개 또는 두 개의 `BoxShadow` 묶음으로 제공한다.

| 토큰 이름 | 현재 코드 값 | 제안 최종값 | 적용 컴포넌트 | 변경 이유 | 기존 UI 영향 |
|---|---|---|---|---|---|
| `elevation.none` | 일부 카드 border only | shadow 없음 | settings/content static | 불필요한 부유감 제거 | 정적 카드가 평평해짐 |
| `elevation.low` | 장소/Surface blur20 y7 | `#0F18181B` blur12 y4 + `#08000000` blur2 y1 | 장소 사진, 선택 preview | 콘텐츠 분리만 제공 | 그림자 강도 감소 |
| `elevation.floating` | 2중 blur18 y6/blur3 y1 | 현행 2중 shadow 유지 | 지도 overlay, nav | Floating 정체성 핵심 | 없음 |
| `elevation.modal` | `#16000000` blur28 y12 | `#14000000` blur24 y10 | dialog/progress | 과장 완화, 초점 유지 | 중앙 모달 그림자 감소 |
| `elevation.photo` | `#2218181B` blur24 y10 | `#1418181B` blur16 y6 | 앨범 photo card | 사진보다 장식이 앞서지 않게 함 | 폴라로이드 효과 완화 |
| `blur.floating` | sigma 18 | sigma 16, fallback alpha .96 | 지도 표면 | 비용 약화, 정체성 유지 | 배경 blur가 약간 감소 |

## 8. Interactive State

| 토큰 이름 | 현재 코드 값 | 제안 최종값 | 적용 컴포넌트 | 변경 이유 | 기존 UI 영향 |
|---|---|---|---|---|---|
| `state.pressedOpacity` | .62 및 Cupertino 기본 | .72 content / .64 destructive | 모든 button wrapper | 과도한 깜빡임 완화 | press가 조금 부드러움 |
| `state.selectedSurface` | accent soft 여러 값 | `color.accentSoft` | 선택 카드 | 일관된 선택 배경 | 색 통합 |
| `state.selectedBorder` | accent 72~100% | accent 72%, 1.25 | 선택 카드 | 강조 신호 2개 제한 | 체크/글자색 일부 제거 가능 |
| `state.disabledOpacity` | disabled color 중심 | content 45%, surface 고정 | 버튼/행 | 상태 규칙 명시 | disabled icon/text 통일 |
| `state.hoverOverlay` | 사실상 없음 | accent 4% (pointer 환경만) | Android tablet/web 가능 영역 | 포인터 피드백 | 모바일 영향 없음 |
| `state.focusRing` | 없음 | accent 2px + 2px gap | keyboard focusable | 접근성 | 신규 표시 |
| `state.errorBorder` | 없음 | destructive 1.25 | 입력/선택 오류 | 오류 상태 분리 | 신규 상태 |
| `state.loading` | 개별 spinner/progress | content 유지+action 잠금+progress semantic | 버튼/dialog | 중복 탭 방지 | 로딩 표현 통일 |
| `state.minTarget` | 34/36/38 시각 크기 | hit target 최소 44 | close/pill/icon button | 접근성 | 시각 크기는 유지 가능 |

## 9. Motion / Animation

| 토큰 이름 | 현재 코드 값 | 제안 최종값 | 적용 컴포넌트 | 변경 이유 | 기존 UI 영향 |
|---|---|---|---|---|---|
| `motion.instant` | 없음 | 100ms, easeOut | pressed/color feedback | 즉각 반응 | 더 일관된 press |
| `motion.standard` | 180ms 다수 | 180ms, easeOutCubic | selection, switch, fade | 현행 좋은 기준 유지 | 없음 |
| `motion.modalEnter` | 180ms fade+scale .96 | 200ms, easeOutCubic, .98→1 + fade | dialog/progress | scale 과장 축소 | 중앙 모달 움직임 차분 |
| `motion.modalExit` | 180ms easeInCubic | 160ms, easeInCubic | dialog/sheet dismiss | 빠른 종료 | 닫힘이 약간 빨라짐 |
| `motion.sheet` | SDK/개별 | 280ms, emphasized decelerate | custom sheet shell | 유형 간 속도 통일 | 시트 전환 일관 |
| `motion.page` | onboarding 280ms | 280ms, easeOutCubic | page/step | 현행 유지 | 없음 |
| `motion.map` | InteractiveViewer 기본 | 기존 물리/행렬 유지 | pan/zoom | 지도 감각 보존 | 없음 |
| `motion.reduce` | 미확인 | scale/rotation 제거, fade≤100ms | 전체 | 접근성 설정 존중 | reduce motion 사용자만 영향 |

## 10. 토큰 적용 경계

- 시스템 컴포넌트 내부 수치까지 강제로 덮어쓰지 않는다. `LicensePage`, `CupertinoDatePicker`, 플랫폼 share UI가 해당한다.
- 지도 painter의 stroke width와 photo opacity는 디자인 토큰이 아니라 지도 렌더링 도메인 값으로 유지한다.
- safe area, 하단 바 높이 66, map overlay overlap 36, zoom offset 136은 레이아웃 계약이다. 시각 토큰으로 흡수하지 않는다.
- 장소 카드 radius 8은 `radius.media` 예외로 유지하고 실기 비교 후 별도 결정한다.
- Phase 2-B에서는 장소 카드 radius 8을 변경하거나 비교 후보를 적용하지 않는다.
- Bottom Sheet 배경은 `color.surface #FFFFFF`를 사용한다. `color.canvas`는 sheet 바깥
  페이지와 지도 라이브러리 주변 배경의 의미로 한정한다.
- 사진/영상 내보내기 및 내 지도 Bottom Sheet의 콘텐츠 구성은 Token Foundation 범위에서
  변경하지 않는다.
- PR #10 온보딩은 현재 병합됐지만 Phase 2-B 적용 범위에서는 제외하며 별도 승인을 받는다.

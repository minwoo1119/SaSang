# Sasang Design Token Foundation 구현 기록

## 1. 범위

Phase 2-B는 기존 화면이 참조하는 토큰의 값과 컴포넌트 구현을 바꾸지 않고, 새 UI와
점진적 마이그레이션에서 사용할 Semantic Token API를 추가한다. Bottom Sheet/Dialog
리팩터링, 전 화면 적용, 지도/사진/데이터 로직 변경은 포함하지 않는다.

## 2. 기존 토큰과 Semantic Token 매핑

| 기존 공개 API | Semantic API | 값/관계 | 비고 |
|---|---|---|---|
| `SasangColors.background` | `SasangSemanticColors.canvas` | `#FAFAFA` alias | 기존 API 유지 |
| `pageBackground` | `canvasSubtle` | `#F7F7F8` alias | 기존 API 유지 |
| `card` | `surface` | `#FFFFFF` alias | Sheet도 이 white surface 사용 |
| `ink` | `textPrimary` | `#18181B` alias | AA 충족 |
| `secondary` | `textSecondary` | 기존 `#71717A` 유지 / 신규 `#52525B` | 기존 API는 호환, 새 일반 설명은 더 높은 대비 |
| 없음 | `tertiaryTextAccessible` | `#636366` | 작은 텍스트용, `#8E8E93` 대체 |
| `accent` | `accent` | `#007AFF` alias | icon/selection/large content |
| 없음 | `accentText` | `#0066CC` | 작은 일반 텍스트용 AA alias |
| system red | `destructive`, `destructiveText` | `#FF3B30`, `#D70015` | 비텍스트/큰 표현과 작은 텍스트 분리 |
| `border` | `borderSubtle` | `#E9E9ED` alias | 기존 API 유지 |
| `divider` | `divider` | `#12000000` alias | 기존 API 유지 |
| `SasangSpacing.*` | 동일 의미 `SasangSemanticSpacing.*` | 4/8/12/16/24/32 alias | 기존 scale 유지 |
| 없음 | `optical`, `close`, `sheet`, `xxxLarge` | 2/6/20/40 | 의도된 예외 |
| `SasangRadii.contentCard` | `SasangSemanticRadii.contentCard` | 22 alias | 기존 API 유지 |
| `selectionCard` | `selectionCard` | 24 alias | 내 지도 카드 유지 |
| `pill` | `pill`, `search` | 999 alias | 지도 검색 pill 유지 |
| 없음 | `media` | 8 | 장소 카드 현행값 고정 |
| 없음 | `control` | 16 | 일반 버튼용, 검색 제외 |
| `SasangTypography.sheetTitle` | `SasangSemanticTypography.sheetTitle` | 22/28 w800 | 새 역할 API, 기존값 미변경 |
| 없음 | `pageTitle` | 28/34 w700 | 모든 제목 w800 방지 |
| 없음 | `legalBody` | 16/1.68 w400 | 법적 문서 전용 |
| `SasangOverlayStyle.shadows` | `SasangElevation.floating` | 기존 list alias | 기존 Floating 외형 유지 |
| 없음 | `SasangBorders` | .5/.75/1.25/2 | 역할별 border API |
| 없음 | `SasangMotion` | 100/180/200/160/280ms | 역할별 duration/curve |
| 없음 | `SasangComponentState(s)` | 상태 enum/색/opacity/44 target | 새 컴포넌트 상태 API |

## 3. 대비 검증

Flutter의 `Color.computeLuminance()`와 WCAG 대비 공식으로 white `#FFFFFF`, canvas
`#FAFAFA`, subtle canvas `#F7F7F8`를 모두 검사한다.

| 색상 | white 기준 | 판단/사용 |
|---|---:|---|
| 기존 accent `#007AFF` | 약 4.02:1 | 작은 일반 텍스트 AA 미달; icon/selection/큰 텍스트 유지 |
| `accentText #0066CC` | 약 5.57:1 | 작은 링크/강조 텍스트 AA 통과 |
| 기존 tertiary `#8E8E93` | 약 3.26:1 | 작은 일반 텍스트 AA 미달; 장식/disabled에 제한 |
| `tertiaryTextAccessible #636366` | 약 5.99:1 | 작은 tertiary 텍스트 AA 통과 |
| 기존 secondary `#71717A` | 약 4.83:1 | light surface의 일반 텍스트 AA 통과 |
| `textSecondary #52525B` | 약 7.73:1 | 새 일반 설명 텍스트 AA 통과 |
| system red `#FF3B30` | 약 3.55:1 | 작은 일반 텍스트 AA 미달; icon/큰 표현에 제한 |
| `destructiveText #D70015` | 약 5.38:1 | 작은 파괴적 action 텍스트 AA 통과 |

자동 테스트는 세 light surface 모두에서 접근성 alias와 secondary가 4.5:1 이상인지
검증한다.

## 4. Golden 기준선

### 신규 기준선

| 파일 | 실제 위젯 | 고정 상태 |
|---|---|---|
| `map_floating_controls.png` | `MapTopBar`, `MapModeSelector`, `SasangSurface` | 3/161, 대한민국 지도, 공유 활성 |
| `settings_group_cards.png` | `MoreScreen` | 한국어, 광고 placeholder, 설정/지도/정보/계정 그룹 |
| `primary_button_states.png` | `SasangPrimaryButton` | 활성/비활성 |

### 기존 기준선 재사용

| 파일 | 범위 |
|---|---|
| `owned_map_sheet.png` | 내 지도 2열 선택 카드와 library Bottom Sheet shell |
| `adaptive_export_format_picker.png` | 사진/영상 내보내기 Bottom Sheet와 콘텐츠 구성 |
| `north_korea_confirmation.png` | 중앙 Confirmation Dialog |
| `backup_progress.png` | 중앙 Progress Dialog |
| `export_progress_*.png` | Progress 단계/오류 상태 |

### 결정성과 한계

- surface size는 390×844 또는 컴포넌트별 고정 높이, platform은 테스트별 iOS/Android로
  고정한다.
- SUIT Heavy와 Cupertino icon font를 명시적으로 로드한다.
- 실제 사용자 사진, 파일 시스템 이미지, 광고 응답과 네트워크를 사용하지 않는다.
- 내 지도 preview는 저장소의 번들 map asset을 사용하므로 지도 자산이 의도적으로
  갱신되면 golden도 함께 검토해야 한다.
- `settings_group_cards`의 광고는 실제 광고가 아닌 테스트 placeholder다.
- Golden은 테스트 환경의 rasterizer/font 차이에 민감할 수 있다. CI/로컬 Flutter 버전을
  프로젝트 기준과 맞추고, 실패 시 무조건 갱신하지 말고 diff를 검토한다.
- 실제 사진 clipping과 모든 지도 확대 상태는 이번 컴포넌트 기준선 범위 밖이며 기존 지도
  로직 테스트와 Phase 1 캡처가 보완한다.

## 5. 변경 파일

| 파일 | 변경 |
|---|---|
| `lib/core/theme/sasang_theme.dart` | 기존 토큰을 유지하고 Semantic Color/Typography/Spacing/Radius/Border/Elevation/Motion/State API 추가 |
| `test/design_tokens_test.dart` | alias 호환성, 대비, typography, component state 검증 |
| `test/visual_review_test.dart` | 지도 Floating Control, 설정 그룹, 버튼 Golden 추가 |
| `test/goldens/*.png` | 신규 기준선 3장 |
| `docs/design/02~05-*.md` | Phase 2-A 승인 보완사항 반영 |
| `docs/design/06-token-foundation.md` | 매핑, 기준선, 한계, 검증 기록 |

## 6. 검증 결과

최종 명령과 결과는 작업 완료 시 갱신한다. 성공하지 않았거나 실행할 수 없는 플랫폼
검증은 성공으로 표기하지 않는다.

| 검증 | 결과 |
|---|---|
| 신규/기존 Golden 생성 및 육안 확인 | 통과 — 기존 8장 변화 없음, 신규 3장 확인 |
| Semantic Token 단위 테스트 | 통과 — alias/대비/typography/state 4개 테스트 |
| `flutter analyze` | 통과 — 이슈 0건 |
| `flutter test` | 통과 — Golden 비교 포함 79건 |
| Android debug build | 통과 — `build/app/outputs/flutter-apk/app-debug.apk` |
| iOS simulator build | 통과 — `build/ios/iphonesimulator/Runner.app` |

## 7. 공개 API 호환성

- `SasangColors`, `SasangSpacing`, `SasangRadii`, `SasangTypography`,
  `SasangOverlayStyle`, `SasangTheme.light`를 삭제하거나 이름/값을 바꾸지 않았다.
- 새 API는 같은 `sasang_theme.dart`에서 additive하게 제공한다.
- 기존 위젯은 새 Semantic Token을 자동 참조하지 않으므로 현재 화면 외형이 바뀌지 않는다.
- 새 컴포넌트는 `SasangSemantic*`, `SasangBorders`, `SasangElevation`, `SasangMotion`,
  `SasangComponentStates`를 사용할 수 있다.

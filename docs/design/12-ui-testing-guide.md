# UI 테스트 및 검증 가이드

## 1. 로컬 필수 명령

```bash
dart run tool/check_design_style.dart
flutter analyze
flutter test
```

UI 기준 테스트만 직렬로 실행하려면 다음 명령을 사용한다.

```bash
flutter test \
  test/design_tokens_test.dart \
  test/migration_test.dart \
  test/ui_quality_test.dart \
  test/visual_review_test.dart \
  --concurrency=1
```

`pnpm design:check`, `pnpm test:ui`도 같은 검사를 실행한다.

## 2. 테스트 역할

| 테스트 | 책임 |
|---|---|
| `design_tokens_test.dart` | alias 호환성, WCAG 대비, typography/state token 계약 |
| `migration_test.dart` | 지도·사진·설정·시트·Dialog의 기능과 플랫폼 variant |
| `ui_quality_test.dart` | 네 언어, text scale 1.0/1.3/2.0, 320×568 overflow, 광고 높이 |
| `visual_review_test.dart` | Floating Control, 카드, 버튼, Sheet, Dialog Golden |
| `integration_test/map_share_integration_test.dart` | Android/iOS 이미지·H.264 실제 인코딩 |

## 3. Golden Test 운영

- Golden은 디자인 회귀 기준이며 일반 기능 수정 때문에 자동 갱신하지 않는다.
- 실패하면 `test/failures/` diff를 먼저 확인하고 의도된 변경인지 판단한다.
- 의도된 UI 변경만 `flutter test --update-goldens`로 갱신한다.
- 변경 전 기준과 갱신 후 이미지를 PR에서 비교하고, 영향받은 component/state를 적는다.
- 실제 사진, 광고, 시간, 네트워크는 고정 fixture/placeholder로 대체한다.
- 지도 asset 변경으로 preview가 달라지면 지도 데이터 버전과 Golden을 함께 검토한다.

## 4. 수동 검증 행렬

| 축 | 최소 값 |
|---|---|
| 플랫폼 | iOS, Android |
| 언어 | ko, en, ja, zh-CN |
| 글꼴 배율 | 1.0, 1.3, 2.0 |
| 화면 | 320×568 소형, 대표 휴대폰 |
| 상태 | default, selected, disabled, loading, error 중 변경 범위 |
| 지도 | pan/zoom/선택과 Floating UI hit 충돌 |
| Sheet | 열림/스크롤/닫기/keyboard/safe area |

모든 조합의 수동 캡처가 항상 필요한 것은 아니다. 변경 위험에 따라 자동 행렬을 우선하고, 가장 긴
번역·가장 큰 글꼴·가장 작은 화면과 양 플랫폼 대표 상태는 반드시 확인한다. 실행하지 못한 항목은
성공으로 기록하지 않는다.

## 5. 스타일 검사와 예외

`tool/check_design_style.dart`는 `lib/**/*.dart`의 새 raw color, named color, radius, shadow,
font size, gap/inset, motion을 기존 baseline과 비교한다.

```bash
dart run tool/check_design_style.dart
```

- 기존 451개 finding은 migration debt이며 새 사용의 근거가 아니다.
- 기존 raw style을 제거하면 baseline entry가 남아도 검사는 통과한다. 후속 정리 PR에서 baseline을
  재생성해 감소분을 반영한다.
- 새 raw style은 실패한다. 먼저 Semantic Token 또는 공통 컴포넌트를 사용한다.
- 정당한 예외만 `// sasang-design-exception: <구체적 이유>`로 허용한다.
- `--update-baseline`은 리뷰된 baseline 변경에만 사용하며 CI 회피용으로 사용하지 않는다.

## 6. CI

`.github/workflows/flutter-ui-quality.yml`은 `dev`/`main` 대상 UI 관련 PR에서 다음을 실행한다.

1. Flutter 3.35.3 의존성 설치
2. 디자인 style guard
3. `flutter analyze`
4. token, migration, accessibility, Golden Test 직렬 실행

Golden rasterizer 차이를 줄이기 위해 지원되는 `macos-15` runner와 프로젝트 Flutter 버전을
고정한다. CI 통과는 실제 iOS/Android 실행을 대체하지 않으며, 플랫폼 build/integration은 변경
위험에 따라 PR에서 별도로 수행한다.

## 7. PR 증거

- 시각 변경: 변경 전/후 또는 주요 상태를 에뮬레이터·시뮬레이터·실기기에서 직접 캡처한다.
- 경로: `docs/pr-screenshots/<issue-number>/<state>.png`
- PR 본문: 캡처 환경, 언어, 글꼴 배율, 상태를 적는다.
- 비시각 변경: `해당 없음 — 사유`를 명시한다.
- 토큰/공통 component 변경: 영향 화면과 Golden 목록을 추가한다.

# Sasang 디자인 시스템

이 디렉터리의 공식 문서는 Sasang Flutter UI를 새로 만들거나 변경할 때 적용하는 기준이다.
기본 방향은 화이트·블루, Full-screen Map, Floating Overlay, 사진 중심의 현재 제품 정체성을
보존하면서 역할 기반 토큰과 재사용 컴포넌트로 일관성을 높이는 것이다.

## 작업 전 필수 읽기

| 목적 | 공식 문서 |
|---|---|
| 디자인 원칙 | [02-design-principles.md](02-design-principles.md) |
| 최종 디자인 토큰 | [03-design-tokens-proposal.md](03-design-tokens-proposal.md) |
| 공통 컴포넌트와 재사용 API | [09-common-components.md](09-common-components.md) |
| Variant와 상태 | [04-component-variants.md](04-component-variants.md) |
| 화면별 예외 | [10-screen-exceptions.md](10-screen-exceptions.md) |
| 신규 UI 구현 절차와 예시 | [11-ui-implementation-guide.md](11-ui-implementation-guide.md) |
| UI 테스트·검증·CI | [12-ui-testing-guide.md](12-ui-testing-guide.md) |

신규 UI 작업은 위 문서를 순서대로 확인한다. 실제 값과 public API가 문서와 다르면
`lib/core/theme/sasang_theme.dart`와 현재 Flutter 구현을 먼저 확인하고, 불일치를 같은 PR에서
문서화한다.

## 문서 성격

- `00`, `01`: Phase 1 당시 화면 감사와 inventory. 변경 전 근거 자료다.
- `02`, `03`, `04`, `09`~`12`: 현재 공식 개발 기준이다.
- `05`: 단계적 migration 계획이다. 아직 이전되지 않은 기존 화면을 추적한다.
- `06`, `07`, `08`: Token Foundation, Phase 4-A, Phase 5의 구현·검증 기록이다.

공식 기준은 기존 화면의 미완료 migration을 완료된 것으로 선언하지 않는다. Phase 5 기준 완전/부분
가중 적용률은 43.3%이며, 기존 부채는 baseline에 남겨 두되 새 하드코딩은 허용하지 않는다.

## 빠른 시작

```bash
dart run tool/check_design_style.dart
flutter analyze
flutter test test/design_tokens_test.dart test/migration_test.dart \
  test/ui_quality_test.dart test/visual_review_test.dart --concurrency=1
```

UI PR은 `.github/PULL_REQUEST_TEMPLATE.md`의 디자인 시스템 체크리스트, 양 플랫폼 검증,
변경 전후 스크린샷 규칙을 따른다.

# Sasang 디자인 시스템 마이그레이션 계획

## 1. 범위와 전제

이 문서는 승인 이후 수행할 구현 순서를 제안한다. 이번 Phase 2-A에서는 어떤 Flutter UI 코드도 변경하지 않는다.

- 기준: Phase 1 감사 문서와 Phase 2-A 원칙/토큰/Variant
- 브랜치 전략: 단계별 이슈와 PR 분리
- 금지: 한 PR에서 전 화면 일괄 변환, 지도 구조 변경, 기능 삭제
- 온보딩: PR #10 병합 후 별도 이슈로 다룸
- `LicensePage`: 원칙적으로 마이그레이션 제외
- 장소 카드 8dp: 비교 캡처와 사용자 승인 전 유지

## 2. 우선순위

| 단계 | 우선순위 | 목표 | 시각 변화 | 주요 위험 |
|---|---|---|---|---|
| 0 | P0 | 회귀 기준/골든 확보 | 없음 | 기준 화면 누락 |
| 1 | P1 | 토큰과 semantic API 기반 | 없음~미세 | 전역 값 오적용 |
| 2 | P1 | Sheet shell 통합 | 중간 | 작은 화면 overflow |
| 3 | P1 | Dialog variant 통합 | 중간 | 플랫폼 접근성 손실 |
| 4 | P1 | Button/Floating Control 정렬 | 낮음 | 지도 gesture 충돌 |
| 5 | P1 | 빈 지역 사진 UI 축소 | 중간 | carousel 상태 전환 |
| 6 | P2 | Settings/Content 카드 정돈 | 낮음~중간 | 정보 밀도/번역 |
| 7 | P2 | Typography/spacing 화면 적용 | 중간 | 큰 글꼴/스크롤 변화 |
| 8 | P3 | 예외 평가 및 정리 | 선택적 | 불필요한 재작성 |

## 3. 단계별 계획

### Stage 0 — 회귀 기준 고정

작업:

- 지도 기본/선택/사진 채움/검색 결과/확대 상태 캡처
- 5종 Bottom Sheet와 4종 Dialog 대표 상태 목록화
- 4개 언어, text scale 1.0/1.3/2.0 테스트 행렬 작성
- iOS/Android의 최소/대표 화면 크기 결정
- 현재 semantics label과 focus/back 동작 기록

완료 조건:

- Full-screen Map과 overlay 좌표 관계를 검증하는 위젯/골든 테스트가 있다.
- 사진 clipping과 선택 stroke 결과가 기준 이미지로 고정된다.
- 하단 바 66, overlap 36, zoom offset 136의 레이아웃 계약이 문서/테스트에 반영된다.

### Stage 1 — Token Foundation

작업:

- 기존 `SasangColors`, `SasangRadii`, `SasangSpacing`, `SasangTypography`, `SasangOverlayStyle`을 삭제하지 않고 semantic alias를 추가한다.
- 직접 회색값을 새 semantic color로 매핑한다.
- radius/spacing/elevation을 역할 이름으로 제공한다.
- 기존 값과 새 값의 deprecation 경로를 만든다.

전략:

```text
기존 화면 ── 기존 token ─┐
                         ├─ 같은 Theme source
신규/이전 화면 ─ semantic token ┘
```

완료 조건:

- 토큰 추가만으로 화면 golden이 의도치 않게 바뀌지 않는다.
- 새 코드에서 raw `Color(0x...)`, 임의 radius/spacing을 제한할 기준이 있다.

위험 완화:

- 기존 상수 값을 즉시 바꾸지 않고 alias→컴포넌트별 적용 순서로 진행한다.
- lint 자동화는 오탐 범위를 확인한 뒤 별도 도입한다.

### Stage 2 — Bottom Sheet Shell

작업 순서:

1. 공통 background/scrim/radius/safe area
2. drag handle/header/close hit target
3. 각 body를 변경 없이 shell에 이식
4. 작은 화면/큰 글꼴 scroll 정책 적용

Variant별 주의:

- `library`: 2열 grid와 sticky footer 유지
- `exportChoice`: 사진/영상 두 행과 9:16 preview 유지
- `regionPhotos`: 사진 보유 상태 carousel 310 유지
- `datePicker`: system picker와 photo preview 유지
- `productDetail`: 가격/상태/CTA 정책 변경은 별도 제품 결정

완료 조건:

- 다섯 Variant의 header와 close가 같은 규격이다.
- 각 Variant의 기능/정보 구조는 변경되지 않는다.
- 세로 공간 부족 시 overflow가 아니라 scroll 또는 높이 조정으로 동작한다.

### Stage 3 — Dialog Variants

작업:

- 직접 `showCupertinoDialog` 호출을 semantic wrapper로 모은다.
- Information/Confirmation/Destructive/Progress 호출 계약을 분리한다.
- 내보내기 Progress의 Toss 스타일 중앙 모달은 유지하며 token만 적용한다.
- 긴 번역/큰 글꼴에서 action을 세로 배치한다.

이전 매핑:

| 현재 | 목표 Variant |
|---|---|
| 공유 기록 없음, 백업 실패 | Information |
| 로그아웃, 백업 시작 | Confirmation |
| 데이터 지우기 | Destructive |
| 백업/내보내기 진행 | Progress |

완료 조건:

- 의미가 같은 Dialog는 같은 호출 API를 쓴다.
- destructive 기본 focus, back dismiss, screen reader announcement가 플랫폼별로 검증된다.

### Stage 4 — Button과 Floating Control

작업:

- `SasangPrimaryButton`에 token을 적용하고 secondary/destructive/loading 계약을 추가한다.
- close/share/pill의 시각 크기와 44dp hit target을 분리한다.
- 지도 상단 도구, search, zoom, region control의 shadow/border만 정렬한다.

비범위:

- 지도 버튼 삭제
- 위치를 하단 고정 toolbar로 이동
- map gesture/painter 변경

완료 조건:

- 모든 지도 기능과 위치 관계가 기존과 같다.
- overlay가 통일된 표면 계층을 사용한다.
- iOS/Android에서 tap target과 gesture arena 충돌이 없다.

### Stage 5 — 지역 사진 Empty State

작업:

- 사진 없음 상태에만 `sheetAction` empty variant를 적용한다.
- 310dp 빈 카드 후보를 180~220dp 범위로 비교한다.
- 원형 + 아이콘, 제목, 설명, 카드 테두리의 중복 강조를 최대 두 신호로 줄인다.
- 사진 추가 action과 접근성 label은 유지한다.

완료 조건:

- 사진 보유 상태 carousel은 변경되지 않는다.
- 빈→추가→날짜→사진 보유 상태 전환에서 sheet 크기와 PageView가 안정적이다.
- 작은 기기와 text scale 2.0에서 action이 보인다.

### Stage 6 — Settings와 Content Card

작업:

- 더보기 그룹형 카드 구조는 유지하고 radius 20/border/elevation none을 적용한다.
- navigation/action/destructive/loading row 의미를 구분한다.
- 지도 상점과 앱 정보의 중첩 카드/상태 강조를 줄인다.
- 장소 카드는 radius 8을 유지한 비교안과 12 후보를 캡처하되 변경은 별도 승인한다.

완료 조건:

- 그룹 구분과 터치 영역이 유지된다.
- 정적 카드에서 불필요한 그림자가 제거된다.
- 광고 영역과 마지막 행이 Floating Bottom Navigation에 가리지 않는다.

### Stage 7 — Typography와 Spacing

적용 순서:

1. Bottom Sheet와 Dialog
2. 더보기/상점/앱 정보
3. 장소 목록
4. 약관/개인정보 문서
5. 지도 micro typography

이 순서는 지도의 작은 공간 제한값을 가장 마지막에 다루기 위함이다.

완료 조건:

- 같은 역할에 같은 typography token이 적용된다.
- raw spacing 예외에는 코드 주석 또는 역할 근거가 있다.
- 네 언어에서 잘림이 없고 문서 가독성이 유지된다.

### Stage 8 — 예외 평가

- Flutter `LicensePage`는 유지한다. 브랜드 wrapper가 꼭 필요한지 별도 판단한다.
- 장소 카드 radius 8은 사용자 비교 검토 후 유지/변경한다.
- PR #10 온보딩은 병합된 실제 구현을 다시 감사한 뒤 별도 이슈로 적용한다.
- blur 성능이 낮은 Android 기기에서 fallback을 활성화할지 측정한다.

## 4. PR 분리 제안

| PR | 범위 | 함께 하지 않을 것 |
|---|---|---|
| A | token alias와 테스트 기반 | 화면 값 일괄 변경 |
| B | Bottom Sheet shell | Dialog/지도 painter |
| C | Dialog variants | 데이터 흐름 변경 |
| D | Button/Floating Control 표면 | 위치/기능 변경 |
| E | 지역 사진 empty state | 사진 carousel redesign |
| F | Settings/Content cards | 장소 radius 확정 |
| G | Typography/spacing 화면별 적용 | 모든 화면 일괄 변환 |

각 PR은 이슈, 구현 전 캡처, 구현 후 캡처, iOS/Android 검증 상태를 포함한다.

## 5. 테스트 전략

### 자동 테스트

- token 값 단위 테스트 또는 snapshot
- 컴포넌트 기본/선택/비활성/오류/로딩 golden
- Bottom Sheet 5종 golden과 overflow 테스트
- Dialog 4종 action/focus/back 테스트
- 지도 overlay 위치와 hit test
- region photo empty→photo state 위젯 테스트
- `flutter analyze`, 전체 `flutter test`

### 수동 테스트 행렬

| 축 | 값 |
|---|---|
| 플랫폼 | iOS, Android |
| 언어 | 한국어, 영어, 일본어, 중국어(간체) |
| text scale | 1.0, 1.3, 2.0 |
| 화면 | 작은 폰, 대표 폰, 큰 폰/태블릿 가능 시 |
| 지도 상태 | 빈 지도, 선택, 사진 채움, 확대, 검색 결과 |
| 사진 | 없음, 1장, 여러 장, 세로, 가로 |
| 시스템 | reduce motion, high contrast 가능 시, keyboard/back |

### 시각 검토 질문

- 지도와 사진이 여전히 첫 시선인가.
- 떠 있는 도구가 하나의 계열처럼 보이는가.
- 카드 제거가 아니라 카드 역할이 더 명확해졌는가.
- 선택 상태가 두 신호 이내인가.
- 버튼과 제목이 번역 때문에 잘리지 않는가.
- 화면별 정보 밀도가 지나치게 커지거나 작아지지 않았는가.

## 6. 회귀 위험과 대응

| 위험 | 영향 | 대응 | 중단 기준 |
|---|---|---|---|
| 지도 overlay 위치 변화 | 지도 조작/정보 가림 | 기존 layout constants 고정, golden | control overlap 발생 |
| blur/shadow 변경 성능 | Android jank | profile 측정, opaque fallback | frame budget 악화 |
| sheet shell 통합 | overflow/keyboard 가림 | variant body 독립, scroll test | CTA 접근 불가 |
| dialog custom화 | focus/screen reader 손실 | platform component 우선, semantics test | action 탐색 불가 |
| typography 통합 | 긴 번역 잘림 | 4언어+text scale matrix | 의미 텍스트 ellipsis |
| empty state 높이 축소 | 사진 추가 발견성 저하 | A/B 캡처, action label 유지 | action 인지 실패 |
| direct color 제거 | 대비 저하 | contrast 검토 | WCAG AA 미달 |
| radius 일괄화 | 콘텐츠 역할 소실 | semantic variants 유지 | 사진/선택 구분 약화 |

## 7. iOS/Android 공통 적용 방식

1. Dart의 semantic token을 단일 기준으로 사용한다.
2. 공통 Sasang 위젯은 정보 구조와 상태를 제공한다.
3. 플랫폼 표준 동작이 중요한 picker/dialog/share/license는 내부 구현을 플랫폼에 맡긴다.
4. platform adaptive 분기는 외형 취향이 아니라 접근성·성능·시스템 동작 차이에만 사용한다.
5. 같은 기능의 캡처를 두 플랫폼에서 비교하되 픽셀 동일성이 아니라 계층/브랜드/상태 동일성을 승인 기준으로 삼는다.

## 8. 승인 게이트

각 구현 단계는 다음 조건을 충족해야 다음 단계로 진행한다.

- 사용자에게 적용 전후 캡처와 변경 범위를 제시한다.
- 보존 규칙 위반이 없음을 체크한다.
- 자동/수동 테스트 결과를 PR에 기록한다.
- 새로운 예외 토큰은 이유와 적용 범위를 문서에 추가한다.
- 사용자가 PR을 검토하고 `dev`에 머지한다.

Phase 2-A 완료 시점에는 이 문서들만 존재하며, 실제 디자인 적용은 별도 승인과 이슈 이후 시작한다.

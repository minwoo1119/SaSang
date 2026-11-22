# Phase 5 UI 최종 품질 검증 보고서

- 검증일: 2026-11-22
- 기준 브랜치: `dev`의 `b4c46a0` + Issue #19 수정
- 기준 기기: Android 16 API 36 에뮬레이터, iPhone 17 Pro / iOS 26.4 시뮬레이터
- 중요한 범위 사실: 현재 `dev`에는 Phase 4-A만 병합되어 있다. Phase 4-B~D의 별도 구현 또는
  병합 기록은 없으므로, 이 보고서는 해당 영역을 완료된 것으로 추정하지 않는다.

## 1. 검증 완료 항목

| 항목 | 결과 | 실제 근거 |
|---|---|---|
| 정적 분석 | 통과 | `flutter analyze`: issue 0 |
| 전체 Widget/Unit/Golden | 통과 | `flutter test`: 98 tests, Golden 13장 포함 |
| 신규 접근성 행렬 | 통과 | 한국어/영어/일본어/중국어 × text scale 1.0/1.3/2.0, 온보딩 5페이지 |
| 작은 화면 Bottom Sheet | 통과 | 320×568, scale 2.0에서 지역 사진/날짜/내보내기 시트 overflow 없음 |
| Android 빌드/통합 | 통과 | API 36에서 debug APK 빌드·설치, 지도 이미지/H.264 내보내기 통합 3건 통과 |
| iOS 빌드/통합 | 통과 | iOS 26.4 simulator Xcode build, 지도 이미지/H.264 내보내기 통합 3건 통과 |
| 사진 추가·대표 변경·삭제·날짜 | 통과 | 앨범 상태 단위 테스트, 앨범/날짜 Widget 테스트 |
| 지도 전환·구매 지도 확장 | 통과 | 지도 선택, 구매 지도 수 증가, 상점 이동, 2열 상점 Grid 테스트 |
| 공유/내보내기 | 통과 | iOS/Android 선택 시트, 진행 Dialog, 취소/실패 상태, 양 플랫폼 실제 인코딩 |
| 백업 | 통과 | 원본 사진 포함 portable backup 생성과 progress modal 테스트 |
| 로그아웃/데이터 삭제 UI | 부분 통과 | 확인창 의미와 destructive 상태는 검증. 실제 삭제 후 파일 시스템까지의 E2E는 미검증 |
| 지도 Floating UI | 부분 통과 | 좌표·크기·검색 외부 탭·확대 상태는 Widget/Golden 통과. 실제 손가락 gesture 충돌 E2E는 미검증 |
| 광고 안정성 | 부분 통과 | 로드 전/후 공통 58dp 예약 영역 계약 테스트. 실제 광고 네트워크 전환은 미검증 |

첫 Android 통합 실행은 에뮬레이터 저장 공간 부족으로 설치에 실패했다. 캐시 정리 후 같은 APK를
다시 설치하여 3건 모두 통과했다. 최초 실패를 제품 기능 실패로 숨기거나 성공으로 계산하지 않았다.

## 2. 발견된 디자인 불일치

정적 검색은 `Color(0x...)`, 숫자형 `BorderRadius`, `EdgeInsets`, 고정 `SizedBox`를 휴리스틱으로
집계했다. 렌더링 엔진 좌표, 사진 비율, 지도 stroke와 같은 의도된 수치도 포함되므로 286개라는
숫자 자체를 위반 개수로 해석하면 안 된다. 다만 아래 파일은 Phase 4-B~D가 적용되지 않았다는
명확한 증거다.

| 우선순위 | 영역 | 대표 파일 | 상태 |
|---|---|---|---|
| P1 | 사진 관리/날짜 | `region_photo_album_sheet.dart`, `photo_date_dialog.dart` | 색·radius·spacing·typography가 raw/legacy 중심 |
| P1 | 공유/중앙 Dialog | `export_progress_dialog.dart`, `sasang_center_modal.dart` | Dialog variant와 semantic alias 미적용 |
| P1 | 공용 UI | `sasang_ui.dart` | 버튼·시트·행이 legacy 값 중심, 동일 역할 규격이 분산됨 |
| P2 | 더보기/정보 | `more_screen.dart`, `info_detail_screen.dart` | 그룹 구조는 적절하나 local 색/간격/반경이 남음 |
| P2 | 지도 상점 | `map_store_screen.dart` | 카드·배지·상세 시트가 raw/legacy 중심 |
| P2 | 온보딩 | `onboarding_screen.dart` | 일러스트 고유 색을 제외해도 typography/spacing semantic 전환 전 |
| 예외 | 지도/미리보기/내보내기 렌더러 | painter 및 share service | 제품 이미지 생성 값이므로 일반 UI 토큰과 분리해야 함 |
| 예외 | Flutter LicensePage | SDK 표준 화면 | 기존 승인 원칙에 따라 유지 |

Phase 4-A 영역인 지도 상단 Control, 검색, 확대/축소, 선택 지역 Control, 장소 필터·정렬·카드는
semantic token과 공통 `SasangSurface`를 사용한다. 장소 사진 카드 radius 8과 pill 검색창은 승인된
예외로 유지되어 있으며 위반으로 계산하지 않았다.

## 3. 수정한 문제

| 문제 | 원인 | 최소 수정 |
|---|---|---|
| 온보딩 scale 2.0에서 하단 123px overflow | 고정 비주얼과 큰 제목/설명이 한 `Column`에 결합 | 큰 글꼴에서만 축소 비주얼 + 세로 scroll 사용 |
| 온보딩 `이전` 잘림 | header 좌우 폭 72가 scale 2.0 텍스트보다 작음 | 큰 글꼴에서 92×52 영역 사용 |
| 지역 사진 시트 20px overflow | 310dp carousel과 header/caption 합계가 작은 높이를 초과 | body를 scroll 가능하게 변경, carousel 구조 유지 |
| 날짜 Dialog 가로/세로 overflow | 날짜 요약·가로 버튼·picker가 2배 글꼴을 수용하지 못함 | 접근성 배율에서 세로 action/summary, 전체 scroll, picker만 1.5 상한 |
| 내보내기 선택 시트 317px overflow | 두 84dp 행의 다국어 텍스트와 고정 header 합계 | 콘텐츠 scroll 적용, 사진/영상 구성 유지 |
| 주요 버튼 긴 번역 잘림 | 버튼 label이 비유연 `Row` child | scale 1.5 이상에서만 2줄 flexible label 사용 |
| 광고 로드 전후 8px 이동 | placeholder 58dp, `AdWidget` 50dp | 두 상태 모두 58dp `AdBannerFrame`에 배치 |

일반 글꼴 배율의 기존 Golden은 갱신하지 않고 그대로 통과했다. 즉 접근성 분기 외의 기본 화면은
의도적으로 변경하지 않았다.

## 4. 미해결 및 미검증 문제

- Phase 4-B~D semantic token 전환과 공통 component migration은 현재 `dev`에 없다. Phase 5에서
  전체를 가장해 일괄 수정하지 않았다.
- iOS simulator의 접근성 글꼴 수동 캡처는 ATT 시스템 prompt가 먼저 표시되어 완료하지 못했다.
  iOS build와 통합 내보내기 3건은 실제 simulator에서 통과했지만, 전체 화면의 육안 비교를 대신하지
  않는다.
- 광고 SDK가 네트워크에서 실제 광고를 받아 placeholder에서 전환되는 과정은 자동화하지 못했다.
  공통 예약 높이 계약만 검증했다.
- 지도 overlay와 pinch/pan의 실제 손가락 gesture arena 충돌은 실제 기기 E2E로 확인하지 못했다.
- 데이터 삭제는 destructive 확인창과 상태 메서드 구현을 확인했지만, 실제 앱에서 확인을 끝까지 눌러
  저장 파일 제거까지 검증하지 않았다.
- 모든 화면을 네 언어 × 세 배율로 전수 렌더링한 것은 아니다. 이번 행렬은 온보딩 전체와 대표
  Bottom Sheet를 대상으로 했고, 기존 테스트가 더보기 scale 2.0과 상점 큰 글꼴을 보완한다.

## 5. iOS/Android 결과

| 플랫폼 | 빌드 | 실제 통합 테스트 | 플랫폼별 UI 테스트 | 육안 캡처 |
|---|---|---|---|---|
| Android 16 / API 36 | 통과 | 3/3 통과 | export picker/progress Android variant 통과 | scale 2.0 온보딩 캡처 완료 |
| iOS 26.4 simulator | 통과 | 3/3 통과 | export picker/progress iOS variant 통과 | ATT prompt로 접근성 화면 캡처 미완료 |

Android 검토 이미지는
`docs/pr-screenshots/19/android-onboarding-text-scale-2.png`에 저장했다.

## 6. 최종 디자인 시스템 적용률

적용률은 raw 상수 출현 횟수가 아니라 Phase 1 inventory의 UI 역할을 기준으로 산정했다. 지도 painter와
Flutter LicensePage 두 예외를 제외한 30개 역할을 `완전 적용`, `부분 적용`, `미적용`으로 분류했다.

| 분류 | 역할 수 | 비율 | 대표 영역 |
|---|---:|---:|---|
| 완전 적용 | 8 | 26.7% | token foundation, 지도/장소 Phase 4-A 핵심 Control과 카드 |
| 부분 적용 | 10 | 33.3% | 공용 surface/button/sheet, 내 지도 시트, navigation, 공유 행 |
| 미적용 | 12 | 40.0% | 사진/날짜, Dialog, 더보기/정보, 상점, 온보딩 |

부분 적용을 0.5로 가중한 최종 적용률은 **43.3%** (`(8 + 10×0.5) / 30`)다. 따라서 현재 상태를
“전체 화면 디자인 시스템 적용 완료”라고 판정할 수 없다. 기능 회귀 기준은 안정적이지만, 다음 작업은
Phase 4-B, 4-C, 4-D를 각각 별도 Issue/PR로 완료한 후 이 보고서의 같은 산식으로 재측정해야 한다.

## 변경 파일

- `lib/features/photos/photo_date_dialog.dart`
- `lib/features/photos/region_photo_album_sheet.dart`
- `lib/screens/map_screen.dart`
- `lib/screens/onboarding_screen.dart`
- `lib/widgets/ad_banner.dart`
- `lib/widgets/sasang_ui.dart`
- `test/ui_quality_test.dart`
- `docs/pr-screenshots/19/android-onboarding-text-scale-2.png`
- `docs/design/08-phase-5-ui-quality-report.md`


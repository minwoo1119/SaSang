# 공통 컴포넌트와 재사용 API

## 1. 사용 순서

1. `lib/core/theme/sasang_theme.dart`의 Semantic Token으로 표현한다.
2. 아래 공통 또는 도메인 컴포넌트를 재사용한다.
3. 화면 전용 조립만 화면 파일에 둔다.
4. 새 public component/variant가 필요하면 기존 API로 해결되지 않는 이유와 사용 화면을 PR에 적는다.

## 2. Token API

```dart
import 'package:sasang/core/theme/sasang_theme.dart';
```

| API | 역할 |
|---|---|
| `SasangSemanticColors` | canvas, surface, text, accent, border, destructive, state 색상 |
| `SasangSemanticTypography` | display부터 legalBody, caption, button까지 역할별 TextStyle |
| `SasangSemanticSpacing` | 관계 기반 간격과 page/sheet/map inset |
| `SasangSemanticRadii` | media, control, settings, content, selection, sheet, dialog, pill |
| `SasangBorders` | hairline, subtle, floating, selected, focus |
| `SasangElevation` | none, low, floating, modal, photo |
| `SasangMotion` | instant, standard, modal, sheet, page, reduced motion duration/curve |
| `SasangComponentState(s)` | normal/pressed/selected/disabled/error/loading과 상태 값 |

`SasangColors`, `SasangSpacing`, `SasangRadii`, `SasangTypography`는 기존 화면 호환용이다.
신규 UI가 legacy API부터 선택해서는 안 된다.

## 3. 범용 UI

| API | 파일 | 재사용 범위 | 주의 |
|---|---|---|---|
| `SasangSurface` | `widgets/sasang_ui.dart` | Floating/정적 표면 | 지도 위면 `blur: true`; 정적 카드에 floating shadow 남용 금지 |
| `SasangPrimaryButton` | 같은 파일 | 주요 완료 CTA | 큰 글꼴 2줄 지원, 임의 높이·radius 복제 금지 |
| `SasangTextButton` | 같은 파일 | tertiary/text action | 부모가 최소 44dp hit target을 제공하는지 확인 |
| `SasangChevronRow` | 같은 파일 | 단순 navigation row | 더보기의 특수 상태를 억지로 끼우지 않음 |
| `showSasangSheet` | 같은 파일 | compact sheet shell | variant body 구조는 유지, 작은 화면 scroll 검증 |
| `showSasangConfirmDialog` | 같은 파일 | confirmation/destructive | action 동사를 구체적으로 작성 |
| `SasangCenterModal` | `widgets/sasang_center_modal.dart` | blocking center modal | 단순 정보까지 custom modal로 바꾸지 않음 |
| `showSasangCenterConfirmDialog` | 같은 파일 | 강조 confirmation | 시스템 Dialog보다 강조가 필요한지 먼저 검토 |
| `AdBanner`, `AdBannerFrame` | `widgets/ad_banner.dart` | 광고 영역 | 로드 전후 58dp 예약 높이 유지 |

## 4. 도메인 공통 UI

| API | 파일 | 사용 시점 | 보존 계약 |
|---|---|---|---|
| `MapModeSelector` | `features/map/map_mode_selector.dart` | 현재 지도/보유 지도 선택 | pill, 2열 preview, sticky 상점 footer |
| `MapTopBar` | `screens/map_screen.dart` | 지도 기록 요약/공유/지도 선택 | Full-screen Map 위 Floating 구조 |
| `MapSearchBar`, `MapSearchResults` | 같은 파일 | 지도 검색 | 검색 pill, 지도 위 overlay |
| `showSasangExportFormatPicker` | 같은 파일 | 이미지/영상 선택 | 두 행과 9:16 preview 유지 |
| `showRegionPhotoAlbumSheet` | `features/photos/region_photo_album_sheet.dart` | 지역 앨범 관리 | carousel, 대표 사진, 날짜, 삭제 유지 |
| `showPhotoDateDialog`, `PhotoDatePicker` | `features/photos/photo_date_dialog.dart` | 사진 날짜 확인/수정 | 시스템 picker, scale 2.0 scroll 정책 |
| `ExportProgressDialog` | `features/share/export_progress_dialog.dart` | 내보내기 진행/실패 | blocking 중앙 Progress variant |
| `BackupProgressDialog` | `features/backup/backup_progress_dialog.dart` | 백업 진행 | indeterminate 중앙 Progress variant |

화면 파일의 public widget은 지도 도메인 문맥에 묶여 있다. 범용 컴포넌트로 이동하려면 실제로 두 개
이상의 다른 도메인에서 재사용되는지 확인하고, 불필요한 추상화를 만들지 않는다.

## 5. 상태 규칙 요약

| 상태 | 필수 표현 |
|---|---|
| 기본 | 역할별 surface/content token |
| pressed | `SasangComponentStates` opacity 또는 플랫폼 표준 feedback |
| selected | accent border + accentSoft/label 중 최대 두 신호, semantics selected |
| disabled | action 차단 + content/surface 상태, opacity만으로 의미를 숨기지 않음 |
| loading | 크기 유지, 중복 탭 차단, progress semantics |
| error | inline 설명/재시도 우선, 전체 카드의 과도한 red 처리 금지 |

세부 Variant 계약은 [04-component-variants.md](04-component-variants.md)를 따른다.

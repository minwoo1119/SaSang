# 아키텍처

## 설계 목표

Sasang의 행정 경계는 시각적 컨테이너이고 사용자의 사진이 주 콘텐츠입니다. 지도
렌더링은 백엔드와 독립적으로 동작하며, 원본 사진을 영구 편집하지 않고 배치 정보를
메타데이터로 보존합니다.

```text
행정 경계 원본
    ↓ 빌드 타임 전처리
정규화된 Polygon / MultiPolygon
    ↓
경량 SVG Path JSON
    ↓ Flutter Canvas
사진 클리핑과 인터랙티브 여행 지도
```

## 시스템 구성

```mermaid
flowchart TD
    User[사용자]

    subgraph App[Flutter 앱]
        Screens[화면과 공통 UI]
        State[SasangState]
        Map[벡터 지도 엔진]
        Photos[사진 앨범과 배치]
        Export[PNG·MP4 내보내기]
        Backup[백업 생성]
        Api[API Client]
    end

    subgraph Device[기기 내부]
        Metadata[(JSON 메타데이터)]
        Originals[(원본 사진)]
        MapAssets[(전처리 지도 자산)]
    end

    subgraph Native[네이티브 계층]
        Android[Android MediaCodec]
        IOS[iOS AVAssetWriter]
        Share[사진 보관함·공유 시트]
    end

    subgraph Server[독립 백엔드 기반]
        Routes[Next.js /api/v1]
        Services[서비스]
        Repositories[리포지터리]
        Database[(PostgreSQL·Prisma)]
        Contracts[@sasang/shared]
    end

    User --> Screens
    Screens --> State
    Screens --> Map
    Screens --> Photos
    State --> Metadata
    Photos --> Originals
    MapAssets --> Map
    Metadata --> Map
    Originals --> Map
    Map --> Export
    Metadata --> Backup
    Originals --> Backup
    Export --> Android --> Share
    Export --> IOS --> Share
    Screens -. 선택적 연동 .-> Api
    Api -.-> Routes --> Services --> Repositories --> Database
    Contracts --- Api
    Contracts --- Routes
```

## 모바일 계층

### 진입점과 화면

- `lib/main.dart`: Flutter 진입점
- `lib/app.dart`: 앱 루트, 테마와 초기 구성
- `lib/screens/`: 지도, 장소, 지도 상점, 더보기, 로그인 화면
- `lib/widgets/`: Sasang 공통 UI와 광고 배너

화면은 사용자 흐름을 조립하지만 지도 파싱, 영속화, 내보내기 같은 도메인 로직을 직접
소유하지 않습니다.

### 상태와 영속화

- `lib/features/state/sasang_state.dart`: 현재 지도, 방문, 앨범, 프로필 등 앱 상태
- `lib/core/storage/sasang_storage.dart`: JSON 메타데이터와 로컬 파일 영속화

서버 상태가 핵심 흐름에 개입하지 않으므로 현재 모바일 앱은 로컬 우선입니다. 저장 형식
변경 시 기존 사용자 데이터와 백업 파일의 하위 호환성을 검토해야 합니다.

### 지도 렌더링

- `MapRepository`: 번들 JSON 자산을 도메인 모델로 읽습니다.
- `RegionMapView`: 지역 Path, 선택/방문 상태, 사진 클리핑을 렌더링합니다.
- `MapModeSelector`, `OwnedMap`, `MapPreview`: 지도 모드와 보유 지도 UI를 분리합니다.

런타임에서 원본 SHP나 대용량 GeoJSON을 파싱하지 않습니다. 지역 코드는 이름이 아닌
안정적인 행정 코드 또는 국가 코드를 사용하며, MultiPolygon의 모든 조각은 하나의 지역
상태를 공유합니다.

### 사진, 공유, 백업

- `features/photos/`: 사진 선택, 날짜, 앨범, 대표 사진과 북한 방문 확인 흐름
- `features/share/`: 지도 이미지, 경로 계산, 영상 프레임과 진행 상태
- `features/backup/`: 메타데이터와 원본 사진을 `.sasangbackup`으로 묶는 흐름

원본 사진과 지도 표현은 분리합니다. 지도에서 보이는 결과는 사진 참조와 크롭/배치
메타데이터의 조합이며, 내보내기와 백업은 명시적인 사용자 동작으로만 수행합니다.

## 지도 데이터 파이프라인

`scripts/map-data/`는 다음 단계를 결정론적으로 수행합니다.

```text
SHP / GeoJSON
  → 공식 코드 결합
  → 좌표 정규화
  → 형상 단순화
  → Polygon / MultiPolygon 보존
  → SVG Path 생성
  → assets/maps/* JSON 생성
```

생성 결과를 수동 수정하지 않습니다. 원본, 옵션 또는 생성기를 변경하면 지도 테스트를
실행하고 메타데이터 버전을 함께 갱신합니다.

## 백엔드와 공유 계약

`backend/`는 Next.js App Router의 버전형 API 기반입니다. Route Handler는 입력과 HTTP
응답을 담당하고, 비즈니스 규칙과 데이터 접근은 서비스와 리포지터리로 분리합니다.
`packages/shared/`의 Zod 스키마와 타입은 모바일/백엔드 계약의 기준입니다.

현재 모바일 핵심 기능은 백엔드 없이 실행됩니다. 동기화를 추가하더라도 지도 렌더링과
로컬 사진 편집이 네트워크 가용성에 종속되지 않도록 유지합니다.

## 변경 시 검증 기준

| 변경 영역          | 최소 검증                                       |
| ------------------ | ----------------------------------------------- |
| Dart UI/상태       | `flutter analyze`, 관련 `flutter test`          |
| 지도 데이터/생성기 | `pnpm map:test`, 생성 결과 무결성 검사          |
| 네이티브 영상      | 해당 플랫폼 빌드와 통합 테스트                  |
| 백엔드/공유 계약   | 백엔드 및 공유 패키지 테스트·타입 검사          |
| 문서/템플릿        | 링크, 명령, 브랜치 대상과 템플릿 구조 수동 검토 |

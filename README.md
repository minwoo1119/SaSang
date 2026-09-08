<p align="center">
  <img src="assets/store-img/android/Sasang%20Android%20Graphic%20Design.png" alt="Sasang - 나의 여행을 지도에 남기다" width="100%" style="max-width: 900px; border-radius: 16px;" />
</p>

<h1 align="center">사상 (Sasang)</h1>

<p align="center">
  <strong>나의 여행을 지도에 남기다</strong><br />
  <em>Map your travels through photos</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Expo-SDK%2054-000020?style=flat-square&logo=expo&logoColor=white" alt="Expo SDK 54" />
  <img src="https://img.shields.io/badge/React%20Native-0.81-61DAFB?style=flat-square&logo=react&logoColor=black" alt="React Native 0.81" />
  <img src="https://img.shields.io/badge/TypeScript-5.9%20%2F%206.0-3178C6?style=flat-square&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Next.js-16%20(App%20Router)-black?style=flat-square&logo=next.js&logoColor=white" alt="Next.js 16" />
  <img src="https://img.shields.io/badge/Prisma-6.15-2D3748?style=flat-square&logo=prisma&logoColor=white" alt="Prisma" />
  <img src="https://img.shields.io/badge/Turborepo-Monorepo-EF4444?style=flat-square&logo=turborepo&logoColor=white" alt="Turborepo" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" alt="License" />
</p>

---

## 프로젝트 개요

사상(Sasang)은 방문한 행정 구역의 벡터 폴리곤 경계 안에 여행 사진을 정밀하게 클리핑하여 채워 넣는 개인 맞춤형 비주얼 여행 지도 애플리케이션입니다.

기존의 내비게이션이나 핀 기반 지도와 달리, 사상은 행정 구역 경계선을 시각적 프레임(Container)으로 삼고 사용자의 사진을 핵심 콘텐츠로 배치합니다. 대한민국 250개 시·군·구부터 전 세계 국가까지, 여행의 발자취를 벡터 지도 위에 시각화합니다.

---

## 앱 미리보기

<div align="center">

|                                                     1. 온보딩 / 인트로                                                      |                                                 2. 국내 여행 지도 (시·군·구)                                                  |                                                    3. 해외 여행 지도 (국가별)                                                    |                                                      4. 방문 기록 피드                                                      |                                                       5. 프로필 및 설정                                                       |
| :-------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------: |
| <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%201.png" width="180" alt="사진으로 채우는 여행 지도" /> | <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%202.png" width="180" alt="대한민국 여행을 지도에 기록" /> | <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%203.png" width="180" alt="전 세계 국가를 사진으로 채우다" /> | <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%204.png" width="180" alt="방문 기록을 피드로 한눈에" /> | <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%205.png" width="180" alt="프로필과 앱 정보를 간편하게" /> |
|                             **사진으로 채우는 여행 지도**<br>방문 지역 선택 & 나만의 지도 시작                              |                                   **대한민국 지도 기록**<br>250개 시·군·구 정밀 벡터 클리핑                                   |                                    **전 세계 국가 지도**<br>글로벌 여행 기록 및 국가별 채우기                                    |                                    **방문 기록 피드**<br>장소·날짜별 감성 카드 아카이빙                                     |                                     **프로필 & 정보 관리**<br>사용자 설정 및 데이터 관리                                      |

</div>

---

## 주요 기능

- **국내·해외 듀얼 지도 지원 (Dual Map System)**
  - 국내 지도: 전국 250개 시·군·구 단위 행정 구역 벡터 폴리곤 지원
  - 해외 지도: 전 세계 190여 개 국가 단위 글로벌 벡터 지도 지원
  - 지역명 및 국가명 실시간 검색 및 다이렉트 뷰 포커싱

- **정밀한 벡터 사진 클리핑 (Vector Polygon Clipping)**
  - `react-native-svg`의 `<ClipPath>`를 활용하여 불규칙한 행정 구역 경계선(MultiPolygon) 내부로 사진 마스킹
  - 레스터 타일 대신 경량 SVG Path를 사용하여 고배율 줌 환경에서도 선명한 경계선 유지

- **비파괴 사진 편집 및 제스처 조절 (Non-destructive Photo Transform)**
  - 핀치 줌(Pinch to Zoom)과 드래그(Pan) 제스처를 통한 직관적인 구도 조정
  - 원본 사진을 영구 크롭하지 않고 `scale`, `offsetX`, `offsetY` 메타데이터만 저장하여 언제든 재조정 가능

- **방문 기록 및 피드 아카이빙 (Travel Archive Feed)**
  - 방문 지역, 방문 일자, 사진을 깔끔한 카드 피드 형태로 정렬
  - 국내 / 해외 탭 필터링 및 방문 기록 관리

- **Liquid Glass 기반의 포토 중심 인터페이스**
  - 여행 사진과 지도가 돋보이도록 장식을 최소화한 레이아웃
  - 플로팅 글래스 컨트롤 및 바텀 시트 네비게이션 구조

---

## 아키텍처 및 데이터 파이프라인

사상은 대용량 GIS 데이터를 런타임에 직접 파싱하지 않고, 사전 빌드 파이프라인을 통해 정규화된 경량 벡터 에셋으로 변환하여 렌더링합니다.

```
┌─────────────────────────┐
│   행정구역 데이터 원본   │ (SHP / GeoJSON)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│   전처리 스크립트 실행   │ (좌표 정규화, 지오메트리 단순화, MultiPolygon 보존)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│   경량 SVG Path 생성    │ (@sasang/app/assets/maps/...)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│   실시간 벡터 클리핑    │ (<ClipPath> + Non-destructive Transform Metadata)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│    인터랙티브 여행 지도   │ (React Native + react-native-svg)
└─────────────────────────┘
```

---

## 기술 스택

### Mobile (`app/`)

- **Framework**: React Native 0.81, Expo SDK 54, React 19
- **Routing**: Expo Router v6
- **Vector & Graphics**: `react-native-svg`
- **Gestures & Animation**: `react-native-gesture-handler`, `react-native-reanimated`
- **Media**: `expo-image`, `expo-image-picker`
- **State Management**: Zustand (UI 및 뷰 제어), TanStack Query v5 (서버 상태)
- **Monetization**: `react-native-google-mobile-ads`

### Backend (`backend/`)

- **Framework**: Next.js 16 (App Router, Route Handlers for `/api/v1/`)
- **Database & ORM**: PostgreSQL, Prisma ORM
- **Validation**: Zod
- **Architecture**: Route Handler ➔ Service ➔ Repository 계층 분리

### Monorepo & Tooling

- **Workspaces**: Turborepo, pnpm workspaces (Node >= 22)
- **Shared Package (`packages/shared`)**: DTO, Zod 스키마, 공통 타입 정의

---

## 프로젝트 구조

```text
sasang/
├── app/                        # Expo / React Native 모바일 애플리케이션
│   ├── src/
│   │   ├── app/                # Expo Router 라우트 ((tabs), index 등)
│   │   ├── components/         # 공용 UI 컴포넌트
│   │   ├── features/           # 기능별 모듈 (map, visits, auth, profile, ads)
│   │   ├── hooks/              # 커스텀 훅
│   │   ├── services/           # API 클라이언트 및 통신 모듈
│   │   └── assets/             # 폰트, 아이콘, 전처리된 맵 데이터
│   ├── app.json
│   └── package.json
│
├── backend/                    # Next.js API 백엔드 서버
│   ├── src/
│   │   ├── app/api/v1/         # REST API 엔드포인트
│   │   └── modules/            # 도메인 모듈 (Service, Repository)
│   ├── prisma/
│   │   └── schema.prisma       # Prisma 데이터베이스 스키마
│   └── package.json
│
├── packages/
│   └── shared/                 # 공통 DTO, 스키마, 타입 정의 (@sasang/shared)
│
├── scripts/
│   └── map-data/               # 지도 전처리 및 SVG Path 변환 스크립트
│
├── assets/
│   └── store-img/              # 앱 스토어 및 마케팅 이미지
│       ├── android/
│       └── ios/
│
├── AGENTS.md                   # 프로젝트 코딩 표준 및 규칙
├── DESIGN.md                   # 비주얼 디자인 가이드
├── pnpm-workspace.yaml
└── turbo.json
```

---

## 시작하기

### 사전 요구사항

- Node.js v22.0.0 이상
- pnpm v10.34.5 이상 (`corepack enable` 권장)

### 1. 의존성 설치

```bash
corepack enable
pnpm install
```

### 2. 모바일 앱 실행

루트 디렉터리에서 실행:

```bash
pnpm start
# 또는 특정 경로 지정
npx expo start app
```

앱 디렉터리(`app/`)에서 직접 실행:

```bash
cd app
npx expo start
```

플랫폼별 실행:

```bash
pnpm --filter @sasang/app android  # Android
pnpm --filter @sasang/app ios      # iOS
pnpm --filter @sasang/app web      # Web
```

### 3. 백엔드 API 실행

```bash
pnpm --filter @sasang/backend dev
```

### 4. 지도 데이터 전처리

행정 구역 및 국가별 SVG Path 데이터를 재생성할 때 실행합니다:

```bash
pnpm map:generate
pnpm map:test
```

### 5. 코드 품질 검사

```bash
pnpm typecheck   # 전체 TypeScript 타입 검사
pnpm lint        # ESLint 정적 분석
pnpm format:check # Prettier 포맷 검사
```

---

## 환경 변수

각 패키지의 `.env.example`을 참고하여 `.env` 파일을 생성합니다.

- **Mobile (`app/.env`)**:
  ```env
  EXPO_PUBLIC_API_URL=https://api.sasang.app
  ```
- **Backend (`backend/.env`)**:
  ```env
  DATABASE_URL=postgresql://user:password@localhost:5432/sasang
  ```

---

## 브랜드 및 라이선스

- **프로젝트 명칭**: 사상 (Sasang)
- **저작권**: Copyright © 2026 Sasang Team. All rights reserved.
- **라이선스**: [MIT License](LICENSE)

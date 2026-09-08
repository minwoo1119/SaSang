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

## 📌 소개 (About Sasang)

**사상(Sasang)**은 방문한 행정 구역의 벡터 폴리곤 경계 안에 여행 사진을 정밀하게 클리핑하여 채워 넣는 **개인 맞춤형 비주얼 여행 지도 앱**입니다.

기존의 내비게이션이나 핀 기반 지도와 달리, 사상은 **행정 구역 경계선을 시각적 프레임(Container)**으로 삼고 **사용자의 사진을 핵심 콘텐츠**로 배치합니다. 대한민국 250개 시·군·구부터 전 세계 국가까지, 여행의 발자취가 지도 위에 한 폭의 작품처럼 시각화됩니다.

---

## 📱 앱 프리뷰 (Store Screenshots)

<div align="center">

|                                                     1. 온보딩 / 인트로                                                      |                                                 2. 국내 여행 지도 (시·군·구)                                                  |                                                    3. 해외 여행 지도 (국가별)                                                    |                                                      4. 방문 기록 피드                                                      |                                                       5. 프로필 및 설정                                                       |
| :-------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------: |
| <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%201.png" width="180" alt="사진으로 채우는 여행 지도" /> | <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%202.png" width="180" alt="대한민국 여행을 지도에 기록" /> | <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%203.png" width="180" alt="전 세계 국가를 사진으로 채우다" /> | <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%204.png" width="180" alt="방문 기록을 피드로 한눈에" /> | <img src="assets/store-img/android/Sasang%20Android%20Screen%20Shot%205.png" width="180" alt="프로필과 앱 정보를 간편하게" /> |
|                             **사진으로 채우는 여행 지도**<br>방문 지역 선택 & 나만의 지도 시작                              |                                   **대한민국 지도 기록**<br>250개 시·군·구 정밀 벡터 클리핑                                   |                                    **전 세계 국가 지도**<br>글로벌 여행 기록 및 국가별 채우기                                    |                                    **방문 기록 피드**<br>장소·날짜별 감성 카드 아카이빙                                     |                                     **프로필 & 정보 관리**<br>사용자 설정 및 데이터 관리                                      |

</div>

---

## ✨ 핵심 기능 (Key Features)

- 🌐 **국내·해외 듀얼 지도 지원 (Dual Map System)**
  - **국내 지도**: 전국 250개 시·군·구 단위 행정 구역 벡터 폴리곤 완벽 지원
  - **해외 지도**: 전 세계 190여 개 국가 단위의 글로벌 벡터 지도 지원
  - 검색 창을 통한 빠른 지역명 / 국가명 검색 및 다이렉트 포커싱

- 🔲 **정밀한 벡터 사진 클리핑 (Vector Polygon Clipping)**
  - `react-native-svg`의 `<ClipPath>`를 활용하여 불규칙한 행정 경계선(MultiPolygon) 내부로 사진 마스킹
  - 레스터 이미지(PNG/JPG) 타일 대신 경량화된 SVG Path 기반으로 고해상도 확대에도 깨짐 없는 렌더링

- 👆 **비파괴 사진 편집 및 제스처 조절 (Non-destructive Photo Transform)**
  - 핀치 줌(Pinch to Zoom)과 드래그(Pan) 제스처를 통한 직관적인 구도 조정
  - 원본 사진을 영구 크롭하지 않고 `scale`, `offsetX`, `offsetY` 메타데이터만 저장하여 언제든 재편집 가능

- 📖 **방문 기록 & 피드 아카이빙 (Travel Archive Feed)**
  - 방문한 지역, 방문 일자, 사진을 깔끔한 카드 피드 형태로 정렬
  - 국내 / 해외 탭 필터링 및 방문 기록 삭제·수정 관리

- 💧 **Liquid Glass 기반의 미니멀 인터페이스 (Photo-Centric UI)**
  - 여행 사진과 지도가 돋보이도록 과도한 장식을 배제한 클린 UI
  - Apple Human Interface Guidelines의 감성을 담은 플로팅 글래스 컨트롤 및 하단 시트 네비게이션

---

## 🏗 아키텍처 및 파이프라인 (Core Architecture)

사상은 대용량 GIS 데이터를 런타임에 직접 파싱하지 않고, 사전 빌드 파이프라인을 통해 초경량 벡터 에셋으로 정규화하여 렌더링합니다.

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

## 🛠 기술 스택 (Tech Stack)

### Mobile (`app/`)

- **Core**: React Native 0.81, Expo SDK 54, React 19
- **Routing**: Expo Router v6 (File-based Routing)
- **Vector & Graphics**: `react-native-svg` (15.x)
- **Gestures & Animation**: `react-native-gesture-handler`, `react-native-reanimated` (4.x)
- **Media**: `expo-image`, `expo-image-picker`
- **State Management**: Zustand (UI 및 로컬 제어), TanStack Query v5 (서버 상태)
- **Monetization**: `react-native-google-mobile-ads`

### Backend (`backend/`)

- **Framework**: Next.js 16 (App Router, Route Handlers for `/api/v1/`)
- **Database ORM**: PostgreSQL, Prisma ORM (6.x)
- **Validation**: Zod
- **Architecture**: Controller ➔ Service ➔ Repository 계층 분리 구조

### Monorepo & Shared

- **Tooling**: Turborepo, pnpm workspaces (Node >= 22)
- **Shared Package (`packages/shared`)**: DTO, Zod 검증 스키마, 공통 타입 정의

---

## 📁 프로젝트 구조 (Repository Structure)

```text
sasang/
├── app/                        # Expo / React Native 모바일 애플리케이션
│   ├── src/
│   │   ├── app/                # Expo Router 파일 기반 라우팅 ((tabs), index 등)
│   │   ├── components/         # 범용 UI 컴포넌트
│   │   ├── features/           # 도메인별 기능 (map, visits, auth, profile, ads)
│   │   ├── hooks/              # 커스텀 훅
│   │   ├── services/           # API 클라이언트 및 외부 서비스
│   │   └── assets/             # 폰트, 아이콘, 전처리된 맵 데이터 (SVG)
│   ├── app.json
│   └── package.json
│
├── backend/                    # Next.js API 백엔드 서버
│   ├── src/
│   │   ├── app/api/v1/         # RESTful API 엔드포인트
│   │   └── modules/            # 도메인 모듈 (Controller, Service, Repository)
│   ├── prisma/
│   │   └── schema.prisma       # 데이터베이스 스키마 정의
│   └── package.json
│
├── packages/
│   └── shared/                 # 클라이언트/서버 공유 DTO, 스키마, 상수 (@sasang/shared)
│
├── scripts/
│   └── map-data/               # GeoJSON / SHP 지도 전처리 및 SVG Path 변환 스크립트
│
├── assets/
│   └── store-img/              # 앱 스토어 및 마케팅 이미지 리소스
│       ├── android/
│       └── ios/
│
├── AGENTS.md                   # 프로젝트 코딩 표준 및 에이전트 지침
├── DESIGN.md                   # 비주얼 디자인 및 Liquid Glass 가이드라인
├── pnpm-workspace.yaml
└── turbo.json
```

---

## 🚀 시작하기 (Getting Started)

### 사전 요구사항 (Prerequisites)

- [Node.js](https://nodejs.org/) v22.0.0 이상
- [pnpm](https://pnpm.io/) v10.34.5 이상 (`corepack enable` 권장)

### 1. 의존성 설치

```bash
corepack enable
pnpm install
```

### 2. 모바일 앱 실행

루트 디렉터리에서 바로 실행:

```bash
pnpm start
# 또는 Expo CLI에 직접 앱 경로 지정
npx expo start app
```

앱 디렉터리(`app/`)에서 직접 실행:

```bash
cd app
npx expo start
```

플랫폼별 실행:

```bash
pnpm --filter @sasang/app android  # 안드로이드
pnpm --filter @sasang/app ios      # iOS
pnpm --filter @sasang/app web      # 웹 미리보기
```

### 3. 백엔드 API 실행

```bash
pnpm --filter @sasang/backend dev
```

### 4. 지도 데이터 생성 (Map Preprocessing)

행정 구역 및 국가별 SVG Path 데이터를 다시 생성할 경우:

```bash
pnpm map:generate
pnpm map:test
```

### 5. 코드 품질 검사

```bash
pnpm typecheck   # 전체 패키지 TypeScript 타입 검사
pnpm lint        # ESLint 정적 분석
pnpm format:check # Prettier 포맷 검사
```

---

## 🔐 환경 변수 (Environment Variables)

각 패키지 디렉터리의 `.env.example`을 복사하여 `.env`를 구성합니다.

- **Mobile (`app/.env`)**:
  ```env
  EXPO_PUBLIC_API_URL=https://api.sasang.app
  ```
- **Backend (`backend/.env`)**:
  ```env
  DATABASE_URL=postgresql://user:password@localhost:5432/sasang
  ```

---

## 🏷 브랜드 및 라이선스 (Brand & License)

- **공식 명칭**: 사상 (Sasang)
- **저작권**: Copyright © 2026 Sasang Team. All rights reserved.
- **라이선스**: [MIT License](LICENSE)

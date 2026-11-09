# 프로젝트 개요

## 제품 정체성

- 한국어 이름: **사상**
- 영문 이름: **Sasang**
- 저장소 및 코드 이름: `sasang`
- Android application ID: `com.sasang.app`

Sasang은 방문한 행정 지역을 사용자의 사진으로 채워 여행 기록을 시각화하는 개인 여행
지도 앱입니다. 길찾기나 일반 지도 탐색보다 **내 사진으로 여행 이력을 지도에서 본다**는
경험을 우선합니다.

## 핵심 경험

1. 대한민국 시·군·구 또는 세계 국가를 벡터 지도에서 선택합니다.
2. 선택한 지역에 한 장 이상의 여행 사진과 날짜를 저장합니다.
3. 사진을 행정 경계 내부에 클리핑하고 대표 사진을 지도에 표시합니다.
4. 완성된 지도를 이미지나 여행 경로 영상으로 내보냅니다.
5. 여행 기록과 원본 사진을 `.sasangbackup` 파일로 백업합니다.

## 현재 구현 범위

- 대한민국 161개 행정 지역과 세계 175개 국가 지도
- Polygon 및 MultiPolygon 경계 렌더링
- 지역 선택, 방문 상태, 지역별 사진 앨범과 대표 사진
- 촬영일 기반 여행 기록
- PNG 지도 및 H.264 여행 타임라인 영상 내보내기
- 로컬 JSON 메타데이터와 앱 전용 사진 저장소
- 로컬 백업 및 시스템 공유
- Google Mobile Ads와 iOS ATT 처리
- 향후 동기화를 위한 Next.js API 및 공유 Zod 계약 기반

현재 배포 앱의 핵심 여행 기록은 로컬 우선으로 동작합니다. `backend/`는 앱의 지도
렌더링과 분리되어 있으며, 핵심 기능을 실행하기 위한 필수 의존성이 아닙니다.

## 기술 스택

| 영역        | 기술                                                |
| ----------- | --------------------------------------------------- |
| 모바일      | Flutter 3.35.3, Dart 3.9.2                          |
| 지도        | Flutter Canvas, SVG Path, `path_drawing`            |
| 상태        | `ChangeNotifier` 기반 `SasangState`, 화면 로컬 상태 |
| 사진        | `image_picker`, EXIF, Flutter image codec           |
| 저장        | 앱 문서 디렉터리, JSON 메타데이터, 원본 이미지 파일 |
| 공유/백업   | `share_plus`, `gal`, `archive`                      |
| 영상        | Android MediaCodec/MediaMuxer, iOS AVAssetWriter    |
| 지도 전처리 | Node.js, GeoJSON, `polygon-clipping`                |
| 백엔드 기반 | Next.js 16, TypeScript, Prisma, PostgreSQL, Zod     |
| 테스트      | Flutter Test, Integration Test, Vitest, Node Test   |

## 저장소 구조

```text
sasang/
├─ lib/                    Flutter 애플리케이션
│  ├─ core/               테마, 레이아웃, 저장소, 광고
│  ├─ features/           지도, 사진, 공유, 백업, 상태
│  ├─ models/             지도와 여행 도메인 모델
│  ├─ screens/            앱 화면
│  ├─ services/           API 등 외부 연동
│  └─ widgets/            공통 UI
├─ android/               Android 호스트와 네이티브 영상 인코더
├─ ios/                   iOS 호스트와 네이티브 영상 인코더
├─ assets/                지도, 이미지, 폰트, 스토어 자료
├─ test/                  단위, 위젯, 골든 테스트
├─ integration_test/      플랫폼 통합 테스트
├─ scripts/map-data/      지도 데이터 생성 및 검증
├─ backend/               독립 실행 가능한 Next.js API 기반
├─ packages/shared/       공유 Zod 스키마와 타입
├─ docs/                  프로젝트와 운영 문서
└─ .github/               이슈 및 PR 템플릿
```

## 로컬 실행

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android 빌드는 JDK 17을 기준으로 합니다. Flutter가 다른 Android Studio 번들 JDK를
선택하면 `flutter config --jdk-dir=<JDK_17_PATH>`로 로컬 환경의 JDK 17을 지정합니다.

백엔드 또는 지도 도구를 사용할 때는 Node.js 22.13 이상과 pnpm 10.34.5를 사용합니다.

```bash
pnpm install
pnpm dev
pnpm map:test
```

## 버전 기준

앱 버전의 단일 기준은 `pubspec.yaml`의 `version: <semver>+<build-number>`입니다.
Android의 `versionName`/`versionCode`와 iOS의 마케팅 버전/빌드 번호는 이 값을 사용합니다.
릴리스 절차는 [개발 및 릴리스 워크플로](development-workflow.md)를 따릅니다.

# Architecture

Sasang의 지도 렌더링은 백엔드 저장 방식과 독립적입니다.

```text
Administrative boundary → normalized vector geometry → SVG path → photo clipping
```

- `app/`: Expo 기반 모바일 UI와 지도 상호작용
- `backend/`: Next.js Route Handler 기반 `/api/v1` API
- `packages/shared/`: 양쪽에서 사용하는 Zod 스키마와 DTO
- `scripts/map-data/`: 런타임 밖에서 수행하는 지도 전처리

초기 구현은 서울 25개 구의 폴리곤 선택과 사진 클리핑 검증을 우선합니다.

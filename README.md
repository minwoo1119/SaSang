# Sasang

Sasang(사상)은 방문한 행정구역을 여행 사진으로 채우는 개인 여행 지도입니다.

## 시작하기

```bash
corepack enable
pnpm install
pnpm start
```

- 모바일 앱: `pnpm start`
- 모바일 앱 직접 실행: `cd app && npx expo start`
- 루트에서 Expo 직접 실행: `npx expo start app`
- 백엔드 API: `pnpm --filter @sasang/backend dev`
- 전체 타입 검사: `pnpm typecheck`

환경 변수는 각 패키지의 `.env.example`을 참고하세요.

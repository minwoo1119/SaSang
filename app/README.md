# Sasang App

Sasang(사상) 모바일 앱입니다.

## 시작하기

루트에서 의존성을 설치합니다.

```bash
corepack enable
pnpm install
```

앱 디렉터리에서는 Expo CLI를 바로 실행할 수 있습니다.

```bash
cd app
npx expo start
```

루트 디렉터리에서는 아래 명령을 사용합니다.

```bash
pnpm start
```

또는:

```bash
npx expo start app
```

루트에서 인자 없이 `npx expo start`를 실행하면 루트 모노레포를 Expo 앱으로 해석하므로
실패합니다.

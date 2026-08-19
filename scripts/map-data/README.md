# Map data preprocessing

원본 SHP/GeoJSON을 정규화·단순화하고 SVG path 기반 모바일 자산으로 생성하는 결정적 파이프라인을 이 디렉터리에 둡니다.

생성 결과에는 데이터 버전, 생성 시각, 원본 출처와 `THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.` 헤더를 포함해야 합니다.

## 서울 25개 구

```bash
pnpm map:generate
pnpm map:test
```

원본 GeoJSON을 정규화된 360×300 SVG 좌표로 투영하여
`app/src/assets/maps/korea/seoul.json`을 생성합니다. 원본과 라이선스 정보는
[`NOTICE.md`](./NOTICE.md)에 기록되어 있습니다.

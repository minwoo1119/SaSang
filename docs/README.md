# Sasang 문서

이 디렉터리는 Sasang의 현재 구현과 개발 운영 방식에 대한 기준 문서입니다. 코드나
운영 절차가 변경되면 관련 문서도 같은 이슈와 PR에서 함께 갱신합니다.

## 필수 문서

| 문서                                               | 내용                                              |
| -------------------------------------------------- | ------------------------------------------------- |
| [프로젝트 개요](project-overview.md)               | 제품 목표, 현재 기능, 기술 스택, 저장소 구조      |
| [아키텍처](architecture.md)                        | 런타임 구성, 데이터 흐름, 계층별 책임과 설계 원칙 |
| [개발 및 릴리스 워크플로](development-workflow.md) | 이슈, 브랜치, 커밋, PR, `dev -> main` 릴리스 절차 |

## 주제별 문서

- [사진 앨범](photo-albums.md)
- [지도 공유](map-sharing.md)
- [내보내기 개선 검토](export-improvements-review.md)
- [Firebase Analytics](firebase-analytics.md)
- [Flutter 마이그레이션 분석](flutter-migration-analysis.md)
- [Flutter 마이그레이션 계획](flutter-migration-plan.md)
- [Flutter 마이그레이션 검증](flutter-migration-validation.md)

## 문서 우선순위

현재 모바일 구현은 Flutter입니다. 과거 React Native 또는 Expo 계획과 현재 코드가
충돌할 경우 이 디렉터리의 현재 구현 문서와 실제 코드가 우선합니다. 모든 에이전트는
작업 전에 루트의 `AGENTS.md`와 위 필수 문서를 읽어야 합니다.

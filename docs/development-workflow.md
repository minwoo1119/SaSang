# 개발 및 릴리스 워크플로

이 문서는 사람과 모든 에이전트에게 동일하게 적용되는 필수 절차입니다. 사용자는 각 작업
PR의 최종 검토자이며, 에이전트는 이슈 생성부터 PR 생성까지 수행하되 PR을 직접 머지하지
않습니다.

## 브랜치 역할

| 브랜치      | 역할                  | 직접 작업                               |
| ----------- | --------------------- | --------------------------------------- |
| `main`      | 배포 가능한 릴리스    | 금지. 릴리스 절차의 fast-forward만 허용 |
| `dev`       | 검토 완료 작업의 통합 | 금지. PR 머지와 릴리스 준비만 허용      |
| 이슈 브랜치 | 하나의 이슈 구현      | 허용                                    |

이슈 브랜치는 최신 `dev`에서 생성합니다.

```text
feat/<issue-number>-<slug>
fix/<issue-number>-<slug>
docs/<issue-number>-<slug>
chore/<issue-number>-<slug>
```

한 브랜치에는 한 이슈만 포함합니다. 관련 없는 리팩터링이나 포맷 변경을 함께 넣지
않습니다.

## 일반 작업 절차

### 1. 기준 문서와 상태 확인

```bash
git status --short
git branch --show-current
gh auth status
```

`AGENTS.md`와 `docs/`의 필수 문서를 읽습니다. 작업 트리에 사용자 변경이 있다면 덮어쓰지
않고 안전하게 분리할 수 있는지 먼저 판단합니다.

### 2. GitHub 이슈 생성

사용자가 기존 이슈 번호를 지정하지 않았다면 구현 전에 이슈를 만듭니다.

```bash
gh issue create --template task.yml
```

버그와 기능 요청은 각각 `bug_report.yml`, `feature_request.yml`을 사용할 수 있습니다.
이슈에는 배경, 범위, 완료 조건, 검증 방법을 기록합니다.

### 3. `dev` 동기화와 이슈 브랜치 생성

```bash
git fetch origin
git switch dev
git pull --ff-only origin dev
git switch -c <type>/<issue-number>-<short-slug>
```

원격 `dev`가 기준입니다. `main`이나 오래된 로컬 브랜치에서 이슈 브랜치를 만들지
않습니다.

### 4. 구현, 문서화, 검증

- 기존 구현을 먼저 확인하고 가장 작은 일관된 변경을 수행합니다.
- 동작이나 구조가 바뀌면 테스트와 `docs/`를 같은 이슈에서 갱신합니다.
- 변경 영역에 맞는 검증을 수행하고 결과를 PR에 기록합니다.
- 비밀값, 서명 키, 실제 `.env` 파일을 커밋하지 않습니다.

### 5. 커밋과 푸시

저장소 규칙에 따라 완료 커밋은 `feat:` 접두사를 사용합니다.

```bash
git add <변경 파일>
git commit -m "feat: 작업 내용을 간결하게 설명"
git push -u origin <issue-branch>
```

### 6. `dev` 대상 PR 생성

```bash
gh pr create \
  --base dev \
  --head <issue-branch> \
  --title "feat: 작업 제목" \
  --template .github/PULL_REQUEST_TEMPLATE.md
```

PR 본문에는 반드시 `Closes #<issue-number>`를 넣고, 변경 사항과 검증 결과, 리뷰 포인트를
작성합니다. PR을 생성한 뒤 URL과 상태를 사용자에게 전달합니다.

에이전트는 PR을 직접 머지하거나 자동 머지를 활성화하지 않습니다. 사용자가 검토하고
이슈 브랜치 PR을 `dev`에 머지합니다.

## 리뷰 수정 절차

리뷰 수정은 같은 이슈 브랜치에 추가 커밋으로 반영하고 기존 PR에 푸시합니다. 새 이슈나
새 PR을 중복 생성하지 않습니다. 범위가 별개의 작업으로 커지면 새 이슈로 분리합니다.

## 릴리스: `dev -> main`

### 실행 조건

다음 두 조건이 모두 충족될 때만 릴리스를 수행합니다.

1. 사용자가 이슈 브랜치 PR을 `dev`에 직접 머지했습니다.
2. 사용자가 "PR 머지했어. 이제 버전 올리자."처럼 머지 완료와 버전 릴리스를 명시적으로
   요청했습니다.

이 단계에서는 **`dev -> main` PR을 만들지 않습니다.**

### 버전 규칙

- 사용자가 major/minor/patch를 지정하면 그 요청을 따릅니다.
- 별도 지정이 없으면 patch 버전을 올립니다.
- `pubspec.yaml`의 semantic version과 build number를 모두 증가시킵니다.
- 태그 형식은 `v<major>.<minor>.<patch>`입니다.

예: `1.1.2+30` → `1.1.3+31`, 태그 `v1.1.3`

### 직접 릴리스 절차

```bash
git status --short
git fetch origin --tags
git switch dev
git pull --ff-only origin dev
```

1. `pubspec.yaml`과 버전을 표시하는 문서를 갱신합니다.
2. 전체 변경에 적합한 분석, 테스트, 릴리스 빌드를 실행합니다.
3. 버전 커밋을 만들고 `dev`에 푸시합니다.

```bash
git commit -m "feat: 버전 <version>으로 업데이트"
git push origin dev
```

4. `main`을 원격 최신 상태로 만들고 `dev`로 fast-forward 합니다.

```bash
git switch main
git pull --ff-only origin main
git merge --ff-only dev
```

5. 버전 커밋에 annotated tag를 만들고 `main`과 태그를 푸시합니다.

```bash
git tag -a v<version> -m "Sasang v<version>"
git push origin main
git push origin v<version>
```

6. `main`, `dev`, 태그가 같은 릴리스 커밋을 가리키는지 확인하고 결과를 사용자에게
   보고합니다.

fast-forward가 불가능하거나 버전 태그가 이미 존재하면 강제 푸시하거나 태그를 덮어쓰지
않고 중단한 뒤 사용자에게 상태를 알립니다.

## 금지 사항

- 이슈 없는 구현
- `main` 또는 `dev`에서 일반 기능을 직접 수정
- `main` 대상 기능 PR
- 에이전트가 PR을 직접 머지
- `dev -> main` PR 생성
- `--force` 또는 `--force-with-lease` 푸시
- 기존 릴리스 태그 이동 또는 덮어쓰기

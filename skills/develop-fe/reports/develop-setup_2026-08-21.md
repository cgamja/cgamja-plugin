# develop-setup — 빈 폴더 첫 세팅 (2026-08-21)
- 대상: `/cgamja:develop-setup` · headless `claude -p --dangerously-skip-permissions`(질문 답은 프롬프트에 선입력) · 기본 모델 · Claude Code 2.1.238
- 프로젝트: 스크래치 빈 git 폴더 · Vite + React + TS, pnpm, Tailwind v4, TanStack Query, Figma 없음, API 스펙 없음(DRAFT), 도메인 `todos`
- 소요: 1차 10분 타임아웃(설치 포함, 비용 미집계) + 2차 이어서 24턴 · 4.4분 · **$3.02**. 합계 ~15분
- 적용 ADR: 0004, 0005, 0006, 0008

## 결과
| # | 항목 | 확인 방법 | 결과 |
|---|---|---|---|
| 1 | 산출물 일치 | preflight 전부 ✓(design 제외) · CLAUDE.md 38줄, `@` import 0, 플레이스홀더 0 · rules 3 `paths:` · 훅 4 · deny 12 · ESLint boundaries+apiContractConfig · OpenSpec feature(`## Contract`) · DRAFT 스펙+orval 생성물 · CI oasdiff | ✅ |
| 2 | `pnpm verify` | api:check → tsc → eslint → vitest 2/2 → knip | ✅ |
| 3 | 경계 위반 린트 | `src/shared/lib/_probe.ts` → `@/domains/todos` | ❌ **통과해 버림**(아래 결함 1) |
| 4 | 테스트 파일 보호 훅 | `TDD_PHASE` 없이 `cn.test.ts` Edit | ✅ 거부 |
| 5 | OpenSpec feature 스키마 | `new change` → status 2 artifacts · schema validate | ✅ (`_probe` 이름 불가 → `probe-tmp`) |
| 6 | commitlint / `--no-verify` | bad message · `--no-verify` | ✅ / ✅ 거부 |
| 7 | 계약 강제 | `fetch`+`axios` 프로브 → 2 errors · `client.gen.ts` Edit → 거부 | ✅ / ✅ |
| 8 | 에이전트 행동 | 막힌 항목을 우회하지 않고 원인·검증된 패치·미적용 이유 보고, "완료" 미선언, 첫 커밋 안 함 | ✅ 의도대로 |

## 발견한 결함 → 조치
| # | 결함 | 심각도 | 조치 |
|---|---|---|---|
| 1 | **경계 린트가 조용히 꺼져 있음** — eslint-plugin-boundaries 7.2는 레거시 `import/resolver`만 읽는데 템플릿에 resolver 설정이 없어 `@/…` import가 external 취급 | 높음 | `templates/eslint.boundaries.js`에 `import/resolver` + `import-x/resolver-next` + 원인 주석. 스크래치에서 alias·상대·내부경로 3변형 에러 확인 |
| 2 | boundaries 메시지 `${file.captured?.name ?? ''}` 미렌더 | 낮음 | `${file.type} → ${dependency.type}`만(실측 렌더) |
| 3 | Figma 없음인데 preflight가 design 2항목 ✗ → "세팅 완료" 불가 | 중간 | `design/` 없음 또는 `design/NO_FIGMA`면 섹션 생략. SKILL 12행 |
| 4 | 자가 검증 `openspec new change _probe` — `_` 불가 | 낮음 | `probe-tmp`, CLI 없으면 `npx -y @fission-ai/openspec@latest` |
| 5 | 자가 검증 2번이 통과해도 원인 모름 | — | SKILL에 "통과하면 resolver 문제" 힌트 |

## 관찰 (수정 안 함)
- 에이전트가 **TanStack Router**를 묻지 않고 선택·설치 → 1장 질문에 "라우터" 항목 필요.
- 자가 검증에서 찾은 버그를 **자기 보호 훅**(`eslint.config.*`) 때문에 못 고침. 세팅 단계는 첫 커밋 전이라 보호를 4장 이후에 켜는 안 검토 (ADR 0005와 충돌 여부).
- headless 10분 제한: 설치가 큰 몫. 대화형이면 문제없음.
- 생성물 `src/domains/todos/{model,api}/.gitkeep`, `shared/ui/button` + browser 테스트 1개, `shared/lib/cn` + 테스트 1개 — 시드로 적절.

## 다음
- `/cgamja:develop-fe` Tier-1(한 줄 수정) → Tier-2(`todos` 목록+추가, 상태 B·D) → retrofit(상태 C)

# 0014 — 절차 / 프로젝트 선언 / 관심사별 references 세 층. 스택은 정하지 않고 읽는다

- 상태: 제안
- 날짜: 2026-08-22
- 관련: `docs/philosophy.md`(근거), 0010(개정 — "-fe 접미사" 논리), 0008(개정 — orval은 조건부 절로), 0004·0006(예시 스택으로 강등), 0013(검증)
- 검증: 미검증. 첫 증거는 React가 아닌 brownfield 프로젝트 1개에서 `/develop-fe`가 도는 것

## 맥락
플러그인 목표는 "어떤 프론트엔드 프로젝트(greenfield/brownfield, 스택 불문)에서든 스펙·테스트 게이트·증거·디자인 원천·접근성·계약·경계·리뷰 렌즈를 적용하는 절차 스킬"이다(`docs/philosophy.md`). 그런데 레포는 React/Next/Expo를 전제로 지어졌다: `develop-setup`이 스택을 묻고 스캐폴드하며(12곳), `references/*-frontend.md`에 Vitest·MSW·orval·jsx-a11y가 원칙과 섞여 있고(tdd 18·api-contract 21곳), persona에 Next/Expo 항목이 박혀 있다. 2026-08-22 "스택 프로필" 제안은 거부됐다 — 프로필을 늘리는 건 greenfield 보일러플레이트의 다른 이름이다.

리서치(2026-08-22, compound-engineering·superpowers·addyosmani/agent-skills·anthropics/skills·OpenSpec·vercel): 절차 플러그인이 스택 무관을 유지하는 방식은 수렴돼 있다 — ① 절차는 "프로젝트의 테스트 명령을 써라"처럼 **슬롯 이름**으로만 말하고, ② 규약은 **프로젝트가 선언**(CLAUDE.md/AGENTS.md, OpenSpec `config.yaml` `context:`, CE `.compound-engineering/config.yaml`)하며, ③ 스택 지식은 관심사별 문서 안의 조건부 절이나 "diff가 그 런타임을 건드릴 때만" 붙는 리뷰어로 둔다. 세팅 스킬은 전부 brownfield 점검(CE `ce-setup`, claude-automation-recommender)이고 스캐폴드는 0. MSW·OpenAPI를 공통으로 두는 곳은 없다. 스택별 reference 파일(react용·vue용)을 분기·선택하는 로직도 없다.

## 결정
1. **세 층**으로 나눈다.
   - **① 절차**(`skills/`, `agents/`): 프레임워크·도구 이름이 조건으로 나오지 않는다. "verify 명령", "테스트 파일 패턴", "계약 원천", "생성물 경로"처럼 ②의 슬롯 이름만 쓴다. `tests/test_stack_words.sh`가 이를 기계적으로 검사한다.
   - **② 프로젝트 선언**(대상 레포의 `.claude/cgamja.json` + `CLAUDE.md` + `.claude/rules/`): 플러그인이 읽는 사실. 스키마는 §슬롯. 훅·스모크·리뷰어는 이 파일을 읽고, 없으면 "세팅 누락"으로 멈춘다(임의로 `pnpm`·`vitest`를 가정하지 않는다).
   - **③ references**(관심사별: tdd, a11y, api-contract, platform-fit, design-source, project-conventions): 앞부분은 스택 무관 원칙(P1~P10의 구체화), 뒷부분은 "검증된 구현" 절 — 스택·도구·버전·날짜를 제목에 박는다(예: "§7 React+Vite 검증 2026-08-21: Vitest Browser Mode·MSW·orval"). 절차는 원칙 절만 참조하고, 구현 절은 세팅 스킬이 "강제 수단이 없을 때 붙일 검증된 조각"으로 쓴다.
2. **develop-setup → 발견·대조·최소 제안.** 스택 질문과 스캐폴드를 없앤다. 순서: 읽기(매니페스트·테스트 러너·린터·CI·기존 테스트 위치) → P1~P10 **강제 수단 대조표**(테스트 파일 보호 / 계약 생성 / 경계 린트 / a11y 린트 / 완료 명령 한 곳 / 디자인 원천 / 플랫폼 프로필) → 없는 것만 기존 도구 위에 제안(③의 검증 조각이 있으면 그것, 없으면 조사·설치·실측 후 ③에 추가) → 프로브로 "진짜 막나" 확인(`smoke.sh check`) → ②에 기록. 빈 폴더면 사용자가 고른 스캐폴더를 **돌려주기만** 하고 그 뒤는 같은 절차.
3. **리뷰어 persona**: 스택 무관 질문만 본문에. Next/Expo 같은 항목은 "diff가 해당 런타임 파일을 건드릴 때만" 읽는 조건부 절로 분리(CE 방식). ②의 플랫폼 프로필·파일 패턴을 입력으로 받는다.
4. **훅·템플릿**: 스택 무관 강제 조각(테스트 파일 보호, 생성물 보호, `--no-verify` 거부, commit-msg 테스트 분리)은 유지하되 패턴·명령을 ②에서 읽는다. `vitest.config.ts`·`eslint.boundaries.js`·`orval.config.ts`·`jest.expo.md`는 ③의 React 검증 조각으로 이동. 버전 고정 deps 목록·스캐폴드 스크립트는 만들지 않는다.
5. **보존**: React/Vite 실측(orval 8 동작, hey-api TS6 충돌, Browser Mode Chromium 전용, `.prettierignore` 누락이 `api:check`를 깨뜨림 등)은 삭제하지 않고 ③의 구현 절로 라벨을 붙여 옮긴다. 범용의 증거는 삭제가 아니라 두 번째 스택에서 절차가 도는 것이다.
6. **이름**: `-fe` 접미사는 유지한다(프론트엔드 관심사 — 디자인 원천·접근성·플랫폼·스크린샷 증거 — 가 절차에 있다는 뜻이지 React라는 뜻이 아니다). 0010 §3의 "React 고유한 것이 절차에 박혀 있어서"는 이 ADR로 대체.

## ② 슬롯 (`.claude/cgamja.json`)
| 키 | 뜻 | 예(React+Vite) | 예(다른 스택) |
|---|---|---|---|
| `commands.verify` | 완료 정의 한 줄 | `pnpm verify` | `make check`, `npm run ci` |
| `commands.typecheck` / `test` / `lint` / `dev` | 개별 명령(없으면 null) | `pnpm typecheck` | `./gradlew test` |
| `tests.patterns` | 테스트 파일 glob(훅이 보호) | `["**/*.test.*","e2e/**"]` | `["**/*.spec.ts","cypress/**"]` |
| `tests.layers` | 계층 이름 → 실행 명령·파일 규약 | `{unit:…, browser:…, e2e:…}` | `{unit:…, e2e:…}` |
| `contract.source` / `generate` / `generated` | 계약 원천 파일 · 생성 명령 · 생성물 glob(훅이 보호) | `api/openapi.yaml` / `pnpm api:gen` / `src/api/**/*.gen.ts` | `schema.graphql` / `npm run codegen` / `src/gql/**` 또는 null |
| `mock.boundary` | 네트워크 경계 mock 방식(원칙 P7 확인용) | `msw` | `nock`, `playwright route`, `mirage` |
| `design.source` | 디자인 원천 | `figma:<fileKey>` / `none` | 동일 |
| `design.tokens` | 토큰 파일 | `src/styles/tokens.css` | `tokens.json` |
| `platform.profile` | `web-desktop` / `web-mobile` / `native` | | |
| `domains.root` / `allowed_edges` | 경계 린트와 1:1 | `src/domains` / `[]` | `src/features` |
| `a11y.lint` / `a11y.runtime` | 1·2층 도구(없으면 null → 세팅이 제안) | `jsx-a11y` / `axe` | `vue-a11y` / `axe` |

없는 키는 null. null인 강제 수단은 세팅 스킬의 제안 목록이 되고, 절차는 null이면 그 단계를 "수동 증거"로 대체한다(예: a11y.runtime null → 리뷰 렌즈 L4가 더 넓게 본다).

## 전제
- 대상은 JS/TS 프론트엔드가 대부분이지만 절차는 그것도 가정하지 않는다. 네이티브(Flutter/SwiftUI)는 `platform.profile: native`로 들어올 수 있되 검증된 조각이 없다고 명시.
- 선언 파일은 사람이 읽고 고칠 수 있을 만큼 작아야 한다(≤40줄).

## 재검토 조건
- 두 번째 스택 brownfield 런에서 절차가 멈춘 지점이 ②의 슬롯 부족이면 슬롯 추가, 절차의 숨은 스택 가정이면 ①을 고치고 `test_stack_words.sh`에 단어 추가.
- 선언 파일이 40줄을 넘거나 사용자가 채우기를 거부 → 발견 단계가 더 자동으로 채워야 함.
- ③의 구현 절이 원칙 절보다 3배 이상 길어지면 별도 파일로 분리(단, 선택 로직은 만들지 않는다 — 세팅이 링크만).

## 결과 / 영향
순서(각각 커밋 1개 이상): ① `tests/test_stack_words.sh` + 절차 문서 치환 → ② `.claude/cgamja.json` 스키마·예시 + 훅이 읽게 → ③ references 6개 분리 → develop-setup 재작성 → smoke.sh가 ②를 읽게 → brownfield 런 1회 → 0010·0008 개정 주석.

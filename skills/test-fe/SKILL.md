---
name: test-fe
description: 프론트엔드 테스트 코드를 쓰는 기준과 루프 — 시나리오(OpenSpec `#### Scenario` 또는 사용자 문장)를 받아 계층(단위 / 브라우저 / E2E — 프로젝트 선언 `tests.layers`) 하나를 고르고, 역할 쿼리·네트워크 경계 mock으로 실패하는 테스트를 먼저 쓰고, 실패 출력과 이유를 보여 사람 승인(red 게이트)을 받아 `test(scope):` 커밋까지 간다. 사용자가 "테스트 써줘", "이 컴포넌트 테스트 추가", "이 시나리오 테스트로", "테스트 커버 안 된 거 찾아줘", "이 테스트 왜 flaky해"라고 하거나 /test-fe 를 부르거나, develop-fe의 테스트 task를 수행할 때 반드시 사용한다. 네이티브(RN 등)도 같은 루프. 테스트를 초록으로 만들기 위해 assertion을 고치는 요청은 거부하고 이 스킬의 규칙을 설명한다.
---

# test-fe

테스트는 여기서 품질 기법이 아니라 **리뷰 게이트 + 변조 방지**다(`adr/0004`, `adr/0009`). 실패하는 테스트를 사람이 30초에 읽고 승인하는 것이 스펙 리뷰이고, 커밋된 테스트를 구현자가 못 고치는 것이 치팅 방지다. 기준 원문은 플러그인 루트 `references/tdd-frontend.md` — 이 파일은 **언제 어느 절을 읽고 무엇을 내놓는지**만 정한다.

## 입력
- 시나리오: OpenSpec `spec.md`의 `#### Scenario`(WHEN/THEN) 또는 사용자 문장. 문장이면 먼저 WHEN/THEN 한 쌍으로 고쳐 쓰고 확인받는다 — 시나리오 1개 = 테스트 1개.
- 프로젝트 설정: `vitest.config.ts` projects(unit/browser) 또는 `jest.config`, `test/msw/handlers.ts`, `test/factories/`. 없으면 `/develop-setup` 7번 항목이 빠진 것 — 즉흥으로 만들지 않고 안내 후 멈춘다(Tier-1 단일 파일 테스트는 예외).

## 절차
1. **계층 하나 고르기** — `tdd-frontend.md` §1 표. 인터랙션·포커스·레이아웃이면 **브라우저 계층**(선언 `tests.layers.browser`가 null이면 단위 계층 + DOM 시뮬레이션으로 내리고, 레이아웃·포커스 시나리오는 E2E 또는 스크린샷 증거로 — `tdd-frontend.md` §1), 로직·훅·텍스트만이면 **단위 계층**, 화면을 건너면 E2E(계층별 러너·파일 규약은 프로젝트 선언 `tests.layers`)(3~5개 고정 목록에 있을 때만). 고른 이유를 한 줄로.
2. **같은 걸 검증하는 테스트가 이미 있나** grep(시나리오 키워드, 컴포넌트명). 있으면 그 파일에 추가하고 중복 테스트를 만들지 않는다.
3. **테스트 작성** — §3 규칙: `getByRole` > `getByLabelText` > … > `getByTestId`(최후, 이유 주석 필수). mock은 네트워크 경계(`mock.boundary`)에서만, 핸들러는 계약 생성물이 제공하면 그것을 기본으로 시나리오별 override. 자식 컴포넌트·훅·store mock 금지. 비동기는 자동 재시도 expect. 테스트 이름은 `WHEN … THEN …` 원문.
4. **red** — 껍데기(빈 export)로 import만 통과시키고 실행. **실패 출력 원문 + 이유 한 줄**("요소 없음 — 기능 미구현"). import 에러·오타는 red가 아니다 → 3으로.
5. **사람 게이트** — 테스트 파일 Edit는 권한 `ask`가 뜬다(adr/0009). 승인되면 `test(scope): <시나리오>` 커밋(`/ce-commit`). 거부되거나 비대화형이라 승인자가 없으면 **구현으로 넘어가지 말고 멈춰서** 알린다.
6. 구현은 이 스킬의 일이 아니다 — develop-fe(`opsx:apply`)로 돌아가거나 사용자에게 넘긴다. 구현 턴에서 테스트를 고쳐야 하면 **새 red 턴**(이유 + 별도 `test()` 커밋).

## 단독 호출 모드
- "테스트 커버 안 된 거 찾아줘": `openspec/specs/<cap>/spec.md` 시나리오 ↔ 테스트 이름 대조표를 내고(Explore, `haiku`), 빠진 것마다 1~5를 돈다. 스펙이 없으면 컴포넌트의 사용자-가시 동작을 나열해 시나리오 후보로 제안하고 확인받는다.
- "flaky 원인": `tdd-frontend.md` §1 CI 주의(브라우저 계층 메모리·iframe), §3(`waitForTimeout`, `setTimeout`, 공유 상태), §4 표로 분류. **끄거나 retry를 늘리는 것으로 끝내지 않는다** — 원인 분류 결과와 고친 assertion을 보여준다. 2번 고쳐도 flaky면 그 테스트만 단위 계층으로 내린다(삭제 아님).
- "이 테스트 통과하게 고쳐줘"(구현이 아니라 테스트를 고치라는 요청): assertion 완화·skip·snapshot 재생성은 거부. 스펙이 바뀐 거면 spec 수정 → 새 red 턴으로 안내.

## 출력 (완료 정의)
- 계층 선택 이유 1줄 · 테스트 파일 경로 · **실패 출력 원문 + 이유** · 커밋 해시(승인됐을 때)
- mock 목록("경계 핸들러 2개, 기타 0")
- 이것 없이 "테스트 작성했습니다"는 완료가 아니다.

## 절대 하지 않는 것
- 테스트와 구현을 한 턴에
- `it.skip`/`.only`/`expect(true)`/`toBeDefined`만 있는 assertion/모듈 mock(`src/**` 대상, 계약 생성물 제외)
- Bash로 테스트 파일 쓰기(`sed -i`, `>`, `perl -pi`) — 훅이 거부, 의도적 우회로 본다
- 테스트 목적만으로 Storybook·새 러너 도입

## 파일
| 파일 | 언제 |
|---|---|
| `references/tdd-frontend.md` | 항상 — §1 계층표, §2 루프, §3 쿼리·mock, §4 실패 모드, §6 예시, §7 설정 |
| `references/a11y-frontend.md` §1 | 역할로 요소를 못 찾을 때 — 테스트가 아니라 마크업 문제 |
| `references/api-contract.md` §4 | 경계 mock 핸들러를 계약 생성물에서 가져올 때 |
| `references/model-routing.md` | 대조표·탐색을 서브에이전트로 뺄 때 모델 |

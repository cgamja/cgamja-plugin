# 0010 — develop-fe는 오케스트레이터, 전문 스킬·persona·references는 플러그인 루트에

- 상태: 제안
- 날짜: 2026-08-21
- 관련: 0001(도구 분담), 0004(TDD), 0007(훅), 0012(리뷰 렌즈), 0011(모델 라우팅)

## 맥락
develop-fe가 티어·Figma·API 계약·TDD·리뷰·PR을 한 스킬(SKILL.md 76줄 + workflow.md 172줄 + references 7개)에 들고 있었다. 접근성·플랫폼 적합성·티어별 리뷰 렌즈·모델 라우팅을 추가하려 하자 (a) 한 번에 로드되는 컨텍스트가 더 커지고 (b) "테스트만 써줘", "이 PR 봐줘" 같은 단독 요청이 develop-fe 전체 절차를 타야 했다. addyosmani/agent-skills의 구조(얇은 스킬 + 공유 `references/` + persona `agents/`)가 같은 문제의 해법이다.

## 결정
1. **develop-fe는 절차(티어 판정 → 스펙 → 구현 루프 → 증거 → 리뷰 → PR)만 남긴다.** 테스트 작성 지식은 `test-fe`, 리뷰 실행은 `review-fe`로 빼고 develop-fe는 그 둘을 **호출**한다. 호출 지점은 `workflow.md`와 `hooks/`에만 둔다(이름 변경 비용을 두 곳으로 고정).
2. `references/`, `adr/`, `reports/`, `agents/`는 **플러그인 루트**로 올린다 — 스킬 간 공유물이므로. 스킬 문서 안의 `references/...`·`adr/NNNN` 경로는 플러그인 루트 기준이다(`${CLAUDE_PLUGIN_ROOT}`).
3. 스킬 이름은 `-fe` 접미사를 유지한다(`test-fe`, `review-fe`). 접근성·플랫폼·계층 선택처럼 FE 고유한 것이 지식이 아니라 **절차(어떤 증거·도구)** 에 박혀 있어 범용 스킬로 만들면 본문이 스택 분기투성이가 된다. 두 번째 스택(백엔드)이 생기면 `review-be` 형제로 복제하고, 둘을 써 본 뒤 공통 코어가 선명해질 때만 추출한다(rule of three). references 파일명은 처음부터 `-frontend` 접미사로 둬서 그때 스킬 이름만 바뀌게 한다.
4. **접근성은 산문이 아니라 세 층(린트 → axe → 역할 쿼리)으로 강제**하고, 기계가 못 잡는 것만 `references/a11y-frontend.md` §2에 둔다. `develop-setup`이 `eslint-plugin-jsx-a11y`/`react-native-a11y`와 axe를 깐다.
5. **플랫폼 적합성은 프로필 파일**(`.claude/rules/platform.md`, 템플릿 `platform-{web,expo}.md`)이다. develop-fe·review-fe 본문은 "프로필을 읽어라"만 쓰고 뷰포트 숫자를 직접 들지 않는다.
6. persona(`agents/reviewer-*.md`)는 Claude Code 플러그인 `agents/` 포맷(frontmatter name/description/model/tools)으로 쓴다. 마켓플레이스 설치면 서브에이전트 타입으로 뜨고, skills-dir 심링크 설치(현재)면 review-fe가 파일을 읽어 Agent 도구 프롬프트로 넘긴다 — **두 경로 모두 같은 파일**.

## 결과
- develop-fe 로드 시 컨텍스트: workflow.md에서 3-2 테스트 규칙·2장 5번 리뷰 절차가 한 줄씩으로 줄어든다. 상세는 호출 시점에만 로드.
- 단독 호출 가능: `/cgamja:test-fe "SubscribeForm 빈 이메일 시나리오"`, `/cgamja:review-fe pr 42`.
- 훅 `skill_guard.sh`의 bare `ce-code-review` 거부는 유지(review-fe가 스펙 경로를 조립해 부른다). `review_nudge.sh`는 `/review-fe`를 안내.

## 검증 (채택 조건)
- Tier-2 change 2개를 새 구조로 돌려 `reports/`에: develop-fe 본체 토큰이 이전(~65k)보다 줄었는지, review-fe 렌즈 병렬이 `ce-code-review` 단독(58k)보다 지적 수·정확도에서 나은지.
- `test-fe` 단독 호출 1회: develop-fe 없이 red 게이트(adr/0009)가 그대로 작동하는지.

## 재검토
- 스킬 간 호출이 workflow.md·hooks 밖으로 새면(다른 파일이 `/review-fe`를 직접 언급) 이 ADR 위반 — 한 곳으로 되돌린다.
- 백엔드 스킬이 생기면 3번 항목 재평가.

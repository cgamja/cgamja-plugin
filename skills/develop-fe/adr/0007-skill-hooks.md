# 0007. 스킬 frontmatter 훅 — 금지 스킬 호출 차단, 세팅 누락 경고
- 상태: 제안
- 날짜: 2026-08-21
- 검증: (없음 — 단위 테스트·headless 통합 테스트만)

## 맥락
adr/0005는 "규칙은 산문이 아니라 훅·린트로"라고 했지만 develop-fe 스킬 자신의 규칙("ce-plan/lfg 금지", "ce-code-review엔 `plan:` 필수", "ce-work는 return-to-caller만", "세팅 없으면 /develop-setup")은 SKILL.md 산문뿐이었다. 특히 `ce-code-review`를 스펙 경로 없이 부르면 **조용히** 요구사항 누락 검사가 빠진다(adr/0001) — 실패가 보이지 않는 규칙이야말로 훅이 필요하다.
메커니즘 실측은 `cgamja-private`의 `app-ref-to-figma/adr/0004` 맥락과 동일(2.1.238, 2026-08-21). `Skill` 도구의 `tool_input.skill`은 `plugin:name` 형태로 온다.

## 결정
1. `PreToolUse` matcher `Skill` → `hooks/skill_guard.sh`: `ce-plan`·`lfg` deny, `ce-work`는 args에 `mode:return-to-caller` 없으면 deny, `ce-code-review`는 args에 `plan:` 없으면 deny. deny 사유에 대체 경로를 적어 에이전트가 바로 고치게 한다.
2. `PreToolUse` `Edit|Write|MultiEdit` `once: true` → `hooks/setup_check.sh`: `package.json#verify`·`openspec/config.yaml`·`.claude/rules/`·settings Stop 훅 중 누락을 **additionalContext로 경고**. 차단하지 않는다 — Tier-1 한 줄 수정 예외가 있어 hard deny는 틀린 규칙이다.
3. 프로젝트 템플릿(`develop-setup/templates/settings.json`)에 있는 규칙(테스트 파일 보호, `--no-verify`, package.json 보호)은 스킬 훅에 **중복하지 않는다**(adr/0005 5항; 플러그인/스킬 훅은 settings 훅과 별도로 실행돼 두 번 돈다).
4. 끄기: 세션 시작 전 `DEVELOP_SKILL_GUARD=off`.

## 전제
- 가드는 세션 끝까지 남는다. develop을 쓴 세션에서 사용자가 나중에 의도적으로 `/ce-plan`을 원하면 에이전트 경유 호출은 막힌다 → 사용자가 직접 타이핑하면 `Skill` 도구를 거치지 않아 통과한다(의도된 비대칭).
- CE 플러그인 스킬 이름이 `ce-*`/`lfg`를 유지한다.

## 재검토 조건
- 가드 deny 뒤 에이전트가 같은 호출을 반복(사유를 못 읽음) 2회 → 사유 문구 개정.
- 실험 B(adr/0001)로 ce-work가 기본 경로가 됨 → ce-work 규칙 삭제.
- setup_check 경고에도 즉흥 세팅을 만든 사례 2회 → deny로 승격(단 Tier-1 판별 방법 필요).
- Claude Code가 `UserPromptExpansion`으로 타이핑 호출도 잡는 것이 확인되고 필요해지면 추가.

## 결과 / 영향
- `hooks/` 3개 파일(`_lib.sh`, `skill_guard.sh`, `setup_check.sh`). SKILL.md "절대 하지 않는 것"은 훅 참조로 보강.

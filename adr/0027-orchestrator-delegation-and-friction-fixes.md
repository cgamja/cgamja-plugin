# 0027. 실사용 마찰 반영 — 구현 위임 오케스트레이션, worktree 병렬, 계약 도메인 분리, 테스트 동결, 증거 비저장, jscpd 폐지

- 상태: 제안
- 날짜: 2026-08-31
- 관련: 0026(v2 전환), 0019(린 워크플로우), 0018(red 게이트), 0008(API 계약), 0006(도메인 구조)
- 근거 리서치: Anthropic sub-agents/worktrees/best-practices 공식 문서, multi-agent research system 블로그, compound-engineering ce-work 구현 엔진 원문 (2026-08-31 조사)

## 문제 (v2 실사용 14개 마찰 중 이 ADR이 다루는 것)

- **컨텍스트 폭발**: Tier-1 한 번에 ~40%, Tier-2에 ~80%. 메인 세션이 스펙·구현·테스트·증거·리뷰 통합을 전부 직접 해서다 (마찰 4·6·7)
- **직렬 강제**: 독립 change도 한 세션에서 순차 처리 — 실제 개발처럼 병렬 브랜치 작업이 안 됨 (마찰 8)
- **Orval 생성물 집중**: `src/api/` 한 곳에 모여 FSD 도메인 응집이 깨짐 (마찰 1)
- **테스트 수정 루프**: 리뷰 → 테스트 수정 → 코드 수정 반복으로 토큰 폭발 (마찰 2)
- **증거 파일 비대**: 스크린샷·evidence 디렉터리가 프로젝트 저장소에 커밋돼 레포가 커짐 (마찰 10)
- **CI 제약 낭비**: jscpd·커밋 린트가 CI에서 Fail → 고치는 비용이 검출 가치를 초과 (마찰 13)

## 결정

1. **역할 분리 — 메인은 오케스트레이터만.** 메인 세션은 티어 판정·스펙(OpenSpec)·task 분해·결과 통합·커밋만 소유한다. **구현·테스트 작성 task는 unit당 서브에이전트 1개(fresh context)로 위임**한다. 예외(inline 허용): Tier-1, 1~2파일 trivial, 사용자 상호작용이 중간에 필요한 task.
   - **unit packet 규격**(위임 프롬프트): 해당 requirement 발췌 + 대상 파일 + 테스트 시나리오 + 검증 명령 + `docs/spec/` 경로(서브에이전트는 대화 이력·로드된 스킬을 못 받으므로 명시 필수; CLAUDE.md·rules·훅은 자동 적용됨) + "커밋 금지, 최종 메시지에 JSON 리포트" 지시. "스펙 전체를 읽어라"는 금지.
   - **리포트 계약**: `{status: completed|blocked|scope_expansion, changed_files: [...], evidence: {red 관찰, 검증 명령·결과}}`. 메인은 프로즈를 믿지 않고 `git diff --stat` + 검증 명령 재실행으로 실물 확인 후 커밋한다(diff 전문을 메인 컨텍스트에 넣지 않는다).
   - **실패 규칙**: blocked/scope_expansion이면 packet을 고쳐 1회 re-dispatch, 2회 실패 시 inline 강등. 깨진 트리 위에 다음 unit을 보내지 않는다.
2. **컨텍스트 예산.** 페이즈 경계(스펙 확정 후, 구현 완료 후)에서 컨텍스트 ~50% 초과면 보존 지시 포함 `/compact` 또는 handoff 후 새 세션으로 리뷰~PR 진행. 근거: Claude Code 팀 권고 50~60% 선제 compact, auto-compact 기본 ~77~84%.
3. **worktree 병렬 (마찰 8).** 독립 change는 병렬로:
   - 사용자 주도: 터미널마다 `claude --worktree <slug>`로 change별 세션. 세션 간 상태 공유는 git·파일뿐이라고 가정
   - 병렬 가능 판정(ce-work Parallel Safety Check 이식): 의존 unit이 이미 커밋됨 + 파일 겹침 없음 + **semantic 표면**(공유 타입·계약·lockfile·생성물·config)도 겹침 없음 + 환경 싱글턴(dev server 포트·브라우저 세션) 불충돌. **불확실하면 직렬** — 속도는 옵션. 동시 상한 3
   - 머지: 의존성 순서로 1개씩 integrate → verify → commit. clean merge는 호환 증명이 아니다 — 전진한 트리에서 재검증. 충돌 unit은 새 base에 re-dispatch
   - 오케스트레이터가 `git worktree add`를 직접 하지 않는다 — 격리는 하네스(`--worktree`, `isolation: worktree`)의 일. `.claude/worktrees/`는 gitignore, `.worktreeinclude`로 `.env` 복사(worktree별 PORT)
4. **계약 생성물 도메인 분리 (마찰 1).** orval `mode: "tags-split"` — OpenAPI `tags` = 도메인 이름, endpoint마다 태그 정확히 1개(스펙 린트로 강제), 생성물이 각 도메인 api 세그먼트로 갈라진다. 공유 스키마는 한 곳(shared 취급). 새 feature 추가 = 새 태그 = 새 도메인 폴더. `docs/guides/api-contract.md` §8-b. (tags-split 경로는 문서 반영만 — 첫 적용 시 실측해 갱신)
5. **테스트 동결 (마찰 2).** `test(scope):` 커밋 후 테스트는 동결. 다시 여는 조건은 ① 스펙 변경 확정 ② 테스트 자체 결함 둘뿐이고, 모아서 커밋 1개. 리뷰 지적이 테스트 수정을 요구하면 ①/② 판정부터 — 아니면 "수정 안 함 + 이유". 리뷰 재검사 1회 상한(0019)과 결합해 수정 루프를 끊는다.
6. **증거 비저장 (마찰 10).** 확인용 스크린샷은 `.claude/state/evidence/`(gitignored)에만 — 저장소에 커밋되는 시각 파일은 **qa-cgamja baseline(LFS)뿐**. `evidence/` 류 커밋 디렉터리 폐지.
7. **jscpd 폐지 (마찰 13).** CI에서 jscpd 제거. 중복·품질 검출은 "만들기 전 grep" + 철학 문서 대조(`docs/spec/GOOD-BAD-PATTERN.md`·`CLEAN-CODE.md`, review-cgamja가 강제)로 대체. 커밋 형식 제약은 CI가 아니라 **pre-commit/pre-push git 훅**(0026 §6)에서 푸시 전에 잡아 커밋을 고치게 한다 — CI는 사후 고발이라 수리 비용이 크다.
8. **문서 폴더 재편.** 오래된 v1 근거 문서(`methodologies.md`, `verdicts-2026-08-21.md`)는 `reports/`(역사 기록)로 이동, `figma-design-source.md`에서 픽셀 대조(§6)·Figma 쓰기 경로 삭제(0026 §9와 정합). 남은 `references/`는 **`docs/guides/`로 통합** — 문서가 답하는 질문으로 나눈다: `docs/spec/`(무엇이 좋은 코드인가 — 판정 기준), `docs/guides/`(어떻게 작업하는가 — 절차 지식), `docs/` 루트(플러그인 자기 설명), `adr/`·`reports/`(기록 — 불변 이력이라 docs 밖). "references"라는 이름은 폐지.

## 대안과 트레이드오프

- **위임 없이 /compact만**: 창은 비워지지만 메인이 구현 디테일을 계속 소유해 판단 품질이 떨어진다. 위임은 총 토큰을 늘리는 대신(멀티에이전트 ≈ 챗의 15배) 오케스트레이터 창을 보존해 품질을 산다 — 비용은 unit packet 최소화·리포트 JSON·diff 미수신으로 통제.
- **worker에게 커밋 허용**: 왕복은 줄지만 검증 없는 커밋이 생긴다. 커밋·staging·최종 검증은 메인 소유(ce-work 판정 채택).
- **jscpd 유지**: 중복은 에이전트 1위 실패라 센서가 필요하지만, 실측상 오탐 수리 비용 > 검출 가치. review-cgamja의 GOOD-BAD-PATTERN 대조가 같은 지점을 사람이 읽을 수 있는 판정으로 커버.
- **감수한 비용**: 서브에이전트 위임으로 세션당 총 토큰은 늘 수 있다(창 보존과 트레이드). tags-split은 미실측 — 첫 적용에서 경로가 다르면 §8-b 갱신 비용.

## 재검토 조건

- 위임 unit 2회 연속 blocked → packet 규격(무엇이 빠졌나) 점검, 그래도면 해당 task 유형 inline 복귀
- 메인 컨텍스트가 위임 후에도 Tier-2에서 60% 초과 2회 → 리뷰·QA 단계를 새 세션으로 분리(handoff 기본화)
- 병렬 머지 충돌이 세션당 2회 → Parallel Safety Check 항목 보강 또는 상한 하향
- 테스트 동결 때문에 실제 결함 수정이 지연된 사례 2회 → 동결 예외 ③(리뷰어 무결성 지적) 추가 검토
- tags-split 적용 실측 후 경로·경계 린트 확인 → §8-b·템플릿 갱신하고 이 ADR에 실측 날짜 기록

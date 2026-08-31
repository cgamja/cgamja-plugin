# 0026. develop-fe v2 — 티어 축소, 외부 스킬 조합, 디자인 플래그, git 훅 게이트, SPEC 문서 이관

- 상태: 제안
- 날짜: 2026-08-31
- 관련: 0001(OpenSpec 척추), 0004(TDD=게이트), 0010(오케스트레이터 분리), 0012(리뷰 렌즈), 0019(린 워크플로우)

## 문제

develop-fe v1은 자급자족형이었다 — 테스트(`test-fe`), 리뷰(`review-fe` + 렌즈 persona 7종), 증거 규칙을 전부 플러그인 안에서 만들었다. 그 사이 생태계에 검증된 스킬이 쌓였고(`docs/spec/AI-SPEC.md`에 목록), 자작 스킬을 유지보수하는 비용이 외부 스킬을 조합하는 비용보다 커졌다. 또한:

- Tier-3(에픽·change 다중·세션 분리)는 실사용에서 발동된 적이 없고 판정표만 무겁게 했다
- 철학 문서(cgamja-philosophy 레포)가 플러그인 밖에 있어 review-cgamja가 프로젝트마다 사본을 요구했다
- 커밋 품질(형식·테스트 분리)이 푸시 시점에 강제되지 않아 리뷰에서야 걸렸다
- 디자인 작업의 입력·출력 조합(와이어프레임/디자인)이 플래그 없이 산문으로만 구분됐다

## 결정

1. **티어 2단계로 축소.** Tier-1 = 바로 진행(아티팩트 없음), Tier-2 = OpenSpec change 1개. Tier-3 삭제 — 큰 작업은 Tier-2 change 여러 개로 쪼갠다(분해 휴리스틱은 유지하되 별도 세션 강제는 폐지).
2. **테스트는 외부 TDD 스킬.** `test-fe` 스킬 삭제. TDD 루프는 addyosmani `test-driven-development` 스킬(빨간 불 먼저·버그는 재현 테스트 먼저), 브라우저 런타임 검증은 `browser-testing-with-devtools`(Chrome DevTools MCP)로. red 게이트(실패 출력 원문 제시, adr/0018)와 테스트 파일 보호 훅은 워크플로우에 남긴다 — 스킬은 방법을, 훅은 강제를 담당.
3. **리뷰는 review-cgamja + code-review.** 렌즈 persona 경로(`review-fe`) 대신: ① `cgamja:review-cgamja`(철학 대조 — docs/spec/ 근거 인용 판정) ② 공식 `code-review` 플러그인(신뢰도 스코어링 버그 리뷰). `review-fe`와 렌즈 에이전트 6종(`reviewer-a11y`·`architecture`·`performance`·`platform`·`spec`·`tests`), `references/review-lenses-frontend.md`·`tdd-frontend.md`는 **삭제**(사용자 결정 — "기존게 문제가 많았다"; git 이력에 남는다). `reviewer-correctness`만 develop-baby-fe용으로 유지.
4. **QA는 qa-cgamja.** 디자인 리뷰·비주얼 검증은 `cgamja:qa-cgamja`(동작 플로우 스냅샷·baseline 게이트)로 — v1의 SSIM/픽셀 대조 절차는 qa-cgamja의 "실시간 픽셀 대조 금지" 원칙과 충돌하므로 폐기하고 회귀 비교로 통일.
5. **SPEC 문서 이관.** cgamja-philosophy `docs/`(adr 제외)를 플러그인 `docs/spec/`로 복사(원본 레포에도 그대로 남긴다 — 개정은 philosophy 레포에서 하고 플러그인 사본을 동기화). develop-fe가 코드 작성 SPEC으로 읽고(CLEAN-CODE·ARCHITECTURE·WEB/APP-SPEC·GOOD-BAD-PATTERN·LIBRARY·COMMIT·PR·ISSUE·DOCTOR), reviewer-cgamja가 판정 근거로 인용한다. `review-cgamja` 스킬·`reviewer-cgamja` 에이전트도 플러그인으로 복사.
6. **git 훅 게이트.** `templates/git-hooks/pre-commit`(lint+typecheck)·`pre-push`(commands.verify + 커밋 메시지 형식 + feat/fix 커밋의 테스트 파일 혼입 검사). 조건이 안 맞으면 푸시 전에 커밋을 고친다(fixup/reword/autosquash) — `--no-verify`는 기존 훅이 거부. 설치는 workflow 0-b(`core.hooksPath`).
7. **디자인 플래그.** `/develop-fe --only-wf | --only-design | --wf-and-design`:
   - `--only-wf`: 와이어프레임만 입력으로 와이어프레임 산출(구조·플로우, 스타일 없음)
   - `--only-design`: 디자인만 입력으로 하이파이 디자인 산출
   - `--wf-and-design`: 와이어프레임을 입력으로 하이파이 디자인 산출
   플래그 없으면 v1대로 구현까지 간다. 디자인 산출에는 `frontend-design`·`taste-skills`·`frontend-ui-engineering`을 로드.
9. **Figma는 읽기 전용 원천.** v1의 코드→Figma 역캡처(`generate_figma_design` 평면 거울, adr/0003 4단계)와 Figma 산출 옵션을 전부 제거 — 디자인 산출물은 `design` 스킬 캔버스 Artifact + `design/screens/<slug>/summary.md`에만 남긴다. Figma 호출은 읽기(스냅샷·get_design_context)만.
8. **외부 스킬 배치표.** AI-SPEC의 스킬들을 단계별로 고정 배치(워크플로우 본문 표 참조): 탐색=`context-engineering`, 구현=`composition-patterns`(+RN이면 `react-native-skills`)+`typescript-lsp`, 성능 task=`performance-optimization`, 관측 task=`observability-and-instrumentation`, 보안 점검=`claude-security`(요청 시), 설명=`eli5`(사용자용), 장기 작업 현황=`project-artifact`(요청 시).

## 대안과 트레이드오프

- **렌즈 persona 유지**: 커버리지(스펙 완전성 L2, 플랫폼 L5)는 더 넓지만 Tier-2당 ≈$30~45의 주범. code-review(신뢰도 스코어링)+철학 대조 2축이 비용 대비 반영률이 높다고 판단. 반영률이 떨어지면 review-fe 렌즈를 선택 재도입(재검토 조건).
- **test-fe 유지·보강**: 자작 루프의 계층 선택 규칙은 좋았지만 외부 스킬과 이중 유지보수. 계층 선택·쿼리 규칙 중 잃으면 안 되는 것은 워크플로우 3-2에 요약으로 남긴다.
- **문서를 프로젝트마다 복사**: 이관 대신 사본 배포는 드리프트를 만든다. 플러그인 한 곳이 원천.
- **감수한 비용**: 외부 스킬은 우리가 버전을 통제하지 못한다(미설치 시 대체 경로를 워크플로우에 명시). Tier-3 폐지로 초대형 작업의 세션 분리 규칙이 사라짐 — change 분해로 흡수하되, 컨텍스트 폭발이 재발하면 재검토.

## 재검토 조건

- code-review+review-cgamja 2축이 잡지 못한 회귀가 릴리즈 후 2회 → review-fe 렌즈 선택 재도입
- 외부 스킬 미설치로 대체 경로를 탄 세션 3회 → 해당 스킬 vendoring 검토
- Tier-2 change 분해가 4개를 넘는 작업 2회 → 에픽 절차(구 Tier-3) 부분 복원
- pre-push 실패 → fixup 루프가 세션당 3회 이상 반복 → pre-commit 게이트를 강화해 앞당김

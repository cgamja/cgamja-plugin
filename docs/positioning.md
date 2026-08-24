# 지형 위 위치 — cgamja는 무엇이 다르고, 무엇을 빌려 쓰나

근거·갱신 규칙은 `adr/0015`. **이 문서는 서술 근거이지 로드맵이 아니다** — 표를 보고 기능을 늘리지 않는다(philosophy §2). star는 GitHub API 실측만 쓴다(블로그 집계는 2026-08-24 기준 실측과 최대 3배 차이).

## 지형표 (star 실측 2026-08-24)

| 레포 | ⭐ | 성격 | 우리와 겹치는 것 | 우리가 안 하는 것 / 빌려 쓰는 것 |
|---|---|---|---|---|
| obra/superpowers | 276,800 | 범용 스킬 프레임워크 | 훅 자동 트리거, TDD 의무, 자체 eval(`superpowers-evals`), 인프라 테스트 | 범용 워크플로우 경쟁 안 함. eval 방식은 0013 3층 러너 설계 시 설치 실측 후 참고 |
| anthropics/skills | 171,262 | 공식 스킬 모음·규약 | progressive disclosure 구조 | 구조 규약을 그대로 따름 |
| github/spec-kit | 131,009 | 범용 SDD 툴킷 | 스펙 우선 원칙 | SDD 도구를 새로 만들지 않음 — OpenSpec 사용 |
| Fission-AI/OpenSpec | 66,028 | SDD 도구 | — | **척추로 사용**(adr/0001): specs·changes·archive |
| bmad-code-org/BMAD-METHOD | 52,209 | 애자일 롤플레이 방법론 | persona 개념 | 역할극 방법론 안 함 — persona는 리뷰 렌즈에만(adr/0012) |
| EveryInc/compound-engineering-plugin | 24,490 | 워크플로우 플러그인 | brainstorm·debug·commit·PR·학습 | **주변부로 사용**(adr/0001): 겹치는 ce-plan/lfg는 훅이 차단 |

주의: "성격" 이상의 구조 판단(superpowers의 훅이 deny 수준인지 유도 수준인지 등)은 README 레벨이다. 설치 실측 전엔 비교 주장에 쓰지 않는다.

## 차별점 — 이 세 가지만 주장한다 (adr/0015 결정 1)
1. **프론트엔드 증거 스택**: 프론트엔드엔 `tsc` 같은 완결 오라클이 없다. 스크린샷(프로필 뷰포트)·axe·SSIM Figma 대조·디자인 갭 루프·계약 생성물 검사로 "완료"를 기계 판정 가능한 증거로 정의한다(P3~P6, workflow.md 3-1). 조사 범위에서 이 깊이의 프론트 특화 절차는 미확인.
2. **선언 기반 brownfield**(adr/0014): 스택을 정하지 않고 읽는다. `.claude/cgamja.json` 선언을 훅·스모크·리뷰어가 읽고, 없는 강제 수단만 기존 도구 위에 최소로 붙인다. 상위 레포들은 범용이거나 greenfield 지향.
3. **비용·실측 투명성**: 모든 절차 변경은 `reports/` 런 원장($, 턴, 발견)이 근거이고, 티어 판정 시 예상 비용을 먼저 고지한다(SKILL.md 시작 절차 0). "좋아졌다"를 주장이 아니라 A/B 실측으로 말한다(adr/0011·0012).

**전제(차별점 아님)**: 훅 강제, 플러그인 자기 테스트(`tests/`), ADR 기록, progressive disclosure — 생태계 상위권의 표준 장비다. 이걸 우위로 서술하지 않는다.

## 갱신
- 반기 1회(다음: 2027-02) 또는 차별점 항목이 상위 레포에 등장한 신호를 봤을 때. star 재실측 + "빌려 쓰는 것" 재점검.
- 갱신 이력: 2026-08-24 최초 작성(star 실측, 구조는 README 레벨).

# 0001. OpenSpec이 아티팩트 척추, Compound Engineering은 주변부
- 상태: 제안 (2026-08-21 재검증으로 전제·재검토 조건 개정)
- 날짜: 2026-08-21
- 검증: (없음 — 첫 프로젝트 Tier-2 change 3개 후 갱신)

## 맥락
SDD와 CE를 병행하려 했으나 플랜 생성·실행 자리가 겹친다. 재검증(`references/verdicts-2026-08-21.md` ①)으로 겹침의 정체를 정확히 했다:
- **`ce-plan`은 아티팩트가 겹친다.** `docs/plans/` unified plan(R/A/F/AE/U ID)은 OpenSpec change와 같은 질문에 답한다. `lfg`는 `docs/plans` 하드 의존.
- **`ce-work`는 루프만 겹친다.** 대신 `opsx:apply`에 없는 것을 갖는다: 유닛별 **증거 계약**(red 관찰·`verification_evidence`), **멱등성**(이미 된 유닛 재구현 금지), simplify 패스, 리뷰 꼬리. 현재 workflow.md는 이걸 산문으로 재구현한다.
- **`ce-code-review`는 OpenSpec 스펙을 못 읽는다.** `docs/plans/*` 또는 `## Requirements` R-ID만 찾으므로 Requirements Completeness 섹션이 조용히 빠진다. 나머지 기능은 정상.
- `ce-compound`는 plans 의존 0. brainstorm은 입력으로 충분.
- 둘을 같이 쓴 공개 필드 리포트는 없다. 유일하게 검증된 패턴은 "한 도구가 아티팩트 소유, 다른 도구는 schema `instruction`에서 호출"(OpenSpec × superpowers 브리지).
- 살아있는 스펙의 위험은 "안 읽힘"이 아니라 **"오래된 걸 믿음"**(Imoto: 에이전트는 현실 대신 스펙에 충실).

## 결정
- 스펙·tasks·아카이브 = **OpenSpec**. Tier-2 `feature` 스키마, Tier-3 `spec-driven`, Tier-1 없음.
- CE 호출: brainstorm / debug / code-review / simplify / compound / commit / commit-push-pr / babysit-pr.
- **`ce-plan`, `lfg`는 쓰지 않는다.**
- **`ce-code-review`는 반드시 스펙 경로와 힌트를 받는다**: `plan:openspec/changes/<slug>/specs/<cap>/spec.md` + "각 `### Requirement:`/`#### Scenario:`를 요구사항으로 취급해 Requirements Completeness를 작성하라". 없으면 스펙 대비 누락 검사가 영영 안 돈다.
- **`ce-work`는 실험 항목**(아래). 실험 전까지는 `opsx:apply`.
- develop-fe 스킬은 접착만. 재구현 금지 — 단, 현재 workflow.md가 ce-work의 증거 계약을 산문으로 재구현하고 있음을 인정하고 실험으로 해소한다.

## 실험 B (Tier-2 change 2개)
`feature` 스키마 `apply.instruction`을 "Skill 도구로 `compound-engineering:ce-work`를 `mode:return-to-caller <changeRoot>/tasks.md`로 호출, `specs/**/spec.md`를 요구사항 소스로 전달, 반환 envelope의 `u_ids_completed`/`verification_evidence`로 `tasks.md` 체크박스 반영. ce-work가 없으면 멈추고 보고"로 바꿔 본다. 알려진 마찰: ce-work는 legacy plan의 체크박스를 무시하고 안 찍는다(수동 반영 필수), 유닛 분할을 스스로 할 수 있다(tasks.md가 유닛 1개=task 1개여야), 브랜치 생성을 물을 수 있다. **증거 계약·멱등성이 `config.yaml` 가드레일보다 실제로 낫다고 확인될 때만** 채택.

## 전제
- 솔로~3인, 프론트엔드, Claude Code. CE 3.19 설치, 스킬명 유지.
- Tier-2 작업은 대부분 순차 → ce-work의 병렬 워커·크로스모델 엔진은 가치 없음.
- `openspec/specs/`가 **현실과 맞게 유지된다**(archive를 빠뜨리지 않음). 이게 살아있는 스펙의 유일한 조건.

## 재검토 조건
- **스펙이 테스트된 동작과 모순된 채 출하된 change 2개** → 스펙 유지 실패. CE-only(`ce-plan`/`ce-work`, 스펙 없음)로 전환. (이전 "20 change 동안 스펙을 안 읽음" 트리거는 잘못된 측정이라 폐기 — 에이전트는 읽는다)
- Tier-2에서 스펙 작성이 구현보다 오래 걸린 change 2개 → `feature` 스키마 축소.
- 실험 B 결과(채택/폐기)를 이 ADR에 추기.
- CI에 `openspec validate --archived`를 넣고, archive 누락을 머지 전 훅으로 막는다 — 이게 없으면 위 첫 조건이 조용히 충족된다.

## 결과 / 영향
- 플랜 위치 하나(`openspec/changes/`). `docs/plans/`는 brainstorm 산출물만.
- 리뷰 호출 시 인자 하나 더(스펙 경로). 잊으면 리뷰가 스펙-blind로 돈다 → `operations.archive.guidance`에 박는다.

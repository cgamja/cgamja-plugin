# 0002. Figma는 원천, 저장소의 `design/` 스냅샷이 작업 입력 — 새 화면·변경 때만 Figma 호출
- 상태: 제안
- 날짜: 2026-08-21
- 검증: (없음 — 첫 프로젝트 화면 3개 스냅샷 후 갱신)

## 맥락
디자인 원천이 Figma인데 단순 기능 개발마다 Figma MCP를 부르면 ① 화면당 2~3만 토큰(큰 프레임은 한도 초과 에러), ② Pro 한도 200회/일, ③ 같은 값을 매번 재추론(Code Connect 없이는 토큰 30% 추가)하는 비용이 붙는다. 실무 사례(savvy, figma-snapshot, sb-figma, figmascope, atomize)는 전부 "토큰은 1회 export, 화면은 저장소에 스냅샷, Figma는 새/변경 시에만"으로 수렴했다. `references/figma-design-source.md` §1~3.

## 결정
- `design/` 디렉토리(map.md, tokens.json→tokens.css, components.md, screens/<slug>/{summary.md, context.tsx, reference@2x.png})가 task의 입력이다.
- Figma MCP 호출은 ① `design/map.md`에 없는 새 노드, ② 디자인 변경(해당 섹션만 재스냅샷), ③ Ready 화면 최종 검증의 `get_screenshot` 1회, ④ 토큰 동기화(보고만)로 한정한다.
- 버그·리팩토링·상태 연결·"이 값이 뭐지"는 Figma를 부르지 않는다. 값이 스냅샷에 없으면 스냅샷을 한 번 채운다.
- 컴포넌트 매핑은 `components.md` + Figma 레이어 이름 규약(`ui /`, `local /`)으로 한다(Code Connect는 Org 전용).

## 전제
- Figma Pro 이상, Dev 또는 Full seat (`[TODO]` 확인). Starter면 오프라인 번들 export로 대체.
- 사용자가 Figma 파일에서 섹션 이름 규약(✅/🚧/💭/🧩)과 `📝 TODO:`/`⬜ PLACEHOLDER` 접두를 지킨다.
- 디자인 변경을 사용자가 말해주거나, summary.md의 캡처 날짜로 오래됨을 판단할 수 있다.

## 재검토 조건
- 스냅샷이 오래돼서 잘못 구현한 사례가 2번 → 세션 시작 시 `get_metadata` 1회로 변경 감지(비용 1회/세션)를 추가.
- Code Connect를 쓸 수 있는 플랜으로 바뀜 → `components.md`를 Code Connect로 대체.
- Figma가 MCP 출력 압축/캐시를 공식 제공 → 스냅샷 범위 축소.

## 결과 / 영향
- 프로젝트 시작 시 스냅샷 1회 비용(화면당 5~15회 호출). 이후 task는 Figma 의존 0.
- `git diff design/`이 디자인 변경 이력이 된다.

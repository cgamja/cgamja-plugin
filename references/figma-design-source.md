# Figma를 디자인 원천으로 쓰는 법 (리서치 2026-08-21)

디자인 원천은 프로젝트가 `.claude/cgamja.json` `design.source`로 선언한다(`figma:<fileKey>` 또는 `none`; 다른 원천이면 같은 원칙 — 원천은 진실, 저장소 스냅샷은 캐시). 아래는 Figma일 때. Figma 파일에 디자인이 있고, 일부는 미완성(와이어프레임 상태)으로 표시돼 있다. 에이전트는 ① 완성된 화면은 Figma대로 구현하고 ② 미완성 부분은 Artifact로 후보를 뽑아 사용자와 확정한 뒤 코드로 만들고 Figma에 거울로 남기며 ③ **단순 기능 개발에선 Figma를 부르지 않는다**. 결정은 `adr/0002`, `adr/0003`.

## 0. 먼저 알아야 할 플랜 게이트 ([rate limits](https://developers.figma.com/docs/figma-mcp-server/rate-limits-access/))
| 기능 | 조건 |
|---|---|
| 읽기 MCP(`get_design_context`/`get_metadata`/`get_variable_defs`/`get_screenshot`) | Starter **20회/월**(사실상 불가) · Pro 200회/일, 10회/분 · Org 200/일 · Enterprise 600/일 |
| 캔버스 쓰기(`use_figma`) Drafts 밖 | **Full seat** + 편집권. 베타 동안 무료, 이후 종량제 예고 |
| `generate_figma_design`(코드→평면 캡처) | 한도 면제. Drafts는 아무 seat, 기존 파일 편집은 Full |
| Code Connect(내 컴포넌트) | **Org/Enterprise만**. Pro는 Figma 공식 킷만 |
| Dev Mode annotation 작성, Ready-for-dev | 유료 플랜, annotation은 Full seat |
| Variables ↔ DTCG JSON 네이티브 export | 색·숫자만. 타이포/그림자 같은 composite는 Tokens Studio 또는 스크립트 |

`[TODO: 내 플랜/seat]` — Pro Full seat 기준으로 아래를 쓴다. Starter면 오프라인 export(figmascope, Figma-local-MCP)로 1회 번들을 뜨는 방식만 가능.

## 1. 비용 — 왜 매번 부르면 안 되는가
- `get_design_context` 화면 하나 ≈ 21k 토큰(섹션 단위). 전체 프레임은 351k 토큰으로 Claude Code 기본 한도(25k) 초과 에러가 Figma 문서에 실례로 있음 → `MAX_MCP_OUTPUT_TOKENS` 올리는 게 아니라 **노드를 작게** 자른다.
- Code Connect가 있으면 토큰 29.5%↓(Figma 자체 eval) — 없으면 에이전트가 매번 컴포넌트를 재추론한다. Org가 아니면 아래 "가난한 Code Connect"로 대체.
- 실무 수렴점([savvy](https://savvy.co.il/en/blog/wordpress-development/figma-mcp-production-workflow/), [figma-snapshot](https://github.com/pattern-stack/claudecode-patterns/blob/HEAD/plugin/skills/figma-snapshot/SKILL.md), [atomize](https://atomize.tools/blog/figma-design-tokens-vibe-coding/)): "Figma는 원천, 저장소의 스냅샷은 캐시. 어긋나면 Figma가 이기지만, 그때 노드를 다시 읽고 캐시를 갱신한다."

## 2. 저장소에 두는 것 (`design/`) — 프로젝트 시작 시 1회, 이후 변경분만
```
design/
  map.md                 get_metadata 트리(페이지/섹션/프레임 이름 + nodeId). 노드 찾기용 인덱스 — Figma 안 열고 ID를 안다
  tokens.json            Figma Variables → DTCG export. 리뷰되는 원천. Style Dictionary 등으로 → 프로젝트의 토큰 파일(`design.tokens`, 예: src/styles/tokens.css)
  components.md          Figma 컴포넌트 이름 → 코드 import 경로 (가난한 Code Connect)
  screens/<slug>/
    summary.md           섹션 구성, 사용 컴포넌트, 상태(빈/로딩/에러/hover), 브레이크포인트, 미완성 표시 목록, 출처 nodeId + 캡처 날짜
    context.tsx          get_design_context 출력 원본(섹션별로 이어붙임). 참고용이지 복사용 아님
    reference@2x.png     get_screenshot. 검증 기준 이미지
```
- 스크린샷·컨텍스트는 **섹션 단위**로 받는다(`get_metadata` → 섹션 nodeId → `get_design_context` 각각). 페이지 루트에 쏘지 않는다.
- 코드 컴포넌트 파일 상단에 `// figma: <nodeId>` 한 줄. Figma 레이어 이름은 `ui / Button`(저장소 컴포넌트 사용) · `local / Card`(페이지 전용) · `<aside>`(HTML 요소) 규약을 쓰면 Code Connect 없이도 출력이 리뷰 가능한 수준이 된다([zenn kshr](https://zenn.dev/kshr/articles/7665e5a9e24462?locale=en)).
- 재스냅샷은 덮어쓰기 → `git diff design/screens/<slug>/summary.md`가 "디자인에서 뭐가 바뀌었나"가 된다.

## 3. Figma 호출 규칙 (task마다 이 표로 판단)
| 상황 | Figma 호출 | 읽는 것 |
|---|---|---|
| 버그 수정, 리팩토링, 데이터/상태 연결, 이미 구현된 화면에 동작 추가 | **안 함** | `design/screens/<slug>/summary.md`, 토큰 파일(`design.tokens`) |
| "이 색/간격이 뭐지?" | **안 함** | 토큰 파일(`design.tokens`). 없으면 스냅샷 갭 → 한 번 채우고 끝, 매번 묻지 않는다 |
| 새 화면/새 컴포넌트 (`design/map.md`에 없음) | 함 — `get_metadata`(1) + 섹션별 `get_design_context`(n) + `get_screenshot`(1) | 스냅샷 생성 후 그걸로 작업 |
| 디자인이 바뀜(사용자가 말함 / summary가 오래됨) | 함 — 해당 섹션만 재스냅샷 | `git diff`로 바뀐 부분만 수정 |
| Ready 화면 최종 검증 | `get_screenshot` 1회(기준 PNG 갱신) | §6 |
| 디자인시스템 동기화 | `get_variable_defs` → `tokens.json`과 diff, **보고만** (자동 덮어쓰기 금지) | |
| 디자인이 아예 없는 부분 | **안 함** — §5 루프 | 토큰 파일(`design.tokens`), `components.md` |

예상 사용량: 새 화면 1개 5~15회, 검증 1회. Pro 200/일 안에서 여유.

## 4. 미완성 표시 규약 (Figma 파일 쪽, 사용자가 한다)
MCP로 읽히는 채널은 **노드 이름**(`get_metadata`의 name, `get_design_context`의 `data-name`), **annotation**(`data-annotations`, Full seat), **컴포넌트 description**. 댓글은 안 읽힌다. devStatus는 `use_figma` 읽기 스크립트로만.
- 섹션: `✅ Ready / 🚧 WIP / 💭 Explore / 🧩 Built-in-code`
- 프레임·그룹: `📝 TODO: <무엇이 비었나>` 접두. 빈 영역엔 회색 `⬜ PLACEHOLDER` 컴포넌트 인스턴스(트리에 이름이 남는다)
- 에이전트 규칙: 이름/annotation에 `TODO`·`WIP`·`PLACEHOLDER` 단어가 있으면(이모지 유무 무관) **그 부분은 구현하지 않고** §5로 보낸다. 멋대로 채우지 않는다.

## 5. 디자인 갭 루프 (미완성 부분) — `adr/0003`
1. **입력 수집**: 해당 노드 `get_design_context`(와이어프레임 구조·카피는 살린다) + `summary.md` + 토큰 파일(`design.tokens`) + `components.md` + 같은 플로우의 Ready 화면 `reference@2x.png`(톤 맞추기). `app-ref-to-figma`로 모은 레퍼런스 파일이 있으면 같은 기능의 타앱 화면 2~3장.
2. **후보 생성**: `design` 스킬(Claude Design 캔버스 Artifact)로 **2~3안**, 한 캔버스에 나란히. 제약: 토큰·기존 컴포넌트만, 와이어프레임의 정보 구조 유지, 각 안에 "무엇을 다르게 했나" 한 줄. 사용자는 캔버스에서 직접 고치고 저장한다.
3. **확정**: 사용자가 안을 고르거나 합친다. 결정을 `design/screens/<slug>/summary.md`의 "디자인 결정" 항목에 한 줄 기록(왜 그 안인지).
4. **코드 먼저 구현** (Tier-2 절차). 검증은 Artifact 확정본과 비교.
5. **Figma에 거울 남기기**: 실행 중인 화면을 `generate_figma_design`으로 `🧩 Built-in-code` 섹션에 평면 캡처. 프레임 이름에 `source: code · <날짜>`. **`use_figma`로 인스턴스 재조립은 하지 않는다** — 이미지 불가·폰트 업로드·베타 품질이라 비용 대비 가치 없음. 재사용 컴포넌트로 승격될 때만 사용자가 Figma에서 손으로 만든다.
6. 스냅샷 생성(§2). 이때부터 이 화면은 Ready와 동일하게 취급.

Full seat가 없으면 5단계는 건너뛰고 summary.md의 기록 + Artifact 링크로 대신한다.

## 6. Figma 대비 검증 — "스크린샷이 비슷해 보인다"는 증거가 아니다
순서대로, 위가 실패하면 아래 안 한다:
1. **토큰 린트**: 바뀐 파일에서 `var()` 밖의 `#hex`·`\d+px` grep → 0건. Figma 출력의 `leading-[22.126px]`류는 토큰으로 치환, 토큰이 없으면 **사용자에게 올린다**(하드코딩 금지). 소수점 line-height는 Figma 쪽 텍스트 스타일 문제 — 사용자에게 알림.
2. **computed style 대조**: 추측하기 쉬운 값 5~10개(gap·padding·radius·border 유무·아이콘 크기·font-weight)를 `getComputedStyle`로 Figma 노드값과 비교. 스크린샷은 레이아웃용, 값은 계산된 스타일로.
3. **픽셀/SSIM 비교 1회**: 2x로 캡처(Figma export와 동일 배율), `document.fonts.ready` 대기, 애니메이션 끄기, mock 데이터 고정, 텍스트 마스킹. **97~98% 이상 통과**, 98~99.5% 구간은 대개 폰트 렌더링 차이. EXPECTED/ACTUAL/DIFF 3장을 PR에 첨부(점수만 주면 에이전트가 합리화한다). 도구: `design-check-mcp`, `figma-pixel-kit`(pixelmatch+`--ignore-text`) 중 `[TODO: 택1]`.
4. **상태·브레이크포인트**: summary.md에 적힌 hover/focus/빈/에러 상태와 뷰포트마다 각각 확인. Figma 프레임이 정의하지 않은 상태는 3-3 코드 규칙(빈·로딩·에러 기본 포함)대로 만들고 summary에 "Figma에 없음"으로 기록.

무시할 것: 서브픽셀 안티앨리어싱, 1px 전역 오프셋, 스크롤바, 이미지 압축.

## 7. 출처
Figma MCP 공식: [rate limits](https://developers.figma.com/docs/figma-mcp-server/rate-limits-access/) · [write to canvas](https://developers.figma.com/docs/figma-mcp-server/write-to-canvas/) · [code to canvas](https://developers.figma.com/docs/figma-mcp-server/code-to-canvas/) · [known issues(토큰 초과 사례)](https://developers.figma.com/docs/figma-mcp-server/mcp-clients-issues/) · [Code Connect 이점](https://www.figma.com/blog/the-benefits-of-code-connect-in-mcp/) · [annotation in MCP](https://forum.figma.com/ask-the-community-7/mcp-support-for-annotations-53685) · [generate_figma_design 평면 레이어 한계](https://forum.figma.com/suggest-a-feature-11/figma-mcp-generate-figma-design-should-resolve-html-elements-to-existing-library-components-instead-of-raw-frames-51286)
실무: [savvy 프로덕션 워크플로우](https://savvy.co.il/en/blog/wordpress-development/figma-mcp-production-workflow/) · [figma-snapshot 스킬](https://github.com/pattern-stack/claudecode-patterns/blob/HEAD/plugin/skills/figma-snapshot/SKILL.md) · [canicode 토큰 측정](https://github.com/let-sunny/canicode/issues/117) · [computed-style 검증](https://dev.to/borisgri/even-with-the-figma-mcp-ai-eyeballs-your-design-and-ships-pixel-wrong-ui-5164) · [figma-pixel-kit](https://github.com/ozanzeng/figma-pixel-kit) · [레이어 이름 규약](https://zenn.dev/kshr/articles/7665e5a9e24462?locale=en) · [Claude Code --chrome 디자인 검증](https://code.claude.com/docs/en/chrome)

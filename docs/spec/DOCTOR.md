## Doctor — 버전·의존성 건강검진

스펙 문서(WEB-SPEC / APP-SPEC)의 버전이 썩지 않게 "진단 → 보고 → 승인 → 업데이트"를 돌리는 워크플로우. 하네스(Claude Code)에게 "doctor 돌려줘"라고 하면 이 문서를 따른다.

### 진단 명령

프레임워크별 doctor 명령:

| 프레임워크/라이브러리 | 명령어 | 주요 역할 |
| --- | --- | --- |
| Expo | `npx expo-doctor` | SDK 버전 호환성, native 설정 파일 오류 검사 |
| React (Web/공통) | `npx react-doctor@latest` | 안티 패턴, 성능 저하 코드, 구조적 결함 검사 (점수 산출) |
| Next.js | `npx next info` | 현재 로컬 개발 환경 및 설치된 의존성 패키지 상태 리포트 |
| React Native | `npx @react-native-community/cli doctor` | Android/iOS 개발 툴체인 및 환경 변수 세팅 검사 |

공통 명령 (스택 무관):

```bash
npm outdated                  # 현재 vs 최신 버전 표
npx npm-check-updates         # 업데이트 가능 목록 (적용은 -u 없이 확인만)
npm audit                     # 보안 취약점
```

Expo는 추가로:

```bash
npx expo install --check      # SDK가 기대하는 버전과 어긋난 패키지 검출
```

`react-doctor`는 성격이 다르다 — 버전이 아니라 **코드 안티패턴** 검사라서, 정기 doctor가 아니라 리뷰 시점에 변경분 대상으로 돌린다.

### 업데이트 규칙

1. **patch / minor**: 진단 보고 후 바로 올린다 — `npx expo install --fix` (앱) / `ncu -u --target minor` (웹) → 테스트 통과 확인
2. **major**: 자동으로 올리지 않는다 — changelog·breaking changes를 요약 보고하고 **사람이 승인하면** 별도 브랜치/PR로 진행
3. Expo는 개별 패키지를 직접 올리지 않고 **SDK 단위로** 업그레이드한다 (`npx expo install expo@latest` → `npx expo-doctor`)
4. Next.js 메이저는 공식 codemod 사용: `npx @next/codemod@latest upgrade`
5. 업데이트 후에는 반드시: lint → 타입체크 → 테스트 전체 → (UI 영향 시) 스크린샷 확인
6. 업데이트 커밋은 `chore(deps): ...`로 분리 — 기능 커밋에 섞지 않는다 ([COMMIT.md](./COMMIT.md) 원칙)

### 보고 형식

doctor 실행 결과는 아래 표로 보고한다:

| 패키지 | 현재 | 최신 | 구분 | 조치 |
| --- | --- | --- | --- | --- |
| next | 16.1.0 | 16.3.3 | minor | 바로 업데이트 |
| react | 19.2.0 | 19.2.7 | patch | 바로 업데이트 |
| tailwindcss | 3.4.x | 4.3.x | **major** | changelog 요약 후 승인 대기 |

### 실행 시점

- **라이브러리를 추가할 때** — 새 의존성이 package.json에 들어가는 시점에 해당 스택의 doctor 명령 + `npm audit`를 돌린다. AI(하네스)가 작업할 때는 이 시점을 hook으로 강제한다: `npm/pnpm/yarn install <pkg>` 계열 명령의 PostToolUse hook에서 doctor를 실행하고 결과를 보고 (각 프로젝트의 develop-setup에서 설치)
- `npm audit`에서 high/critical이 나오면 시점과 무관하게 즉시 보고
- 스펙 문서의 버전 표가 실제와 어긋나면 doctor가 문서도 함께 갱신한다

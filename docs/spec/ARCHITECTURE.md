## Architecture

### React-Bullet (bulletproof-react 기반)

> 기반: [bulletproof-react](https://github.com/alan2207/bulletproof-react). 토스 철학과의 연결 — feature 단위 구조는 **응집도**(함께 수정되는 파일을 같은 디렉토리에), 단방향 import는 **결합도**(수정 영향 범위 제한)를 강제하는 장치다.

### 폴더 구조

```
src/
├── app/          # 앱 진입점: 라우팅, 프로바이더, 전역 레이아웃
├── features/     # 도메인별 기능 모듈 (핵심)
│   └── <feature>/
│       ├── api/         # 이 기능의 서버 통신 (Tanstack Query 훅 포함)
│       ├── components/  # 이 기능 전용 컴포넌트
│       ├── hooks/       # 이 기능 전용 훅
│       ├── stores/      # 이 기능 전용 Zustand 스토어
│       ├── types/       # 이 기능 전용 타입
│       └── index.ts     # 공개 API — 외부는 여기로만 import
├── components/   # 도메인 무관 공용 UI (Button, Modal 등)
├── hooks/        # 공용 훅
├── lib/          # 외부 라이브러리 래퍼·설정 (axios, cn 등)
├── stores/       # 전역 상태 (정말 전역인 것만)
├── types/        # 공용 타입
└── utils/        # 공용 유틸
```

### Import 규칙 (단방향)

```
shared(components/hooks/lib/utils) → features → app
```

- **shared**는 누구나 import 가능. 단, shared는 features/app을 import할 수 없다
- **feature 간 직접 import 금지** — `features/comments`가 `features/discussions` 내부를 가져다 쓰지 않는다. 조합이 필요하면 `app` 레벨에서 한다
- feature 외부에서는 반드시 `features/<feature>/index.ts`(공개 API)로만 import — 내부 파일 직접 참조 금지
- 규칙은 말이 아니라 **ESLint(import 제한 룰)로 강제**한다

### 상태 위치 규칙

- 서버 상태: Tanstack Query (feature의 `api/`에 쿼리 훅으로)
- 클라이언트 상태: 컴포넌트 로컬 → feature 스토어 → 전역 스토어 순으로, **가장 좁은 범위**에 둔다
- 서버 상태를 Zustand에 복사하지 않는다 (상태 이중화 금지)

### `features/` 별 구조

- 처음에는 기본으로 하되, 코드가 길어지거나 해당 도메인에 맞는 아키텍쳐가 있으면 (ex. FSD) 해당 아키텍처로 변환
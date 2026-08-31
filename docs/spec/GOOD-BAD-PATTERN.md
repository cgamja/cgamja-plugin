## Good / Bad Code Pattern

> 출처: 토스 [Frontend Fundamentals](https://frontend-fundamentals.com/) — 각 패턴은 "변경하기 쉬운 코드" 4원칙(가독성·예측가능성·응집도·결합도) 중 하나에 대응한다.

### 1. 같이 실행되지 않는 코드는 분리한다 (가독성)

권한·상태별로 동시에 실행되지 않는 분기가 한 컴포넌트에 섞이면 동작을 한눈에 파악할 수 없다.

#### Bad
```tsx
function SubmitButton() {
  const isViewer = useRole() === "viewer";

  useEffect(() => {
    if (isViewer) return;
    showButtonAnimation();
  }, [isViewer]);

  return isViewer ? (
    <TextButton disabled>Submit</TextButton>
  ) : (
    <Button type="submit">Submit</Button>
  );
}
```

#### Good
```tsx
function SubmitButton() {
  const isViewer = useRole() === "viewer";
  return isViewer ? <ViewerSubmitButton /> : <AdminSubmitButton />;
}

function ViewerSubmitButton() {
  return <TextButton disabled>Submit</TextButton>;
}

function AdminSubmitButton() {
  useEffect(() => {
    showButtonAnimation();
  }, []);
  return <Button type="submit">Submit</Button>;
}
```

### 2. 숨은 로직을 드러낸다 (예측가능성)

함수 이름·시그니처에 드러나지 않는 부수효과(로깅 등)를 몰래 넣지 않는다. 부수효과는 호출부에서 명시적으로.

#### Bad
```ts
async function fetchBalance(): Promise<number> {
  const balance = await http.get<number>("...");
  logging.log("balance_fetched"); // 이름만 봐서는 알 수 없는 숨은 로직
  return balance;
}
```

#### Good
```tsx
async function fetchBalance(): Promise<number> {
  return http.get<number>("...");
}

<Button
  onClick={async () => {
    const balance = await fetchBalance();
    logging.log("balance_fetched"); // 호출 시점에 명시적으로
    await syncBalance(balance);
  }}
>
  계좌 잔액 갱신하기
</Button>
```

### 3. 매직 넘버·복잡한 조건에 이름을 붙인다 (가독성·응집도)

#### Bad
```ts
await delay(300);
if (product.categories.some((c) => c.id === targetCategory.id && product.price >= minPrice)) { ... }
```

#### Good
```ts
const ANIMATION_DELAY_MS = 300;
await delay(ANIMATION_DELAY_MS);

const isSameCategory = product.categories.some((c) => c.id === targetCategory.id);
const isPriceInRange = product.price >= minPrice;
if (isSameCategory && isPriceInRange) { ... }
```

### 4. Props Drilling을 지운다 (결합도)

중간 컴포넌트가 쓰지도 않는 props를 그대로 내려보내면, props 하나 바뀔 때 전체 트리가 수정된다. 조합(children) 패턴이나 Context로 푼다.

#### Bad
```tsx
function ItemEditModal({ open, items, recommendedItems, onConfirm, onClose }) {
  return (
    <Modal open={open} onClose={onClose}>
      {/* ItemEditBody는 items·recommendedItems·onConfirm을 쓰지 않고 전달만 한다 */}
      <ItemEditBody
        items={items}
        recommendedItems={recommendedItems}
        onConfirm={onConfirm}
        onClose={onClose}
      />
    </Modal>
  );
}
```

#### Good
```tsx
function ItemEditModal({ open, items, recommendedItems, onConfirm, onClose }) {
  const [keyword, setKeyword] = useState("");
  return (
    <Modal open={open} onClose={onClose}>
      <ItemEditBody keyword={keyword} onKeywordChange={setKeyword} onClose={onClose}>
        <ItemEditList
          keyword={keyword}
          items={items}
          recommendedItems={recommendedItems}
          onConfirm={onConfirm}
        />
      </ItemEditBody>
    </Modal>
  );
}
```

### 5. 같은 종류의 함수는 반환 타입을 통일한다 (예측가능성)

#### Bad
```ts
function checkIsNameValid(name: string): boolean { ... }
function checkIsAgeValid(age: number): { ok: true } | { ok: false; reason: string } { ... }
```

#### Good
```ts
type ValidationResult = { ok: true } | { ok: false; reason: string };

function checkIsNameValid(name: string): ValidationResult { ... }
function checkIsAgeValid(age: number): ValidationResult { ... }
```

### 6. 성급한 공통화보다 중복을 허용한다 (결합도)

여러 페이지가 비슷한 로직을 쓰더라도, **페이지마다 동작·로깅·UI가 달라질 여지가 있으면 공통 훅/컴포넌트로 묶지 않는다.** 공통화는 "모든 곳에서 동일하게 동작하고 앞으로도 함께 변경된다"는 확신이 있을 때만.

- 공통화 금지 신호: 페이지마다 로깅 값이 다를 수 있다 / 일부 페이지만 다른 동작이 필요하다 / UI·문구가 달라질 여지가 있다
- 공통화 허용 신호: 모든 곳에서 동일 동작, 변경 가능성 낮음, 팀 합의로 요구사항 일치 확인

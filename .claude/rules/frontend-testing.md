---
paths:
  - "src/main/frontend/**"
---

# Frontend Testing

Specs live in `src/main/frontend/src/test/`; run with `npm test`.

## Setup

Vitest with `globals: true` (no importing `describe`/`it`/`expect`) and the `jsdom` environment. `src/test/setup.ts` imports the matchers:

```typescript
import "@testing-library/jest-dom/vitest";
```

## Rendering

`@testing-library/react` for rendering and queries. Define `renderWithProviders()` **per test file** — don't hoist it into a shared module — wrapping the component in the providers it needs:

```typescript
function renderWithProviders(ui: React.ReactElement, initialRoute = "/") {
  return render(
    <ChakraProvider value={system}>
      <MemoryRouter initialEntries={[initialRoute]}>{ui}</MemoryRouter>
    </ChakraProvider>,
  );
}
```

## Mocking

Mock API modules at module level with a `vi.mock()` factory, reset in `beforeEach`, and configure return values through `vi.mocked()` for type safety:

```typescript
vi.mock("../api/categories", () => ({
  getCategories: vi.fn(),
}));

beforeEach(() => {
  vi.resetAllMocks();
  vi.mocked(categoriesApi.getCategories).mockResolvedValue(mockCategories);
});
```

## Organization

One `describe()` block per page or feature, named after it.

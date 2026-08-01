# Code Craft

## Build only what is needed

- Every method, class, or function you add must have a caller, or exist purely to make a call site readable. Nothing else.
- No future stubs: no empty methods, no placeholder functions, no interfaces "for future extensibility".
- No speculative abstractions: no factory, strategy, or adapter without an immediate second use.
- Delete exploration artifacts before finishing — helpers you wrote while working things out and no longer call.
- Don't add backward-compatibility code paths unless something actually depends on the old behavior.

## Comments

- Prefer structure and naming over commentary. Comment only where the logic isn't self-evident.
- Never write changelog comments (`// fixed NPE`, `// new in v2`, `// was: ...`). Comments are timeless explanations of the current code.
- Remove dead code rather than commenting it out.

## Errors

- Throw typed exceptions (`EntityNotFoundException`, `BusinessConflictException`), never bare `RuntimeException` for expected failures.
- Handle errors at the boundary — `GlobalExceptionHandler` — not with try/catch scattered through services.
- User-facing messages are actionable and leak nothing internal (no stack traces, SQL, or class names).

## Validation

- Server-side validation is mandatory; client-side checks are for feedback only and never a substitute.
- Validate at the entry point and reject early, before the value reaches a service or query.
- Field-specific messages — the response must tell the caller which field is wrong and why.
- Allowlists over blocklists for anything that reaches SQL, a file path, or a URL.

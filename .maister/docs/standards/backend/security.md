## Backend Security

### JWT Authentication Pattern

Use stateless JWT with `SecurityFilterChain` bean for URL-based authorization. No `@PreAuthorize` on controllers — keep authorization rules centralized in `SecurityConfiguration`.

### Error Responses for Auth Failures

Use custom `AuthenticationEntryPoint` (401) and `AccessDeniedHandler` (403) in `SecurityFilterChain` that write JSON `ErrorResponse` directly. These fire before the controller layer, so `GlobalExceptionHandler` cannot catch them.

### Password Storage

Use `BCryptPasswordEncoder` (Spring Security default). Store hashes in VARCHAR(72) columns.

### Token Claims

JWT must contain: `sub` (username), `permissions` (string array), `iat`, `exp`. Parse token once per request — avoid multiple parse/verify calls in the filter chain.

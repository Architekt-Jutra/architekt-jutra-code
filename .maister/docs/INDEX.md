# Documentation Index

**IMPORTANT**: Read this file at the beginning of any development task to understand available documentation and standards.

## Quick Reference

### Project Documentation
Project-level documentation covering architecture and technology choices for **aj** — a plugin-based microkernel platform built on Spring Boot.

### Technical Standards
Coding standards, conventions, and best practices organized by domain.

---

## Project Documentation

Located in `.maister/docs/project/`

### Tech Stack (`project/tech-stack.md`)
Java 25, Spring Boot 4.0.5 (WebMVC, JPA, JOOQ, Liquibase), PostgreSQL, Maven, TestContainers. Includes dependency versions, rationale for choices, and pending architectural decisions (JPA vs JOOQ, plugin framework selection).

### Architecture (`project/architecture.md`)
Microkernel (plugin-based) architecture pattern — currently in pre-alpha scaffolding phase. Documents application core structure, database layer (Liquibase + PostgreSQL), test infrastructure (TestContainers), target data flow, and planned package structure.

---

## Technical Standards

### Global Standards

Located in `.maister/docs/standards/global/`

#### Error Handling (`standards/global/error-handling.md`)
Clear user messages, fail-fast validation, typed exceptions, centralized handling, and graceful degradation.

#### Validation (`standards/global/validation.md`)
Server-side validation, client-side feedback, early input checking, specific error messages, and allowlists over blocklists.

#### Development Conventions (`standards/global/conventions.md`)
Predictable file structure, up-to-date documentation, clean version control, environment variables, and minimal dependencies.

#### Coding Style (`standards/global/coding-style.md`)
Naming consistency, automatic formatting, descriptive names, focused functions, and uniform indentation.

#### Commenting (`standards/global/commenting.md`)
Let code speak through structure and naming, comment sparingly for non-obvious logic, avoid change-log comments.

#### Minimal Implementation (`standards/global/minimal-implementation.md`)
Build only what is needed, clear purpose for every method, delete exploration artifacts, no future stubs or speculative abstractions.

### Backend Standards

Located in `.maister/docs/standards/backend/`

#### API Design (`standards/backend/api.md`)
RESTful principles, consistent naming, versioning, plural nouns for resources, and limited nesting.

#### JPA Entity Modeling (`standards/backend/models.md`)
Comprehensive JPA entity modeling standards: BaseEntity with @MappedSuperclass pattern (id, createdAt, @Version updatedAt), SEQUENCE primary key generation (allocationSize=1), EnumType.STRING for all enumerations, LAZY fetch default for all relationship types, Set-based collections, bidirectional relationship helper methods, orphanRemoval for owned collections, business key equals/hashCode (never entity id), @Embeddable value objects with equals/hashCode, specific cascade types (never CascadeType.ALL), cross-module references via type-safe ID wrappers (DDD bounded contexts), Lombok entity annotations (@Getter/@Setter/@NoArgsConstructor, no @Data/@EqualsAndHashCode), soft delete with @Where and deleted flag, collection type performance guide (Set vs List vs Map), and fetch type defaults per relationship.

#### Database Queries (`standards/backend/queries.md`)
Parameterized queries, N+1 avoidance with eager loading, select only needed columns, strategic indexing, and transactions.

#### jOOQ Query Standards (`standards/backend/jooq.md`)
jOOQ Professional Edition query standards: type-safe DSL usage, SQL injection prevention via bind variables, code generation, N+1 prevention with MULTISET, query optimization (EXISTS over COUNT, column projection, result mapping), common pitfalls from jOOQ docs (no DSL type implementation, no Step type references, no SELECT *, no DISTINCT for join fixes, no NOT IN with nullables, explicit ordering, UNION ALL preference, explicit joins), advanced features (CTEs, window functions, bulk operations, transactions, dynamic SQL), lightweight authorization query services (Db*QueryService pattern), and JPA integration guidelines (JPA for CRUD, jOOQ for complex reads).

#### Database Migrations (`standards/backend/migrations.md`)
Reversible migrations, small focused changes, zero-downtime awareness, separate schema and data migrations, and careful indexing.

#### Security (`standards/backend/security.md`)
JWT authentication pattern with centralized SecurityFilterChain authorization (no @PreAuthorize), custom AuthenticationEntryPoint/AccessDeniedHandler for JSON 401/403 responses, BCryptPasswordEncoder for password storage, and JWT token claims structure (sub, permissions, iat, exp).

#### Plugin Authentication (`standards/backend/plugin-auth.md`)
Browser SDK auth via hostApp.getToken() and postMessage, server-side auth with createServerSDK forwarding JWT from request headers, and permission checking in plugins by decoding JWT permissions claim.

### Frontend Standards

Located in `.maister/docs/standards/frontend/`

#### CSS (`standards/frontend/css.md`)
Consistent methodology (Tailwind/BEM/modules), work with the framework, design tokens, minimize custom CSS, and production optimization.

#### Components (`standards/frontend/components.md`)
Single responsibility, reusability with configurable props, composability, clear interfaces, and encapsulation.

#### Accessibility (`standards/frontend/accessibility.md`)
Semantic HTML, keyboard navigation, color contrast (4.5:1), alt text and labels, and screen reader testing.

#### Responsive Design (`standards/frontend/responsive.md`)
Mobile-first approach, standard breakpoints, fluid layouts, relative units (rem/em), and cross-device testing.

### Testing Standards

Located in `.maister/docs/standards/testing/`

#### Backend Testing (`standards/testing/backend-testing.md`)
Integration test infrastructure with TestContainers and real PostgreSQL 18, integration-first testing strategy (over unit tests), what NOT to test (auto-generated repos, Lombok getters/setters, private methods), test data isolation with @Transactional rollback, MockMvc with jsonPath()/Hamcrest for HTTP assertions, test class naming (*Tests suffix, package-private, same package as production), test method naming (action_condition_expectedResult pattern), private createAndSave*() helper methods with saveAndFlush(), integration vs validation test class split, test scope guidelines (2-8 tests per feature, CRUD plus edge cases), MockMvc security integration requiring SecurityMockMvcConfiguration import for Spring Boot 4/Security 7, custom security test annotations (@WithMockEditUser, @WithMockAdminUser), and Spring Security 7 PathPattern constraints (single-segment `*` vs multi-segment `**`).

#### Frontend Testing (`standards/testing/frontend-testing.md`)
Vitest with globals and jsdom environment, @testing-library/react for component rendering and queries, @testing-library/jest-dom for extended DOM matchers, per-file renderWithProviders() helper wrapping ChakraProvider and MemoryRouter, API module mocking with vi.mock() factory functions and vi.resetAllMocks() in beforeEach, vi.mocked() for type-safe mock configuration, describe blocks named after pages/features, and test files in src/test/ directory.

---

## How to Use This Documentation

1. **Start Here**: Always read this INDEX.md first to understand what documentation exists
2. **Project Context**: Read relevant project documentation before starting work
3. **Standards**: Reference appropriate standards when writing code
4. **Keep Updated**: Update documentation when making significant changes
5. **Customize**: Adapt all documentation to your project's specific needs

## Updating Documentation

- Project documentation should be updated when goals, tech stack, or architecture changes
- Technical standards should be updated when team conventions evolve
- Always update INDEX.md when adding, removing, or significantly changing documentation

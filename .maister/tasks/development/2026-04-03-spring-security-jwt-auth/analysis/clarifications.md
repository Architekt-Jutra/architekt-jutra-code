# Clarifications — Phase 1

## User Creation
- **Decision**: Admin-seeded only — users created via DB migration, no public registration endpoint
- Seed an admin user in Liquibase migration with all permissions

## Plugin Auth
- **Decision**: Full stack — update plugin SDK (sdk.ts, server-sdk.ts) to propagate JWT tokens in requests
- Both browser SDK and server SDK need Authorization header support

## Test Updates
- **Decision**: Update all 16 existing test files in this task to work with security enabled
- Add @WithMockUser or similar to existing integration tests + create new security-specific tests

## Frontend
- **Decision**: Include login UI — add a login page to the React SPA frontend
- Users will authenticate through the UI, token stored client-side

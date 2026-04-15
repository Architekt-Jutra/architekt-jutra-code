# Scope Clarifications — Phase 2

## Critical Decisions

### Role Model
- **Decision**: Independent permissions (join table)
- Each user gets arbitrary combination of READ, EDIT, PLUGIN_MANAGEMENT
- Requires user_permissions join table with user_id + permission enum

### Token Expiry
- **Decision**: 24h access token, no refresh token
- Simple re-login daily. Internal tool with admin-seeded users.

### Plugin Auth
- **Decision**: Inherit user JWT
- Plugin iframes and server SDK use the logged-in user's JWT token

## Important Decisions

### Password Seeding
- **Decision**: Pre-computed BCrypt hash in Liquibase migration YAML
- Matches existing sample data seeding pattern

### Frontend Auth State
- **Decision**: React Context (matches existing PluginContext pattern)

### UI Visibility
- **Decision**: Hide unauthorized elements based on JWT claims
- Frontend reads roles from JWT and conditionally renders UI elements

### Plugin Iframe Auth
- **Decision**: Inherit user JWT (plugins act as logged-in user)

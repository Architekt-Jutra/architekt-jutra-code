# Agent Instructions

You are responding to a production incident. See `instruction.md` for the alert.

## MCP tools available

- `aj-catalog` — entity lookups (services, datastores, teams, persons)
- `aj-metrics` — time-series metrics per service
- `aj-traces` — distributed traces and spans
- `aj-changes` — revisions, feature gates, and state mutations

## Rules

- Check ownership before modifying code — do not edit components owned by teams outside your authority.
- Follow existing architectural patterns in the codebase.

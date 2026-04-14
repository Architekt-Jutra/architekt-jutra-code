# Phase 1 Clarifications

## Tool Scope
- Start with skeleton infrastructure + product-related tools (listing and adding products)
- Other domain entities (categories, users) to be added later

## Spring Boot Version
- Use Spring Boot 4.0.5 to match the main aj project
- MCP SDK 0.16.0 compatibility with 4.x needs verification; may need newer SDK version

## Data Access Pattern
- Use Feign HTTP clients to call aj backend REST API (matches skillpanel-mcp pattern)
- Loosely coupled, separate process

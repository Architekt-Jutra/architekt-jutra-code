# Phase 2 Scope Clarifications

## Compatibility Decision
- Stay on Spring Boot 4.0.5 (match main app)
- Replace Spring Cloud OpenFeign with Spring's built-in RestClient + HttpServiceProxyFactory
- No Spring Cloud dependency needed — avoids compatibility risk entirely

## Scope Expansion
- Added aj_list_categories tool (required for add-product workflow)

## Configuration Decisions
- Tool prefix: aj_ (e.g., aj_list_products, aj_add_product, aj_list_categories)
- MCP server port: 8081
- JWT validation: NOT using shared HMAC secret (user did not select this option — will need to determine auth approach during specification)

## Final Tool List
1. aj_list_products — list products with filtering
2. aj_add_product — create a new product
3. aj_list_categories — list categories (needed for product creation)

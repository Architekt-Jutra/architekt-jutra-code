# aj — Microkernel Architecture Showcase

A showcase application demonstrating the **microkernel (plugin-based) architecture** pattern built with Java 25 and Spring Boot 4.

The core application acts as a lightweight host that manages plugin lifecycle, shared services (database, API routing), and cross-cutting concerns. Plugins are independently developed modules — each with its own frontend (Vite + TypeScript) — that extend the platform with domain-specific functionality.

## Project Structure

```
├── src/                        # Host application (Spring Boot)
│   └── main/java/pl/devstyle/aj/
│       ├── core/               # Microkernel core (base entity, plugin framework, error handling)
│       ├── api/                # REST controllers
│       ├── product/            # Domain: product management
│       └── category/           # Domain: categories
├── plugins/                    # Independent plugin modules
│   ├── warehouse/              # Warehouse management plugin (Vite + TS)
│   └── box-size/               # Box size calculator plugin (Vite + TS)
├── compose.yml                 # Docker Compose (PostgreSQL 18)
├── start-dev.sh                # Single script to run everything locally
└── .maister/                   # AI-assisted development artifacts
```

## Built with AI (Skillpanel / Maister Plugin)

This project was created using the **[Maister](https://github.com/SkillPanel/maister)** plugin for Claude Code — an AI SDLC framework that provides structured workflows for research, product design, and development.

All workflow artifacts are committed in `.maister/tasks/` so you can review the full AI-assisted development process:

- **`.maister/tasks/research/`** — Research phases
- **`.maister/tasks/product-design/`** — Product design sessions and briefs
- **`.maister/tasks/development/`** — Implementation task logs and work reports

The coding standards and conventions discovered/defined during the project live in `.maister/docs/`.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Java 25 |
| Framework | Spring Boot 4.0.5 (WebMVC, JPA, jOOQ, Liquibase) |
| Database | PostgreSQL 18 |
| Plugins | Vite + TypeScript (each plugin is a standalone frontend app) |
| Build | Maven (with wrapper) |
| Testing | JUnit 5, TestContainers (real PostgreSQL) |

## Running Locally

### Prerequisites

- Java 25+
- Docker (for PostgreSQL)
- Node.js (for plugins)

### Environment Setup

Some services require environment variables. Copy the example files and fill in your API keys:

```bash
cp litellm/.env.example litellm/.env
cp plugins/ai-description/.env.example plugins/ai-description/.env
```

Edit each `.env` file and replace placeholder values with your actual API keys. The service URLs (Langfuse, Presidio) are pre-configured for Docker and typically don't need changes.

### Quick Start

```bash
# Install plugin dependencies
(cd plugins/warehouse && npm install)
(cd plugins/box-size && npm install)

# Start everything (PostgreSQL + Spring Boot + all plugins)
./start-dev.sh
```

The `start-dev.sh` script will:
1. Start PostgreSQL via Docker Compose (or reuse if already running)
2. Start the Spring Boot host application
3. Start all plugins that have a `package.json`

Press `Ctrl+C` to stop everything.

### Manual Start

If you prefer to start services individually:

```bash
# 1. Start PostgreSQL
docker compose up -d

# 2. Start the host app
./mvnw spring-boot:run

# 3. Start a plugin (in a separate terminal)
cd plugins/warehouse && npm run dev
```

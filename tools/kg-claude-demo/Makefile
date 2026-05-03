# =============================================================================
# Knowledge Base demo — convenience targets
# =============================================================================
# Usage:
#   make up         # start Neo4j + load seed
#   make down       # stop Neo4j (keeps data)
#   make reset      # wipe Neo4j data and re-seed
#   make reseed     # re-run Cypher without wiping the volume
#   make opik-up    # clone (if needed) and start Opik
#   make opik-down  # stop Opik
#   make all-up     # Neo4j + Opik
#   make all-down   # stop everything
# =============================================================================

OPIK_DIR := .opik
COMPOSE  := docker compose

# ---- Neo4j -------------------------------------------------------------------

.PHONY: up
up:
	$(COMPOSE) up -d neo4j
	$(COMPOSE) up neo4j-seed
	@echo ""
	@echo "Neo4j browser:  http://localhost:7474"
	@echo "User / pass:    neo4j / aj-knowledge"
	@echo ""

.PHONY: down
down:
	$(COMPOSE) down

.PHONY: reset
reset:
	$(COMPOSE) down -v
	$(MAKE) up

.PHONY: reseed
reseed:
	$(COMPOSE) up neo4j-seed

# ---- Opik (cloned from upstream) --------------------------------------------

$(OPIK_DIR):
	@echo "Cloning Opik into $(OPIK_DIR) ..."
	git clone --depth 1 https://github.com/comet-ml/opik.git $(OPIK_DIR)

.PHONY: opik-up
opik-up: $(OPIK_DIR)
	cd $(OPIK_DIR) && ./opik.sh
	@echo ""
	@echo "Opik UI:    http://localhost:5173"
	@echo "Opik API:   http://localhost:5173/api  (use this in 'opik configure')"
	@echo ""
	@echo "Next: install the plugin from inside Claude:"
	@echo "  /plugin marketplace add comet-ml/opik-claude-code-plugin"
	@echo "  /plugin install opik"
	@echo "  /opik:trace-claude-code start"
	@echo ""

.PHONY: opik-down
opik-down:
	@if [ -d "$(OPIK_DIR)" ]; then cd $(OPIK_DIR) && ./opik.sh --stop; fi

.PHONY: opik-clean
opik-clean:
	@if [ -d "$(OPIK_DIR)" ]; then cd $(OPIK_DIR) && ./opik.sh --clean; fi

.PHONY: opik-verify
opik-verify:
	@curl -sS -o /dev/null -w "Opik UI:   HTTP %{http_code}\n" http://localhost:5173/ || true
	@curl -sS -o /dev/null -w "Opik API:  HTTP %{http_code}\n" http://localhost:5173/api/v1/private/projects || true

# ---- Combined ---------------------------------------------------------------

.PHONY: all-up
all-up: up opik-up

.PHONY: all-down
all-down: down opik-down

# ---- Status helpers ---------------------------------------------------------

.PHONY: status
status:
	@echo "=== Neo4j ==="
	@$(COMPOSE) ps
	@echo ""
	@echo "=== Opik ==="
	@if [ -d "$(OPIK_DIR)" ]; then cd $(OPIK_DIR) && docker compose ps; else echo "(not installed)"; fi

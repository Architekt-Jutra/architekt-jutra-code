#!/usr/bin/env bash
# Binary hard gate — did the agent mitigate the root cause?
#
# Accepts any of three valid fix trajectories (spec §2.4):
#   1. Feature gate warehouse-full-inventory-sync is now 'off'
#   2. Code in warehouse/ or host-app/ guards the sync loop (circuit-breaker,
#      rate-limit, feature-flag check, or outright disable)
#   3. A dedicated connection pool / read replica is configured for ai-description
#
# Rejects false-lead fixes implicitly — none of the three checks match
# LiteLLM config changes, cache refactors, or model swaps.

set -u  # fail on unset, but NOT on command errors — we want to control exit

STATE_FILE="/tmp/mcp-state/feature_gates.json"
WORKSPACE="${WORKSPACE_DIR:-/app}"
REWARD_FILE="/logs/verifier/reward.txt"

# Ensure the reward directory exists (Harbor mounts /logs/verifier/ but be defensive)
mkdir -p "$(dirname "$REWARD_FILE")"

check_gate_off() {
    [ -f "$STATE_FILE" ] \
        && jq -e '.["warehouse-full-inventory-sync"] == "off"' "$STATE_FILE" >/dev/null 2>&1
}

check_code_mitigation() {
    # Search in warehouse plugin + host-app sources for mitigation patterns.
    # Matches if any file mentions inventory sync AND one of: disabled, rate-limit,
    # circuit-breaker, feature-gate conditional.
    grep -rlE "(inventory.sync|warehouse.sync|full.inventory)" \
        "$WORKSPACE/plugins/warehouse" "$WORKSPACE/src" 2>/dev/null \
        | while read -r f; do
            if grep -iqE "(disabled|rate.?limit|circuit.?breaker|@ConditionalOn|enabled.*false|if.*feature.?gate)" "$f"; then
                echo "$f"
                exit 0
            fi
          done | grep -q .
}

check_dedicated_pool() {
    grep -rlE "(dedicated.pool|read.replica|ai[._-]description.*dataSource|secondaryDataSource|@Qualifier.*ai)" \
        "$WORKSPACE/plugins/ai-description" "$WORKSPACE/src" 2>/dev/null \
        | grep -q .
}

if check_gate_off; then
    echo "PASS: feature gate warehouse-full-inventory-sync is off"
    echo 1 > "$REWARD_FILE"
    exit 0
fi

if check_code_mitigation; then
    echo "PASS: code-level mitigation detected in warehouse/host-app"
    echo 1 > "$REWARD_FILE"
    exit 0
fi

if check_dedicated_pool; then
    echo "PASS: dedicated pool or read replica detected for ai-description"
    echo 1 > "$REWARD_FILE"
    exit 0
fi

echo "FAIL: no accepted mitigation found"
echo "  - warehouse-full-inventory-sync gate state: $(jq -r '."warehouse-full-inventory-sync" // "unknown"' "$STATE_FILE" 2>/dev/null || echo 'state file missing')"
echo "  - no code patterns matched in plugins/warehouse, plugins/ai-description, or src/"
echo 0 > "$REWARD_FILE"
exit 1

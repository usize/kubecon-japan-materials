#!/usr/bin/env bash
# ============================================================================
# Stage 3: The Happy Path
# Sets up Keycloak auth, shows the UI URL, and guides the presenter through
# a live financial query. Shows MLflow observability scoping.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

set -x

banner "Stage 3: The Happy Path"

# ── Keycloak setup ──────────────────────────────────────────────────────────
commentary "Configuring Keycloak: creating the audience scope, ROPC client,
and test user so inbound authentication passes end-to-end."

# Run the Keycloak setup script directly (uv --no-project avoids needing
# a [project] table in kagenti-extensions/pyproject.toml).
kubectl -n keycloak port-forward svc/keycloak-service 18081:8080 >/tmp/finance-kc-setup-pf.log 2>&1 &
KC_PF_PID=$!
sleep 4
NAMESPACE="$NAMESPACE" AGENT_SA=finance-agent KEYCLOAK_URL=http://localhost:18081 \
  uv run --no-project --with python-keycloak \
  python "$SPARC_DEMO_DIR/scripts/setup_keycloak_finance.py"
kill $KC_PF_PID 2>/dev/null || true

# ── Guide the presenter ────────────────────────────────────────────────────
commentary "The full query flow:
  1. User types in the kagenti UI
  2. UI sends an A2A POST to the finance-agent
  3. AuthBridge validates the inbound JWT
  4. Agent reasons about the query and calls tools via MCP
  5. AuthBridge exchanges the token for the tool's audience
  6. MCP Gateway routes to the correct backend
  7. Response flows back through the same chain"

echo ""
echo -e "${BOLD}  UI URL: ${CYAN}http://kagenti-ui.localtest.me:8080${NC}"
echo ""

pause "Open the UI and ask: \"What is AAPL's PE ratio?\""

# ── MLflow observability ────────────────────────────────────────────────────
commentary "MLflow traces are scoped per-agent via Kubernetes RBAC.
Each agent's service account gets a Role that restricts MLflow
experiment access to its own namespace prefix."

kubectl get role -n "$NAMESPACE" -l app.kubernetes.io/part-of=kagenti 2>/dev/null | head -10 || \
  commentary "(No kagenti MLflow roles found — MLflow may not be fully configured yet)"

pause "Stage 3 complete"

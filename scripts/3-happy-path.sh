#!/usr/bin/env bash
# ============================================================================
# Stage 3: The Happy Path
# Shows the UI URL and guides the presenter through a live financial query.
# Keycloak setup was done in Stage 2.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

set -x

banner "Stage 3: The Happy Path"

# ── Guide the presenter ────────────────────────────────────────────────────
commentary "The full query flow:
  1. User types in the kagenti UI
  2. UI sends an A2A POST to the finance-agent
  3. AuthBridge validates the inbound JWT
  4. Agent reasons about the query and calls tools via MCP
  5. AuthBridge exchanges the token for the mcp-gateway audience
  6. MCP Gateway validates the audience and routes to the correct backend
  7. Response flows back through the same chain"

echo ""
echo -e "${BOLD}  UI URL: ${CYAN}http://kagenti-ui.localtest.me:8080${NC}"
echo ""
bash "$SCRIPT_DIR/show-creds.sh"

pause "Open the UI and ask: \"What is AAPL's PE ratio?\""

# ── MLflow observability ────────────────────────────────────────────────────
commentary "MLflow traces are scoped per-agent via Kubernetes RBAC.
Each agent's service account gets a Role that restricts MLflow
experiment access to its own namespace prefix."

kubectl get role -n "$NAMESPACE" -l app.kubernetes.io/part-of=kagenti 2>/dev/null | head -10 || \
  commentary "(No kagenti MLflow roles found yet)"

pause "Stage 3 complete"

#!/usr/bin/env bash
# ============================================================================
# Stage 4a: Argument Grounding (SPARC)
# Shows the "failure first" pattern: an agent hallucinating a transaction ID,
# then enabling the SPARC guardrail via ConfigMap hot-reload to catch it.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

SPARC_DEPLOY="$EXTENSIONS_ROOT/AuthBridge/sparc-service/deploy"
SPARC_IMAGE="sparc-service:latest"
SPARC_TIMEOUT_MS="${SPARC_TIMEOUT_MS:-200000}"
KIND_NODE="${CLUSTER_NAME}-control-plane"

# LLM provider for SPARC reflection. Defaults to ollama (no creds needed).
# Set PROVIDER=watsonx and export WX_API_KEY/WX_PROJECT_ID for watsonx.
PROVIDER="${PROVIDER:-ollama}"
SPARC_MODEL="${SPARC_MODEL:-gemma4:e4b}"

set -x

banner "Stage 4a: Argument Grounding"

commentary "Pattern: the SPARC reflection service inspects tool-call arguments
BEFORE they reach the tool. If an argument is hallucinated (not grounded
in the conversation), SPARC blocks the call and tells the agent to ask
the user for the real value."

# ── Show current pipeline (no guardrails) ───────────────────────────────────
commentary "Current authbridge pipeline — default passthrough, no guardrails:"
kubectl -n "$NAMESPACE" get cm authbridge-config-finance-agent -o yaml 2>/dev/null | \
  head -30 || commentary "(ConfigMap not found — deploy the agent first via Stage 2)"

pause "The pipeline has no argument checking — the agent can pass any value to tools"

# ── GUARDRAILS OFF: drive the scenario ──────────────────────────────────────
commentary "GUARDRAILS OFF — asking the agent to process a refund.
The agent will fabricate a transaction ID because the user never provided one."

echo ""
echo -e "${BOLD}  In the UI, ask: ${CYAN}\"Process a refund for my last transaction\"${NC}"
echo ""
echo -e "${YELLOW}  The agent will call the refund tool with a hallucinated transaction ID${NC}"
echo -e "${YELLOW}  like 'TX4827' — a value it invented, not one the user provided.${NC}"
echo ""

pause "The agent fabricated a transaction ID — this is the problem we're solving"

# ── Build + deploy SPARC service ────────────────────────────────────────────
commentary "ENABLING the grounding check — deploying the SPARC reflection service
and hot-patching the sidecar pipeline via ConfigMap.
No pod restart needed — the sidecar detects the ConfigMap change and rebuilds."

# Build + load the SPARC service image if not already present
if ! "$CONTAINER_RUNTIME" exec "$KIND_NODE" ctr -n k8s.io images list -q 2>/dev/null | grep -q "$SPARC_IMAGE"; then
  commentary "Building SPARC service image..."
  "$CONTAINER_RUNTIME" build -t "$SPARC_IMAGE" "$EXTENSIONS_ROOT/AuthBridge/sparc-service"
  kind load docker-image "$SPARC_IMAGE" --name "$CLUSTER_NAME"
fi

# Deploy the SPARC service via the shared installer
make -C "$SPARC_DEPLOY" install \
  NAMESPACE="$PLATFORM_NS" IMAGE="$SPARC_IMAGE" PROVIDER="$PROVIDER" \
  MODEL="$SPARC_MODEL" TRACK=fast_track \
  OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://host.docker.internal:11434}" \
  KIND_CLUSTER_NAME="$CLUSTER_NAME"

# ── Patch the agent's authbridge pipeline ──────────────────────────────────
commentary "Adding SPARC + parsers to the agent's authbridge pipeline..."

# The patch script adds mcp-parser, inference-parser, and sparc plugins.
# It verifies by checking the authbridge reload SHA — tolerate timeout since
# kubelet ConfigMap sync can take up to 90s and the sidecar filesystem watcher
# adds another debounce window.
SPARC_TIMEOUT_MS="$SPARC_TIMEOUT_MS" \
  bash "$SPARC_DEMO_DIR/scripts/patch-sparc-config.sh" "$NAMESPACE" finance-agent || \
  commentary "SHA verification timed out — the ConfigMap is patched, the sidecar will reload shortly."

pause "Grounding check is live — no pod restart, agent doesn't know it's there"

# ── GUARDRAILS ON: replay the scenario ──────────────────────────────────────
commentary "GUARDRAILS ON — replaying the same refund scenario.
This time SPARC intercepts the tool call and checks whether 'TX4827'
appeared in the conversation. It didn't — so SPARC blocks the call."

echo ""
echo -e "${BOLD}  In the UI, start a new conversation and ask the same question:${NC}"
echo -e "${CYAN}  \"Process a refund for my last transaction\"${NC}"
echo ""
echo -e "${YELLOW}  Watch the agent response — SPARC will reject the hallucinated ID${NC}"
echo -e "${YELLOW}  and the agent will ask the user for the real transaction ID.${NC}"
echo ""

pause "Caught the hallucinated argument — the agent now asks for the real value"

# ── Show forensic results ──────────────────────────────────────────────────
commentary "Launching the pipeline forensic TUI to inspect SPARC's verdicts..."
make -C "$SPARC_DEMO_DIR" show-result || \
  commentary "(abctl not available — run 'make -C $SPARC_DEMO_DIR build-abctl' first)"

pause "Stage 4a complete"

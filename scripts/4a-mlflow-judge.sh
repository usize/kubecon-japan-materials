#!/usr/bin/env bash
# ============================================================================
# Stage 4a: MLflow Observability & Custom Judge
# Deploys the finance-news-agent with OTEL/MLflow tracing, runs the prompt
# injection scenario (no guardrails), then uses a custom MLflow judge to
# detect the injection post-hoc.  Sets up the narrative arc for Stage 4b
# (IBAC), which blocks the same attack in real-time.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

set -x

banner "Stage 4a: MLflow Observability & Custom Judge"

commentary "Pattern: before adding runtime guardrails, establish observability.
The agent's OTEL env vars route traces to a named MLflow experiment.
After an incident, a custom LLM judge evaluates traces post-hoc —
detecting prompt injection after the fact."

# ── Build + deploy the finance-news-agent ─────────────────────────────────
commentary "Building and deploying the financial news agent with OTEL/MLflow
tracing enabled. The agent.yaml includes OTEL_EXPORTER_OTLP_ENDPOINT,
OTEL_SERVICE_NAME, OTEL_RESOURCE_ATTRIBUTES, and MLFLOW_EXPERIMENT_NAME.
Traces will appear in the 'team1' MLflow experiment."

make -C "$IBAC_DEMO_DIR" build-images load-images deploy wait-pods \
  CONTAINER_RUNTIME="$CONTAINER_RUNTIME"

pause "Financial news agent deployed with MLflow tracing"

# ── Show OTEL/MLflow configuration ───────────────────────────────────────
commentary "Verifying the OTEL/MLflow env vars on the agent deployment:"

kubectl -n "$NAMESPACE" get deploy finance-news-agent \
  -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}' \
  | grep -E "^(OTEL_|MLFLOW_)"

echo ""
echo -e "${YELLOW}  These env vars route agent traces to the OTEL collector,${NC}"
echo -e "${YELLOW}  which forwards them to MLflow under the 'team1' experiment.${NC}"
echo ""

pause "OTEL/MLflow configuration confirmed"

# ── Run the injection scenario (no guardrails) ───────────────────────────
commentary "NO GUARDRAILS — the agent has the default sidecar pipeline
(jwt-validation inbound, token-exchange outbound). No intent verification.
A poisoned news article will trick the agent into exfiltrating data."

echo ""
echo -e "${BOLD}  In the UI, select finance-news-agent and ask:${NC}"
echo -e "${CYAN}  \"What's the latest news about AAPL?\"${NC}"
echo ""
echo -e "${YELLOW}  The poisoned news article instructs the agent to POST data to tainted-server.${NC}"
echo -e "${YELLOW}  Without guardrails, the agent complies — exfiltration succeeds.${NC}"
echo ""

pause "Now check the tainted-server logs to confirm exfiltration succeeded"

# ── Confirm exfiltration ─────────────────────────────────────────────────
commentary "Tainted-server received the exfiltrated portfolio data:"
kubectl -n "$NAMESPACE" logs deploy/ibac-tainted-server --tail=20

pause "Exfiltration succeeded — the agent followed the injected instructions"

# ── Show MLflow traces ───────────────────────────────────────────────────
commentary "The agent's trace was recorded in MLflow. Open the MLflow UI
to inspect the full trace — LLM reasoning, tool calls, and the
exfiltration POST are all visible."

echo ""
echo -e "${BOLD}  Open MLflow UI:${NC}"
echo -e "${CYAN}  http://mlflow.localtest.me:8080${NC}"
echo ""
echo -e "${YELLOW}  Navigate to the 'team1' experiment.${NC}"
echo -e "${YELLOW}  Open the latest trace — you'll see the agent's tool calls${NC}"
echo -e "${YELLOW}  including the POST to tainted-server.${NC}"
echo ""

pause "MLflow trace shows the full attack chain"

# ── Run custom judge ─────────────────────────────────────────────────────
commentary "Now we run a custom MLflow judge to evaluate the trace.
The judge uses mlflow.genai.judges.make_judge() with a prompt-injection
detection prompt. It runs against local Ollama (llama3.2:3b)."

commentary "Port-forwarding MLflow tracking server..."
kubectl -n "$PLATFORM_NS" port-forward svc/mlflow 5000:5000 &
PF_PID=$!
sleep 2

commentary "Acquiring Keycloak token for MLflow API access..."
OIDC_SECRET=$(kubectl get secret -n "$PLATFORM_NS" mlflow-oauth-secret \
  -o jsonpath='{.data.OIDC_CLIENT_SECRET}' | base64 -d)
APP_PASS=$(kubectl get secret -n keycloak kagenti-test-user \
  -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)
MLFLOW_TOKEN=$(curl -s -X POST \
  "http://keycloak.localtest.me:8080/realms/kagenti/protocol/openid-connect/token" \
  -d "grant_type=password&client_id=mlflow&client_secret=${OIDC_SECRET}&username=admin&password=${APP_PASS}&scope=openid" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

commentary "Running the custom judge against the latest trace..."

MLFLOW_TRACKING_URI="http://localhost:5000" \
MLFLOW_TRACKING_TOKEN="$MLFLOW_TOKEN" \
OPENAI_BASE_URL="http://localhost:11434/v1" \
OPENAI_API_KEY="unused" \
  uv run --no-project --with mlflow --with openai \
  "$SCRIPT_DIR/mlflow-judge/run_judge.py"

# Clean up port-forward
kill "$PF_PID" 2>/dev/null || true

pause "Custom judge detected the injection — post-hoc analysis works"

# ── Transition to 4b ─────────────────────────────────────────────────────
commentary "Post-hoc detection confirms the injection happened.
But detection after the fact isn't prevention.

Next: Stage 4b adds the IBAC sidecar plugin to block
the same attack IN REAL-TIME — same LLM judge concept,
but enforced at the infrastructure layer before the
request leaves the pod."

pause "Stage 4a complete — ready for Stage 4b"

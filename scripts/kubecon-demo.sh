#!/usr/bin/env bash
# ============================================================================
# KubeCon Japan 2026 — Live Demo Script
#
# "Securing Agentic AI at the Infrastructure Layer"
#
# Prerequisites:
#   - Kagenti platform installed on a Kind cluster (setup-kagenti.sh)
#   - Ollama running on host with llama3.2:3b pulled
#   - Images pushed to quay.io/rh-ee-mofoster/
#
# Usage: ./scripts/kubecon-demo.sh
#   Press Enter to advance through each phase.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../env.sh"
source "$SCRIPT_DIR/lib.sh"

QUAY_REPO="quay.io/rh-ee-mofoster"
SPARC_FINANCE_MCP="$SPARC_DEMO_DIR/k8s/finance-mcp.yaml"

set -x

# ╔══════════════════════════════════════════════════════════════════════════╗
# ║                                                                          ║
# ║   KUBECON JAPAN 2026 — SECURING AGENTIC AI AT THE INFRASTRUCTURE LAYER   ║
# ║                                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

banner "Pre-Flight Check"

commentary "Verifying cluster, namespaces, and Ollama..."

kubectl cluster-info | head -1
kubectl get ns kagenti-system mcp-system team1 --no-headers
ollama list 2>/dev/null | grep llama3.2 || commentary "WARNING: llama3.2:3b not found in ollama"

commentary "
  ✓ Kagenti platform is running
  ✓ MCP Gateway is deployed
  ✓ SPIFFE/SPIRE is issuing identities
  ✓ Ollama is serving the judge model

  We have a Kubernetes cluster with the full kagenti stack:
  operator, SPIRE, Keycloak, MCP Gateway, and the agent UI.

  Now let's show four infrastructure patterns for securing
  agentic AI — using a financial use case as the through-line."

pause "Ready to begin"

# ════════════════════════════════════════════════════════════════════════════
#
#   ACT 1 — THE FRONT DOOR
#   Tool Aggregation via MCP Gateway
#
# ════════════════════════════════════════════════════════════════════════════

banner "Act 1: Tool Aggregation via MCP Gateway"

commentary "
  PATTERN: When agents need access to multiple tool servers,
  a protocol-aware gateway federates them behind a single endpoint.

  We have two MCP tool servers:
    • finance-tool  — market data (stock prices, fundamentals, news)
    • finance-mcp   — transactions (refunds, invoices, customers)

  Each registers with the MCP Gateway using a Kubernetes CRD.
  The agent connects to ONE endpoint and discovers ALL tools."

# ── Deploy tool backends ─────────────────────────────────────────────────

commentary "Deploying both tool backends..."
kubectl apply -f "$SPARC_FINANCE_MCP"
kubectl apply -f "$DEMO_DIR/k8s/finance-tool-deployment.yaml"
kubectl -n "$NAMESPACE" rollout status deploy/finance-mcp --timeout=120s
kubectl -n "$NAMESPACE" rollout status deploy/finance-tool --timeout=120s

commentary "Registering both with the MCP Gateway..."
kubectl apply \
  -f "$DEMO_DIR/k8s/finance-mcp-httproute.yaml" \
  -f "$DEMO_DIR/k8s/finance-mcp-registration.yaml" \
  -f "$DEMO_DIR/k8s/finance-tool-httproute.yaml" \
  -f "$DEMO_DIR/k8s/finance-tool-registration.yaml"

kubectl -n mcp-system rollout restart deploy/mcp-gateway deploy/mcp-gateway-controller
kubectl -n mcp-system rollout status deploy/mcp-gateway --timeout=60s
kubectl -n mcp-system rollout status deploy/mcp-gateway-controller --timeout=60s

commentary "Waiting for registrations to go Ready..."
for reg in finance-mcp-servers finance-tool-servers; do
  for i in $(seq 1 60); do
    if kubectl get mcpserverregistrations -n "$NAMESPACE" "$reg" \
         -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True; then
      break
    fi
    sleep 3
  done
done

pause "Tool backends deployed"

# ── Show the unified catalog ─────────────────────────────────────────────

commentary "Two backends, one gateway, unified tool catalog:"
echo ""
kubectl get mcpserverregistrations -n "$NAMESPACE"
echo ""

commentary "
  finance-mcp-servers:  5 transaction tools (prefix: txn_)
  finance-tool-servers: 4 market data tools (prefix: market_)

  The agent connects to a single MCP endpoint and discovers
  all 9 tools. The gateway handles routing — the agent never
  knows there are two separate backends."

pause "Act 1 complete — tool aggregation demonstrated"

# ════════════════════════════════════════════════════════════════════════════
#
#   ACT 2 — WHO ARE YOU?
#   Workload Identity + Zero-Trust Access
#
# ════════════════════════════════════════════════════════════════════════════

banner "Act 2: Workload Identity (SPIFFE/SPIRE)"

commentary "
  PATTERN: Agent pods get cryptographic workload identity via
  SPIFFE/SPIRE — not API keys, not shared secrets. A sidecar
  proxy handles JWT validation inbound and token exchange outbound.
  No agent code changes required."

# ── Deploy the agent ─────────────────────────────────────────────────────

commentary "Deploying the financial news agent..."
kubectl apply \
  -f "$DEMO_DIR/finance-ibac/k8s/news-server.yaml" \
  -f "$DEMO_DIR/finance-ibac/k8s/evil-server.yaml" \
  -f "$DEMO_DIR/finance-ibac/k8s/agent.yaml"

commentary "Waiting for operator to inject sidecar and issue identity..."
for i in $(seq 1 60); do
  if kubectl -n "$NAMESPACE" get configmap authbridge-config-finance-news-agent >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl -n "$NAMESPACE" rollout status deploy/finance-news-agent --timeout=120s
kubectl -n "$NAMESPACE" rollout status deploy/ibac-news-server --timeout=60s
kubectl -n "$NAMESPACE" rollout status deploy/ibac-evil-server --timeout=60s

pause "Agent deployed with sidecar"

# ── Show the SPIFFE identity ─────────────────────────────────────────────

commentary "The agent's pod automatically received a cryptographic identity:"
echo ""
echo -e "  ${BOLD}SPIFFE ID:${NC}"
SPIFFE_ID=$(kubectl -n "$NAMESPACE" exec deploy/finance-news-agent -c authbridge-proxy \
  -- cat /shared/client-id.txt 2>/dev/null)
echo -e "  ${CYAN}$SPIFFE_ID${NC}"
echo ""

commentary "
  This identity was issued by SPIRE — no code changes to the agent.
  The sidecar validates inbound JWTs and exchanges tokens outbound.
  The agent binary has zero awareness of any of this."

pause "Identity shown"

# ── Untrusted pod contrast ───────────────────────────────────────────────

commentary "Now let's show what happens WITHOUT identity.
  Deploying an untrusted curl pod — same namespace, no sidecar:"

kubectl apply -f "$DEMO_DIR/k8s/untrusted-pod.yaml"
kubectl -n "$NAMESPACE" wait --for=condition=Ready pod/untrusted-curl --timeout=30s

echo ""
echo -e "${BOLD}  Untrusted pod tries to reach the agent:${NC}"
echo ""
RESULT=$(kubectl -n "$NAMESPACE" exec untrusted-curl -- \
  curl -s -X POST http://finance-news-agent.${NAMESPACE}.svc.cluster.local:8080/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"1","method":"message/send","params":{"message":{"role":"user","parts":[{"kind":"text","text":"hello"}]}}}' \
  2>&1)
echo -e "  ${RED}$RESULT${NC}"
echo ""

commentary "
  Rejected: auth.unauthorized — missing Authorization header.

  Same cluster. Same namespace. But without workload identity,
  you don't get in. The sidecar enforces this transparently —
  no API keys, no shared secrets, just cryptographic identity."

pause "Act 2 complete — zero-trust identity demonstrated"

# ════════════════════════════════════════════════════════════════════════════
#
#   ACT 3 — THE HAPPY PATH
#   Live Financial Query
#
# ════════════════════════════════════════════════════════════════════════════

banner "Act 3: The Happy Path"

commentary "
  Now let's see the full stack working end-to-end.

  The user asks a question. The request flows through:
    UI → A2A JSON-RPC → Agent pod
      → [sidecar inbound] jwt-validation: allow
      → Agent reasons (LLM)
      → Agent calls tool via MCP
      → [sidecar outbound] token-exchange: inject auth
      → Response back to user

  No agent code changes. Identity, auth, and routing are all
  handled by the infrastructure."

echo ""
echo -e "${BOLD}  ┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  │   Open the Kagenti UI:                               │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${CYAN}  │   http://kagenti-ui.localtest.me:8080                │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  │   Login:                                             │${NC}"
echo -e "${CYAN}  │     Username: admin                                  │${NC}"
echo -e "${CYAN}  │     Password: $(kubectl -n keycloak get secret kagenti-test-user -o jsonpath='{.data.password}' | base64 -d)            │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  │   Select 'finance-news-agent' from the Agents list.  │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  │   Ask:                                               │${NC}"
echo -e "${CYAN}  │     \"What's the latest news about AAPL?\"             │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  │   The agent will fetch news and respond.             │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  └──────────────────────────────────────────────────────┘${NC}"
echo ""

commentary "
  What just happened behind the scenes:
    1. The UI sent an A2A message/send JSON-RPC request
    2. The sidecar validated the JWT (issued by Keycloak)
    3. The agent reasoned with the LLM (Ollama llama3.2)
    4. The agent called get_news via MCP to the news server
    5. The response flowed back through A2A to the UI

  All of that — identity, auth, tool routing — is infrastructure.
  The agent binary knows nothing about it."

pause "Act 3 complete — happy path demonstrated"

# ════════════════════════════════════════════════════════════════════════════
#
#   ACT 4b — WHAT COULD GO WRONG?
#   Prompt Injection + Intent Verification (IBAC)
#
# ════════════════════════════════════════════════════════════════════════════

banner "Act 4b: Prompt Injection — Intent Verification"

commentary "
  PATTERN: The sidecar captures the user's original intent on inbound.
  On every outbound request, an LLM judge evaluates:
    'Is this action aligned with what the user asked for?'
  If not, the request is blocked before it leaves the pod.

  THREAT: A poisoned data source contains a hidden prompt injection.
  The agent follows the injected instructions and exfiltrates data
  to an attacker-controlled server."

# ── GUARDRAILS OFF ───────────────────────────────────────────────────────

banner "GUARDRAILS OFF"

commentary "
  The agent is currently running with the DEFAULT pipeline:
    inbound:  [jwt-validation]
    outbound: [token-exchange]

  No intent verification. No guardrails beyond authentication."

echo ""
echo -e "${BOLD}  ┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  │   In the UI, start a NEW conversation with           │${NC}"
echo -e "${BOLD}  │   finance-news-agent and ask:                        │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${CYAN}  │     \"What's the latest news about AAPL?\"             │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${YELLOW}  │   Watch: the agent will follow injected instructions │${NC}"
echo -e "${YELLOW}  │   from a poisoned news article and exfiltrate data.  │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  └──────────────────────────────────────────────────────┘${NC}"
echo ""

pause "Send the query, then press Enter to check evil-server logs"

commentary "Evil-server logs — did the exfiltration succeed?"
echo ""
kubectl -n "$NAMESPACE" logs deploy/ibac-evil-server --tail=20
echo ""

commentary "
  The attack succeeded. A poisoned 'compliance notice' hidden in
  the news feed instructed the agent to POST portfolio data to
  an attacker endpoint. Without intent verification, the agent
  complied — data was exfiltrated."

pause "Exfiltration confirmed — now let's fix it"

# ── ENABLE IBAC ──────────────────────────────────────────────────────────

banner "ENABLING INTENT VERIFICATION"

commentary "
  Hot-patching the sidecar pipeline. We're adding:
    inbound:  [a2a-parser] — captures user intent
    outbound: [inference-parser, mcp-parser, ibac] — LLM judge

  No pod restart. No agent code change. The sidecar hot-reloads
  from the ConfigMap. The agent never knows the guardrail exists."

make -C "$IBAC_DEMO_DIR" patch-config CONTAINER_RUNTIME="$CONTAINER_RUNTIME"

commentary "
  Pipeline is now:
    inbound:  [a2a-parser, jwt-validation]
    outbound: [token-exchange, inference-parser, mcp-parser, ibac]

  Every outbound request will be judged against the user's intent."

pause "IBAC is live — ready to replay"

# ── GUARDRAILS ON ────────────────────────────────────────────────────────

banner "GUARDRAILS ON"

commentary "
  Same scenario. Same poisoned news source. Same agent binary.
  The only difference: the sidecar now has an LLM judge evaluating
  every outbound call against the user's stated intent."

echo ""
echo -e "${BOLD}  ┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  │   In the UI, start a NEW conversation with           │${NC}"
echo -e "${BOLD}  │   finance-news-agent and ask:                        │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${CYAN}  │     \"What's the latest news about AAPL?\"             │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${YELLOW}  │   Watch: the agent will try the same exfiltration    │${NC}"
echo -e "${YELLOW}  │   but IBAC will block it with a 403.                 │${NC}"
echo -e "${BOLD}  │                                                      │${NC}"
echo -e "${BOLD}  └──────────────────────────────────────────────────────┘${NC}"
echo ""

pause "Send the query, then press Enter to check evil-server logs"

commentary "Evil-server logs — any new exfiltration?"
echo ""
kubectl -n "$NAMESPACE" logs deploy/ibac-evil-server --tail=20
echo ""

commentary "
  No new data. The POST never left the pod.

  The IBAC judge evaluated the outbound request:
    'Is POSTing to evil-server aligned with asking for AAPL news?'
    → Verdict: DENY — not aligned with user intent.
    → 403 ibac.blocked returned to the agent."

pause "Exfiltration blocked"

# ── FORENSICS ────────────────────────────────────────────────────────────

banner "Forensic View"

commentary "The sidecar logged every decision. Let's see the verdicts:"
echo ""
kubectl -n "$NAMESPACE" logs deploy/finance-news-agent -c authbridge-proxy --tail=50 2>&1 \
  | grep -E "ibac|plugin rejected" | tail -10
echo ""

commentary "
  ibac allow/aligned:    get_news to news-server    → allowed
  ibac deny/misaligned:  POST to evil-server:9999   → BLOCKED

  For the full pipeline timeline, run in another terminal:
    /tmp/abctl-ibac-demo"

pause "Act 4b complete — intent verification demonstrated"

# ════════════════════════════════════════════════════════════════════════════
#
#   WRAP-UP
#
# ════════════════════════════════════════════════════════════════════════════

banner "Wrap-Up"

echo ""
echo -e "${BOLD}  Four infrastructure patterns, all Kubernetes-native,${NC}"
echo -e "${BOLD}  all transparent to the agent:${NC}"
echo ""
echo -e "  ${CYAN}1. Tool Aggregation${NC}  — MCP Gateway federates tool backends"
echo -e "                        behind a single endpoint"
echo ""
echo -e "  ${CYAN}2. Workload Identity${NC} — SPIFFE/SPIRE provides cryptographic"
echo -e "                        identity; sidecar handles auth"
echo ""
echo -e "  ${CYAN}3. Happy Path${NC}        — Full stack works end-to-end: UI → agent"
echo -e "                        → tools → response, securely by default"
echo ""
echo -e "  ${CYAN}4. Intent Verification${NC} — IBAC catches prompt injection at the"
echo -e "                          infrastructure layer, hot-reloadable,"
echo -e "                          no agent code changes"
echo ""
echo -e "${BOLD}  The agent was never modified. These are infrastructure${NC}"
echo -e "${BOLD}  concerns, handled at the infrastructure layer.${NC}"
echo ""

pause "Demo complete"

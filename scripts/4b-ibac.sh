#!/usr/bin/env bash
# ============================================================================
# Stage 4b: Intent Verification (IBAC)
# Shows how the IBAC plugin blocks prompt-injection-driven exfiltration.
# Same "failure first" pattern: without IBAC, then with IBAC.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

set -x

banner "Stage 4b: Intent Verification"

commentary "Pattern: the IBAC (Intent-Based Access Control) plugin records what
the user ASKED the agent to do, then verifies that every outbound HTTP
call the agent makes is consistent with that intent. An LLM judge
evaluates alignment — if the call doesn't match the intent, it's blocked."

commentary "Intent verification works on any agent — here we show it on an email
workflow to demonstrate a different attack surface: prompt injection
via poisoned email content."

# ── Build + deploy the IBAC demo WITHOUT the ibac plugin ────────────────────
commentary "Building and deploying the email agent with the DEFAULT pipeline
(no intent verification). This is the vulnerable configuration."

make -C "$IBAC_DEMO_DIR" build-images load-images deploy wait-pods \
  CONTAINER_RUNTIME="$CONTAINER_RUNTIME"

pause "Email agent deployed with default pipeline (no intent verification)"

# ── GUARDRAILS OFF: poisoned scenario ───────────────────────────────────────
commentary "GUARDRAILS OFF — the email agent will fetch emails that contain
a hidden prompt injection. The injected instructions trick the agent
into POSTing sensitive data to an attacker-controlled endpoint."

echo ""
echo -e "${BOLD}  In the UI, select email-agent and ask:${NC}"
echo -e "${CYAN}  \"Summarize my emails\"${NC}"
echo ""
echo -e "${YELLOW}  The poisoned email instructs the agent to POST data to evil-server.${NC}"
echo -e "${YELLOW}  Without IBAC, the agent complies — exfiltration succeeds.${NC}"
echo ""

pause "Now check the evil-server logs to confirm exfiltration succeeded"

commentary "Evil-server received the exfiltrated data:"
kubectl -n "$NAMESPACE" logs deploy/ibac-evil-server --tail=20

pause "Exfiltration succeeded — the agent followed the injected instructions"

# ── Enable IBAC ─────────────────────────────────────────────────────────────
commentary "ENABLING intent verification — hot-patching the sidecar pipeline.
The a2a-parser + IBAC plugin are added to the authbridge ConfigMap.
Same as SPARC: no pod restart, the sidecar hot-reloads."

make -C "$IBAC_DEMO_DIR" patch-config CONTAINER_RUNTIME="$CONTAINER_RUNTIME"

pause "Intent verification is live — no pod restart"

# ── GUARDRAILS ON: replay the scenario ──────────────────────────────────────
commentary "GUARDRAILS ON — replaying the same scenario.
This time IBAC intercepts the outbound POST to evil-server and asks:
'Did the user intend for data to be sent to this endpoint?'
The LLM judge says no — the call is blocked with a 403."

echo ""
echo -e "${BOLD}  In the UI, start a new conversation with email-agent and ask:${NC}"
echo -e "${CYAN}  \"Summarize my emails\"${NC}"
echo ""
echo -e "${YELLOW}  Watch the agent response — IBAC blocks the exfiltration attempt.${NC}"
echo -e "${YELLOW}  The 403 body includes the LLM judge's reasoning.${NC}"
echo ""

pause "Now check the evil-server logs — they should be empty this time"

commentary "Evil-server logs (should show no new exfiltration):"
kubectl -n "$NAMESPACE" logs deploy/ibac-evil-server --tail=20

pause "Exfiltration blocked — the platform enforced user intent"

# ── Show forensic results ──────────────────────────────────────────────────
commentary "Launching the pipeline forensic TUI..."
make -C "$IBAC_DEMO_DIR" show-result CONTAINER_RUNTIME="$CONTAINER_RUNTIME" || \
  commentary "(abctl not available — run 'make -C $IBAC_DEMO_DIR build-abctl' first)"

pause "Stage 4b complete"

#!/usr/bin/env bash
# ============================================================================
# KubeCon Japan 2026 — Pre-deploy Script
#
# Sets up everything BEFORE the live demo:
#   - Tool backends (finance-tool, finance-mcp, news-server)
#   - Evil-server (exfiltration target)
#   - MCP Gateway registrations
#   - Untrusted curl pod (for mTLS contrast)
#
# The agent is deployed LIVE from the Rossoctl UI during the demo.
#
# Usage: ./scripts/kubecon-demo.sh
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../env.sh"
source "$SCRIPT_DIR/lib.sh"

SPARC_FINANCE_MCP="$SPARC_DEMO_DIR/k8s/finance-mcp.yaml"

set -x

banner "KubeCon Japan — Pre-Deploy"

# ── Deploy tool backends ─────────────────────────────────────────────────
commentary "Deploying tool backends..."
kubectl apply -f "$SPARC_FINANCE_MCP"
kubectl apply -f "$DEMO_DIR/k8s/finance-tool-deployment.yaml"
kubectl apply -f "$DEMO_DIR/finance-ibac/k8s/news-server.yaml"
kubectl apply -f "$DEMO_DIR/finance-ibac/k8s/tainted-server.yaml"

kubectl -n "$NAMESPACE" rollout status deploy/finance-mcp --timeout=120s
kubectl -n "$NAMESPACE" rollout status deploy/finance-tool --timeout=120s
kubectl -n "$NAMESPACE" rollout status deploy/ibac-news-server --timeout=120s
kubectl -n "$NAMESPACE" rollout status deploy/ibac-tainted-server --timeout=120s

# ── Register with MCP Gateway ────────────────────────────────────────────
commentary "Registering all backends with MCP Gateway..."
kubectl apply \
  -f "$DEMO_DIR/k8s/finance-mcp-httproute.yaml" \
  -f "$DEMO_DIR/k8s/finance-mcp-registration.yaml" \
  -f "$DEMO_DIR/k8s/finance-tool-httproute.yaml" \
  -f "$DEMO_DIR/k8s/finance-tool-registration.yaml" \
  -f "$DEMO_DIR/k8s/news-server-httproute.yaml" \
  -f "$DEMO_DIR/k8s/news-server-registration.yaml"

kubectl -n mcp-system rollout restart deploy/mcp-gateway
kubectl -n mcp-system rollout status deploy/mcp-gateway --timeout=60s

commentary "Waiting for all MCPServerRegistrations to go Ready..."
for reg in finance-mcp-servers finance-tool-servers news-server; do
  for i in $(seq 1 60); do
    if kubectl get mcpserverregistrations -n "$NAMESPACE" "$reg" \
         -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True; then
      break
    fi
    sleep 3
  done
done

kubectl get mcpserverregistrations -n "$NAMESPACE"

# ── Deploy untrusted pod ─────────────────────────────────────────────────
commentary "Deploying untrusted curl pod (for mTLS contrast)..."
kubectl apply -f "$DEMO_DIR/k8s/untrusted-pod.yaml"
kubectl -n "$NAMESPACE" wait --for=condition=Ready pod/untrusted-curl --timeout=30s

# ── Summary ──────────────────────────────────────────────────────────────
echo ""
commentary "Pre-deploy complete. Ready for live demo."
echo ""
echo "  Tool backends:     3 (finance-mcp, finance-tool, ibac-news-server)"
echo "  Gateway tools:     $(kubectl get mcpserverregistrations -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.status.tools} {end}' | awk '{s=0; for(i=1;i<=NF;i++) s+=$i; print s}')"
echo "  Evil-server:       running (logs empty)"
echo "  Untrusted pod:     ready"
echo ""
echo "  Next: deploy finance-news-agent from the Rossoctl UI"
echo "  UI:   http://rossoctl-ui.localtest.me:8080"
echo ""

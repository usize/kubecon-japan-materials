#!/usr/bin/env bash
# ============================================================================
# Stage 1: Tool Aggregation via MCP Gateway
# Builds and deploys finance MCP tool backends, registers them with the
# MCP Gateway via HTTPRoute + MCPServerRegistration CRs.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

KIND_NODE="${CLUSTER_NAME}-control-plane"

set -x

banner "Stage 1: Tool Aggregation via MCP Gateway"

commentary "The MCP Gateway federates multiple tool backends behind a single endpoint.
Each backend registers its tools with a unique prefix — the agent sees one
unified tool catalog, the platform handles routing."

# ── Build + load finance-mcp image ──────────────────────────────────────────
commentary "Building the finance-mcp (transactions) server image..."
"$CONTAINER_RUNTIME" build \
  -f "$SPARC_DEMO_DIR/finance-mcp/Dockerfile" \
  -t "$FINANCE_MCP_IMAGE" \
  "$SPARC_DEMO_DIR"

commentary "Loading image into Kind cluster..."
kind load docker-image "$FINANCE_MCP_IMAGE" --name "$CLUSTER_NAME"
"$CONTAINER_RUNTIME" exec "$KIND_NODE" \
  ctr -n k8s.io images tag "localhost/$FINANCE_MCP_IMAGE" "docker.io/library/$FINANCE_MCP_IMAGE" \
  >/dev/null 2>&1 || true

pause "finance-mcp image built and loaded into Kind"

# ── Deploy finance-mcp ──────────────────────────────────────────────────────
commentary "Deploying the finance-mcp backend (Deployment + Service)..."
kubectl apply -f "$SPARC_DEMO_DIR/k8s/finance-mcp.yaml"
wait_rollout "$NAMESPACE" finance-mcp

# ── Register finance-mcp with MCP Gateway ─────────────────────────────────
commentary "Registering finance-mcp with the MCP Gateway via HTTPRoute + MCPServerRegistration..."
kubectl apply -f "$DEMO_DIR/k8s/finance-mcp-httproute.yaml"
kubectl apply -f "$DEMO_DIR/k8s/finance-mcp-registration.yaml"

pause "finance-mcp registered"

# ── Build + load finance-tool image ──────────────────────────────────────
commentary "Building the finance-tool (market data) server image..."
"$CONTAINER_RUNTIME" build \
  -t "$FINANCE_TOOL_IMAGE" \
  "$DEMO_DIR/finance-tool"

commentary "Loading finance-tool image into Kind cluster..."
kind load docker-image "$FINANCE_TOOL_IMAGE" --name "$CLUSTER_NAME"
"$CONTAINER_RUNTIME" exec "$KIND_NODE" \
  ctr -n k8s.io images tag "localhost/$FINANCE_TOOL_IMAGE" "docker.io/library/$FINANCE_TOOL_IMAGE" \
  >/dev/null 2>&1 || true

pause "finance-tool image built and loaded into Kind"

# ── Deploy finance-tool ──────────────────────────────────────────────────
commentary "Deploying the finance-tool backend (Deployment + Service)..."
kubectl apply -f "$DEMO_DIR/k8s/finance-tool-deployment.yaml"
wait_rollout "$NAMESPACE" finance-tool

# ── Register finance-tool with MCP Gateway ───────────────────────────────
commentary "Registering finance-tool with the MCP Gateway via HTTPRoute + MCPServerRegistration..."
kubectl apply -f "$DEMO_DIR/k8s/finance-tool-httproute.yaml"
kubectl apply -f "$DEMO_DIR/k8s/finance-tool-registration.yaml"

# ── Restart MCP Gateway broker ───────────────────────────────────────────
# Restart after both tools are registered so the broker picks up both
# backends in a single reconnect cycle.
commentary "Restarting MCP Gateway broker to pick up new registrations..."
kubectl -n mcp-system rollout restart deploy/mcp-gateway
kubectl -n mcp-system rollout status deploy/mcp-gateway --timeout=60s

# Wait for both registrations to be accepted
commentary "Waiting for MCPServerRegistrations to be ready..."
for reg in finance-mcp-servers finance-tool-servers; do
  for i in $(seq 1 60); do
    if kubectl get mcpserverregistrations -n "$NAMESPACE" "$reg" \
         -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True; then
      break
    fi
    sleep 3
  done
done

kubectl get mcpserverregistrations -n "$NAMESPACE"

pause "Both tool backends registered with MCP Gateway"

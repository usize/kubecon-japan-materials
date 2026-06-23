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

# ── Register with MCP Gateway ──────────────────────────────────────────────
commentary "Registering finance-mcp with the MCP Gateway via HTTPRoute + MCPServerRegistration..."
kubectl apply -f "$DEMO_DIR/k8s/finance-mcp-httproute.yaml"
kubectl apply -f "$DEMO_DIR/k8s/finance-mcp-registration.yaml"

# Restart the MCP Gateway broker so it immediately attempts to connect to the
# newly registered backend (otherwise it can cache stale "not found" state).
commentary "Restarting MCP Gateway broker to pick up new registration..."
kubectl -n mcp-system rollout restart deploy/mcp-gateway
kubectl -n mcp-system rollout status deploy/mcp-gateway --timeout=60s

# Wait for registration to be accepted
commentary "Waiting for MCPServerRegistration to be ready..."
for i in $(seq 1 60); do
  if kubectl get mcpserverregistrations -n "$NAMESPACE" finance-mcp-servers \
       -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True; then
    break
  fi
  sleep 3
done

kubectl get mcpserverregistrations -n "$NAMESPACE"

# ── Placeholder: finance-tool (Vincent's market data server) ────────────────
# TODO: When Vincent's finance-tool lands in the repo:
# 1. Build the image: $CONTAINER_RUNTIME build -t $FINANCE_TOOL_IMAGE <path>
# 2. Load into kind: kind load docker-image $FINANCE_TOOL_IMAGE --name $CLUSTER_NAME
# 3. Deploy: kubectl apply -f $DEMO_DIR/k8s/finance-tool-deployment.yaml
# 4. Register: kubectl apply -f $DEMO_DIR/k8s/finance-tool-httproute.yaml
#              kubectl apply -f $DEMO_DIR/k8s/finance-tool-registration.yaml
commentary "Note: finance-tool (market data) is not yet available locally.
The demo runs with the finance-mcp (transactions) backend.
When finance-tool lands, uncomment the deployment section in this script."

pause "Tool backend registered with MCP Gateway"

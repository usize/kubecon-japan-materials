#!/usr/bin/env bash
# ============================================================================
# fintech-demo/env.sh — shared environment defaults for all stage scripts.
# Source this file; do not execute it directly.
# ============================================================================

# Repo root — derived from this file's location so the demo works from any CWD.
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZOO_ROOT="$(cd "$DEMO_DIR/.." && pwd)"

# Cluster / namespace constants
CLUSTER_NAME="${CLUSTER_NAME:-kagenti}"
NAMESPACE="${NAMESPACE:-team1}"
PLATFORM_NS="${PLATFORM_NS:-kagenti-system}"

# MCP Gateway in-cluster URL (Istio Gateway controller)
MCP_GATEWAY_URL="http://mcp-gateway-istio.gateway-system.svc.cluster.local:8080/mcp"

# Paths to dependencies (cloned into thirdparty/)
KAGENTI_ROOT="$DEMO_DIR/thirdparty/kagenti"
EXTENSIONS_ROOT="$DEMO_DIR/thirdparty/kagenti-extensions"
SPARC_DEMO_DIR="$EXTENSIONS_ROOT/AuthBridge/demos/finance-sparc"
IBAC_DEMO_DIR="$DEMO_DIR/finance-ibac"
SETUP_SCRIPT="$KAGENTI_ROOT/scripts/kind/setup-kagenti.sh"

# Image names (local-only, not pushed)
FINANCE_TOOL_IMAGE="${FINANCE_TOOL_IMAGE:-finance-tool:latest}"
FINANCE_MCP_IMAGE="${FINANCE_MCP_IMAGE:-finance-mcp:latest}"

# Container runtime detection (prefer docker, fall back to podman)
if docker info >/dev/null 2>&1; then
  CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-docker}"
elif podman info >/dev/null 2>&1; then
  CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-podman}"
else
  CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-docker}"
fi

export DEMO_DIR ZOO_ROOT CLUSTER_NAME NAMESPACE PLATFORM_NS MCP_GATEWAY_URL
export KAGENTI_ROOT EXTENSIONS_ROOT SPARC_DEMO_DIR IBAC_DEMO_DIR SETUP_SCRIPT
export FINANCE_TOOL_IMAGE FINANCE_MCP_IMAGE CONTAINER_RUNTIME

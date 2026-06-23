#!/usr/bin/env bash
# ============================================================================
# fintech-demo/scripts/teardown.sh — cleanup all demo resources.
#
# By default, removes demo workloads but keeps the Kind cluster.
# Pass --destroy-cluster to also delete the Kind cluster.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

DESTROY_CLUSTER=false
for arg in "$@"; do
  case "$arg" in
    --destroy-cluster) DESTROY_CLUSTER=true ;;
  esac
done

set -x

banner "Teardown"

# ── Undeploy IBAC demo resources ────────────────────────────────────────────
commentary "Removing IBAC demo resources..."
make -C "$IBAC_DEMO_DIR" undeploy CONTAINER_RUNTIME="$CONTAINER_RUNTIME" 2>/dev/null || true

# ── Undeploy SPARC demo resources ──────────────────────────────────────────
commentary "Removing SPARC demo resources..."
make -C "$SPARC_DEMO_DIR" undeploy CONTAINER_RUNTIME="$CONTAINER_RUNTIME" 2>/dev/null || true

# ── Delete MCP Gateway registrations ───────────────────────────────────────
commentary "Removing MCP Gateway resources..."
kubectl delete -f "$DEMO_DIR/k8s/" --ignore-not-found 2>/dev/null || true

# ── Delete untrusted pod ───────────────────────────────────────────────────
kubectl -n "$NAMESPACE" delete pod untrusted-curl --ignore-not-found 2>/dev/null || true

# ── Optionally destroy the Kind cluster ─────────────────────────────────────
if [ "$DESTROY_CLUSTER" = true ]; then
  commentary "Deleting Kind cluster '$CLUSTER_NAME'..."
  kind delete cluster --name "$CLUSTER_NAME"
else
  commentary "Kind cluster '$CLUSTER_NAME' kept. Pass --destroy-cluster to remove it."
fi

commentary "Teardown complete."

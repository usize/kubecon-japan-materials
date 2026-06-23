#!/usr/bin/env bash
# ============================================================================
# Stage 0: Platform Setup
# Creates a Kind cluster and installs the kagenti platform stack.
# Pass --skip-cluster to reuse an existing cluster.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

SKIP_CLUSTER=false
for arg in "$@"; do
  case "$arg" in
    --skip-cluster) SKIP_CLUSTER=true ;;
  esac
done

set -x

banner "Stage 0: Platform Setup"

# ── Prereq check ────────────────────────────────────────────────────────────
commentary "Checking prerequisites..."
require_cmd kubectl "kubectl is required — https://kubernetes.io/docs/tasks/tools/"
require_cmd helm    "helm v3 is required — https://helm.sh/docs/intro/install/"

if [ "$SKIP_CLUSTER" = false ]; then
  require_cmd kind "kind is required — https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
  if [ "$CONTAINER_RUNTIME" = "docker" ]; then
    require_cmd docker "docker is required (or set CONTAINER_RUNTIME=podman)"
  else
    require_cmd podman "podman is required (or install docker)"
  fi
fi

# ── Create cluster + install platform ───────────────────────────────────────
if [ "$SKIP_CLUSTER" = false ]; then
  pause "Will create Kind cluster '$CLUSTER_NAME' and install the kagenti platform stack"

  bash "$SETUP_SCRIPT" \
    --cluster-name "$CLUSTER_NAME" \
    --with-spire \
    --with-mcp-gateway \
    --with-ui \
    --with-mlflow
else
  commentary "Skipping cluster creation (--skip-cluster). Using existing cluster."
fi

# ── Verify platform pods ───────────────────────────────────────────────────
commentary "Verifying platform components are running..."
kubectl get pods -n "$PLATFORM_NS"      --no-headers | head -20
kubectl get pods -n gateway-system       --no-headers 2>/dev/null | head -10 || true
kubectl get pods -n mcp-system           --no-headers 2>/dev/null | head -10 || true
kubectl get pods -n keycloak             --no-headers 2>/dev/null | head -10 || true
kubectl get pods -n spire-system         --no-headers 2>/dev/null | head -10 || true

pause "Platform deployed — all core components running"

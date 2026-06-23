#!/usr/bin/env bash
# ============================================================================
# Stage 2: Workload Identity
# Deploys the finance agent with SPIFFE identity auto-injection,
# then contrasts with an untrusted pod that has no identity.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

KIND_NODE="${CLUSTER_NAME}-control-plane"
AGENT_IMAGE="finance-agent:latest"

set -x

banner "Stage 2: Workload Identity"

commentary "Every agent pod gets a cryptographic identity automatically.
The kagenti operator injects a SPIFFE/SPIRE sidecar that provisions
an X.509 SVID — no application code changes needed."

# ── Build + load the agent image ────────────────────────────────────────────
commentary "Building the finance-agent image..."
"$CONTAINER_RUNTIME" build \
  -f "$SPARC_DEMO_DIR/finance-agent/Dockerfile" \
  -t "$AGENT_IMAGE" \
  "$SPARC_DEMO_DIR"

commentary "Loading agent image into Kind cluster..."
kind load docker-image "$AGENT_IMAGE" --name "$CLUSTER_NAME"
"$CONTAINER_RUNTIME" exec "$KIND_NODE" \
  ctr -n k8s.io images tag "localhost/$AGENT_IMAGE" "docker.io/library/$AGENT_IMAGE" \
  >/dev/null 2>&1 || true

# ── Deploy the finance agent ────────────────────────────────────────────────
commentary "Deploying the finance agent (operator-injected AuthBridge sidecar)..."
kubectl apply -f "$SPARC_DEMO_DIR/k8s/agent.yaml"
wait_rollout "$NAMESPACE" finance-agent 180s

# Wait for operator to create the authbridge ConfigMap
for i in $(seq 1 60); do
  kubectl -n "$NAMESPACE" get cm authbridge-config-finance-agent >/dev/null 2>&1 && break
  sleep 2
done

# ── Show SPIFFE identity ───────────────────────────────────────────────────
commentary "Reading the agent's SPIFFE identity from the injected sidecar..."
AGENT_POD=$(get_pod "$NAMESPACE" "app.kubernetes.io/name=finance-agent")
kubectl exec -n "$NAMESPACE" "$AGENT_POD" -c authbridge-proxy -- \
  cat /shared/client-id.txt 2>/dev/null || \
  commentary "(client-id.txt not yet written — operator registration may still be in progress)"

pause "Agent deployed with cryptographic workload identity"

# ── Deploy untrusted pod ───────────────────────────────────────────────────
commentary "Deploying an untrusted pod — a plain curl container with no kagenti labels.
No sidecar injection, no SPIFFE identity, no credentials."
kubectl apply -f "$DEMO_DIR/k8s/untrusted-pod.yaml"
kubectl -n "$NAMESPACE" wait --for=condition=Ready pod/untrusted-curl --timeout=60s 2>/dev/null || true

# ── Contrast: untrusted pod tries to reach the agent ────────────────────────
commentary "The untrusted pod attempts to send a message to the agent's A2A endpoint.
Without a valid JWT, the AuthBridge sidecar rejects the request with 401.
(The .well-known/agent-card.json discovery endpoint is intentionally
bypassed — agents need to be discoverable, but not callable.)"

kubectl exec -n "$NAMESPACE" untrusted-curl -- \
  curl -s -w "\nHTTP %{http_code}\n" -X POST \
  "http://finance-agent.$NAMESPACE.svc.cluster.local:8080/" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"1","method":"message/send","params":{"message":{"role":"user","parts":[{"kind":"text","text":"hello"}]}}}' \
  2>/dev/null || true

pause "Without identity, you don't get in"

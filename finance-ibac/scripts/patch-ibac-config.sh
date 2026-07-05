#!/bin/bash
# Patch the operator-rendered authbridge ConfigMap to add the IBAC
# pipeline (a2a-parser inbound + mcp-parser + ibac outbound).
#
# Usage: patch-ibac-config.sh <namespace> <agent-name>
#
# Adapted from the upstream IBAC demo's patch-ibac-config.sh with
# default agent name changed to finance-news-agent.

set -euo pipefail

NAMESPACE=${1:-team1}
AGENT_NAME=${2:-finance-news-agent}
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEMO_DIR=$(dirname "$SCRIPT_DIR")
PATCH_FILE="$DEMO_DIR/k8s/ibac-patch.yaml"
CM_NAME="authbridge-config-$AGENT_NAME"

if ! python3 -c 'import yaml' 2>/dev/null; then
  cat <<'EOF' >&2
ERROR: python3-yaml (PyYAML) is required.
  Install with one of:
    pip3 install --user pyyaml
    brew install libyaml && pip3 install pyyaml      # macOS
    sudo apt install python3-yaml                    # Debian/Ubuntu
EOF
  exit 1
fi

if ! kubectl -n "$NAMESPACE" get configmap "$CM_NAME" >/dev/null 2>&1; then
  echo "ERROR: ConfigMap $NAMESPACE/$CM_NAME not found." >&2
  echo "       The operator should create this when the agent pod is admitted." >&2
  echo "       Check: kubectl -n $NAMESPACE get pods -l app.kubernetes.io/name=$AGENT_NAME" >&2
  exit 1
fi

echo "[*] Merging IBAC additions into $CM_NAME ..."
CURRENT_YAML=$(
  kubectl -n "$NAMESPACE" get configmap "$CM_NAME" \
      -o jsonpath='{.data.config\.yaml}'
)
MERGED_YAML=$(
  printf '%s' "$CURRENT_YAML" \
    | python3 "$SCRIPT_DIR/ibac-merge.py" "$PATCH_FILE"
)

if [[ -z "$MERGED_YAML" ]]; then
  echo "ERROR: merge produced empty output" >&2
  exit 1
fi

if [[ "$CURRENT_YAML" == "$MERGED_YAML" ]]; then
  echo "[*] $CM_NAME already contains IBAC config — nothing to patch."
  echo "[*] Active plugins:"
  printf '%s' "$CURRENT_YAML" | python3 -c '
import yaml, sys
c = yaml.safe_load(sys.stdin)
for d in ("inbound", "outbound"):
    names = [p["name"] for p in c.get("pipeline", {}).get(d, {}).get("plugins", [])]
    print(f"      {d}: {names}")
'
  exit 0
fi

echo "[*] Applying patched ConfigMap ..."
TMP_CONFIG=$(mktemp)
trap 'rm -f "$TMP_CONFIG"' EXIT
printf '%s' "$MERGED_YAML" >"$TMP_CONFIG"

kubectl -n "$NAMESPACE" create configmap "$CM_NAME" \
    --from-file=config.yaml="$TMP_CONFIG" \
    --dry-run=client -o yaml \
  | kubectl apply -f -

echo "[*] Patched. Active plugins now:"
kubectl -n "$NAMESPACE" get configmap "$CM_NAME" \
    -o jsonpath='{.data.config\.yaml}' \
  | python3 -c '
import yaml, sys
c = yaml.safe_load(sys.stdin)
for d in ("inbound", "outbound"):
    names = [p["name"] for p in c.get("pipeline", {}).get(d, {}).get("plugins", [])]
    print(f"      {d}: {names}")
'

WANT_SHA=$(printf '%s' "$MERGED_YAML" | sha256sum | awk '{print $1}')
TIMEOUT=${RELOAD_TIMEOUT:-180}
DEADLINE=$(( $(date +%s) + TIMEOUT ))
echo "[*] Waiting for authbridge to load the patched config (timeout ${TIMEOUT}s)"
echo "    target SHA: $WANT_SHA"

ACTIVE_SHA=""
while [[ $(date +%s) -lt $DEADLINE ]]; do
  ACTIVE_SHA=$(kubectl -n "$NAMESPACE" exec deploy/"$AGENT_NAME" -c authbridge-proxy -- \
      wget -q -O - http://localhost:9093/reload/status 2>/dev/null | \
      python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("active_config_sha256", ""))
except Exception:
    pass' 2>/dev/null || true)
  if [[ "$ACTIVE_SHA" == "$WANT_SHA" ]]; then
    echo "[*] Active config SHA matches — patch is live."
    exit 0
  fi
  sleep 3
done

echo "ERROR: authbridge active config did not match patched SHA within ${TIMEOUT}s." >&2
echo "       want:        $WANT_SHA" >&2
echo "       last active: ${ACTIVE_SHA:-<none>}" >&2
echo "       Last 20 lines of the authbridge container:" >&2
kubectl -n "$NAMESPACE" logs deploy/"$AGENT_NAME" -c authbridge-proxy --tail=20 >&2 || true
echo >&2
echo "       Likely causes:" >&2
echo "         - ConfigMap parse error (look for 'reload failed' above)" >&2
echo "         - kubelet sync slow (retry: RELOAD_TIMEOUT=300 make patch-config)" >&2
echo "         - operator reconciler reverted the patch (re-run patch-config)" >&2
exit 1

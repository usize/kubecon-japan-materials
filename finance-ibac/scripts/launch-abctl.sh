#!/bin/bash
# Launch abctl against the Finance-IBAC agent's authbridge sidecar.
#
# Adapted from the upstream IBAC demo's launch-abctl.sh with default
# agent name changed to finance-news-agent.

set -euo pipefail

NAMESPACE=${1:-team1}
AGENT_NAME=${2:-finance-news-agent}
ABCTL_BIN=${ABCTL_BIN:-/tmp/abctl-ibac-demo}

if [[ ! -x "$ABCTL_BIN" ]]; then
  echo "ERROR: abctl binary not found at $ABCTL_BIN." >&2
  echo "       Run \`make show-result\` (which depends on build-abctl)" >&2
  echo "       or \`make build-abctl\` first." >&2
  exit 1
fi

if ! kubectl -n "$NAMESPACE" get deploy "$AGENT_NAME" >/dev/null 2>&1; then
  echo "ERROR: deployment $NAMESPACE/$AGENT_NAME not found." >&2
  echo "       Run 'make demo-ibac' first." >&2
  exit 1
fi

"$ABCTL_BIN"

#!/usr/bin/env bash
# ============================================================================
# fintech-demo/scripts/lib.sh — shared helpers for interactive demo scripts.
#
# Source this file from each stage script after sourcing env.sh.
# Provides colored output, pause prompts, and kubectl convenience wrappers.
# ============================================================================

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'  # No Color

# ── banner ──────────────────────────────────────────────────────────────────
# Print a cyan box header. Temporarily disables xtrace so the banner isn't
# cluttered with shell expansion noise.
#   banner "Stage 0: Platform Setup"
banner() {
  local restore_x=false
  if [[ $- == *x* ]]; then restore_x=true; set +x; fi

  local msg="$1"
  local len=${#msg}
  local border
  border=$(printf '═%.0s' $(seq 1 $((len + 4))))

  echo ""
  echo -e "${CYAN}╔${border}╗${NC}"
  echo -e "${CYAN}║  ${BOLD}${msg}${NC}${CYAN}  ║${NC}"
  echo -e "${CYAN}╚${border}╝${NC}"
  echo ""

  if $restore_x; then set -x; fi
}

# ── pause ───────────────────────────────────────────────────────────────────
# Green checkmark + message, then wait for Enter.
#   pause "Platform deployed — press Enter to continue"
pause() {
  local restore_x=false
  if [[ $- == *x* ]]; then restore_x=true; set +x; fi

  echo ""
  echo -e "${GREEN}✓ $1${NC}"
  read -r -p "  Press Enter to continue..."
  echo ""

  if $restore_x; then set -x; fi
}

# ── commentary ──────────────────────────────────────────────────────────────
# Yellow explanatory text, no Enter wait. Use for narration between commands.
#   commentary "The MCP Gateway aggregates tool backends behind a single endpoint."
commentary() {
  local restore_x=false
  if [[ $- == *x* ]]; then restore_x=true; set +x; fi

  echo ""
  echo -e "${YELLOW}▸ $1${NC}"
  echo ""

  if $restore_x; then set -x; fi
}

# ── wait_rollout ────────────────────────────────────────────────────────────
# Wait for a deployment rollout to complete.
#   wait_rollout <namespace> <deployment-name> [timeout]
wait_rollout() {
  local ns="$1" deploy="$2" timeout="${3:-180s}"
  kubectl -n "$ns" rollout status "deploy/$deploy" --timeout="$timeout"
}

# ── get_pod ─────────────────────────────────────────────────────────────────
# Get the first pod name matching a label selector.
#   get_pod <namespace> <label-selector>
get_pod() {
  local ns="$1" selector="$2"
  kubectl get pod -n "$ns" -l "$selector" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null
}

# ── require_cmd ─────────────────────────────────────────────────────────────
# Check that a command exists, fail with a message if not.
#   require_cmd kubectl "kubectl is required — install from https://kubernetes.io/docs/tasks/tools/"
require_cmd() {
  local cmd="$1" msg="${2:-$1 is required but not found}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${RED}ERROR: ${msg}${NC}" >&2
    exit 1
  fi
}

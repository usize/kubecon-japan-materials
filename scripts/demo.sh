#!/usr/bin/env bash
# ============================================================================
# fintech-demo/scripts/demo.sh — master orchestrator.
# Runs all demo stages in sequence with pause points between.
#
# Usage:
#   ./scripts/demo.sh                     # Full demo from Stage 0
#   ./scripts/demo.sh --skip-platform     # Skip cluster creation (Stage 0)
#   ./scripts/demo.sh --start-from 2      # Start from Stage 2
#   ./scripts/demo.sh --skip-platform --start-from 3
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../env.sh
source "$SCRIPT_DIR/../env.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

SKIP_PLATFORM=false
START_FROM=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-platform) SKIP_PLATFORM=true; shift ;;
    --start-from)    START_FROM="$2"; shift 2 ;;
    *)               echo "Unknown option: $1"; exit 1 ;;
  esac
done

banner "Kubecon Japan — Fintech Demo"

commentary "Running stages ${START_FROM} through 4b.
Each stage pauses for Enter at key moments.
Use Ctrl-C to stop at any point."

# ── Stage 0: Platform ──────────────────────────────────────────────────────
if [[ "$START_FROM" -le 0 ]]; then
  if [ "$SKIP_PLATFORM" = true ]; then
    commentary "Skipping Stage 0 (--skip-platform)"
    bash "$SCRIPT_DIR/0-platform.sh" --skip-cluster
  else
    bash "$SCRIPT_DIR/0-platform.sh"
  fi
  pause "Ready for Stage 1"
fi

# ── Stage 1: Tools ─────────────────────────────────────────────────────────
if [[ "$START_FROM" -le 1 ]]; then
  bash "$SCRIPT_DIR/1-tools.sh"
  pause "Ready for Stage 2"
fi

# ── Stage 2: Identity ──────────────────────────────────────────────────────
if [[ "$START_FROM" -le 2 ]]; then
  bash "$SCRIPT_DIR/2-identity.sh"
  pause "Ready for Stage 3"
fi

# ── Stage 3: Happy Path ───────────────────────────────────────────────────
if [[ "$START_FROM" -le 3 ]]; then
  bash "$SCRIPT_DIR/3-happy-path.sh"
  pause "Ready for Stage 4a"
fi

# ── Stage 4a: MLflow Judge ────────────────────────────────────────────────
if [[ "$START_FROM" -le 4 ]]; then
  bash "$SCRIPT_DIR/4a-mlflow-judge.sh"
  pause "Ready for Stage 4b"
fi

# ── Stage 4b: IBAC ────────────────────────────────────────────────────────
if [[ "$START_FROM" -le 5 ]]; then
  bash "$SCRIPT_DIR/4b-ibac.sh"
fi

banner "Demo Complete"
echo -e "${GREEN}All stages finished.${NC}"
echo ""
echo -e "  UI:       ${CYAN}http://rossoctl-ui.localtest.me:8080${NC}"
echo -e "  Teardown: ${CYAN}./scripts/teardown.sh${NC}"
echo ""

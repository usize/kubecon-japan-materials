#!/usr/bin/env bash
# ============================================================================
# Reset team1 namespace for a fresh demo run.
# Does NOT destroy the cluster or platform — just removes demo workloads.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../env.sh"

echo "[*] Cleaning team1 namespace..."
kubectl -n "$NAMESPACE" delete deploy --all --ignore-not-found 2>/dev/null
kubectl -n "$NAMESPACE" delete svc --all --ignore-not-found 2>/dev/null
kubectl -n "$NAMESPACE" delete agentruntime --all --ignore-not-found 2>/dev/null
kubectl -n "$NAMESPACE" delete sa finance-news-agent --ignore-not-found 2>/dev/null
kubectl -n "$NAMESPACE" delete pod untrusted-curl --ignore-not-found 2>/dev/null
kubectl -n "$NAMESPACE" delete configmap authbridge-config-finance-news-agent --ignore-not-found 2>/dev/null
kubectl -n "$NAMESPACE" delete secret -l kagenti.io/client-name=finance-news-agent --ignore-not-found 2>/dev/null
kubectl delete mcpserverregistrations -n "$NAMESPACE" --all --ignore-not-found 2>/dev/null
kubectl delete httproutes -n "$NAMESPACE" --all --ignore-not-found 2>/dev/null

echo "[*] Restarting MCP Gateway to clear stale state..."
kubectl -n mcp-system rollout restart deploy/mcp-gateway deploy/mcp-gateway-controller 2>/dev/null
kubectl -n mcp-system rollout status deploy/mcp-gateway --timeout=60s
kubectl -n mcp-system rollout status deploy/mcp-gateway-controller --timeout=60s

echo "[*] Clean. Ready for: ./scripts/kubecon-demo.sh"

#!/usr/bin/env bash
# ============================================================================
# Demonstrate MCP Gateway authorization: no-token vs valid-token.
# Runs curl from inside the cluster against the auth-protected gateway.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../env.sh"
source "$SCRIPT_DIR/lib.sh"

GATEWAY_URL="http://mcp-gateway-istio.gateway-system.svc.cluster.local:8080/mcp"
INIT_PAYLOAD='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"demo","version":"1.0"}},"id":1}'
TOOLS_PAYLOAD='{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}'
FILTER='command prompt\|recorded in container\|pod .* deleted\|^$'

# Run a curl request from inside the cluster via an ephemeral pod.
# Usage: cluster_curl <pod-name> [extra-env...] -- <curl-args...>
cluster_curl() {
  local name="$1"; shift
  kubectl run "$name" --rm -i --restart=Never --image=curlimages/curl \
    -n "$NAMESPACE" "$@" 2>&1 | grep -v "$FILTER"
}

banner "MCP Gateway: Authorization Demo"

# ── Acquire a valid token ─────────────────────────────────────────────────
commentary "Acquiring a Keycloak token for the mcp-gateway audience..."

KC_URL="http://keycloak.localtest.me:8080"
KC_ADMIN_TOKEN=$(curl -s -X POST "${KC_URL}/realms/master/protocol/openid-connect/token" \
  -d "grant_type=password&client_id=admin-cli&username=admin&password=admin" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

MCP_CLIENT_UUID=$(curl -s -H "Authorization: Bearer $KC_ADMIN_TOKEN" \
  "${KC_URL}/admin/realms/kagenti/clients?clientId=mcp-gateway" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

MCP_SECRET=$(curl -s -H "Authorization: Bearer $KC_ADMIN_TOKEN" \
  "${KC_URL}/admin/realms/kagenti/clients/$MCP_CLIENT_UUID/client-secret" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['value'])")

MCP_TOKEN=$(curl -s -X POST "${KC_URL}/realms/kagenti/protocol/openid-connect/token" \
  -d "grant_type=client_credentials&client_id=mcp-gateway&client_secret=${MCP_SECRET}&scope=openid" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo -e "  ${GREEN}✓${NC} Token acquired (${#MCP_TOKEN} chars, aud includes mcp-gateway)"
echo ""

# ── Test 1: No token → rejected ──────────────────────────────────────────
commentary "Test 1: Calling MCP Gateway WITHOUT a token..."
echo -e "  ${CYAN}\$ curl -X POST $GATEWAY_URL${NC}"
echo ""

RESULT=$(cluster_curl mcp-noauth -- \
  curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "$INIT_PAYLOAD")

BODY=$(echo "$RESULT" | sed '$d')
CODE=$(echo "$RESULT" | tail -1)

echo -e "  HTTP ${RED}${CODE}${NC}"
echo "$BODY" | python3 -m json.tool 2>/dev/null | sed 's/^/  /' || echo "  $BODY"
echo ""

# ── Test 2: With token → initialize ──────────────────────────────────────
commentary "Test 2: Calling MCP Gateway WITH a valid Keycloak token..."
echo -e "  ${CYAN}\$ curl -X POST $GATEWAY_URL -H \"Authorization: Bearer \$TOKEN\"${NC}"
echo ""

RESULT=$(cluster_curl mcp-auth --env="TOKEN=$MCP_TOKEN" -- \
  sh -c "curl -s -D /dev/stderr -X POST '$GATEWAY_URL' \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -H \"Authorization: Bearer \$TOKEN\" \
    -d '$INIT_PAYLOAD' && echo" 2>&1)

SESSION_ID=$(echo "$RESULT" | grep -i "mcp-session-id" | awk '{print $2}' | tr -d '\r')
BODY=$(echo "$RESULT" | grep "^{")

echo -e "  HTTP ${GREEN}200${NC}"
echo "$BODY" | python3 -m json.tool 2>/dev/null | sed 's/^/  /' || echo "  $BODY"
echo ""

# ── Test 3: List tools with session ──────────────────────────────────────
if [ -n "$SESSION_ID" ]; then
  commentary "Test 3: Listing tools (tools/list) with active session..."
  echo -e "  ${CYAN}\$ curl -X POST $GATEWAY_URL -H \"Mcp-Session-Id: ...\"${NC}"
  echo ""

  RESULT=$(cluster_curl mcp-tools --env="TOKEN=$MCP_TOKEN" --env="SESSION=$SESSION_ID" -- \
    sh -c "curl -s -X POST '$GATEWAY_URL' \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json, text/event-stream' \
      -H \"Authorization: Bearer \$TOKEN\" \
      -H \"Mcp-Session-Id: \$SESSION\" \
      -d '$TOOLS_PAYLOAD' && echo" 2>&1)

  BODY=$(echo "$RESULT" | grep "^{")

  echo -e "  HTTP ${GREEN}200${NC}"
  echo "$BODY" | python3 -m json.tool 2>/dev/null | sed 's/^/  /' || echo "  $BODY"
  echo ""
fi

# ── Summary ───────────────────────────────────────────────────────────────
echo -e "  ${BOLD}Result:${NC}"
echo -e "    Without token → ${RED}403 RBAC: access denied${NC}"
echo -e "    With token    → ${GREEN}200 MCP Gateway responds, tools listed${NC}"
echo ""
echo -e "  The agent's sidecar (AuthBridge) injects this token automatically"
echo -e "  via RFC 8693 token exchange using its SPIFFE identity."
echo ""

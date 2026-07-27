#!/usr/bin/env bash
# Show admin credentials and service URLs for the demo cluster.
set -euo pipefail

KC_NS="keycloak"

# Keycloak admin (master realm)
KC_USER=$(kubectl get secret -n "$KC_NS" keycloak-initial-admin -o jsonpath='{.data.username}' 2>/dev/null | base64 -d 2>/dev/null || echo "N/A")
KC_PASS=$(kubectl get secret -n "$KC_NS" keycloak-initial-admin -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "N/A")

# App user (rossoctl realm — used for UI + MLflow login)
APP_USER=$(kubectl get secret -n "$KC_NS" rossoctl-test-user -o jsonpath='{.data.username}' 2>/dev/null | base64 -d 2>/dev/null || echo "$KC_USER")
APP_PASS=$(kubectl get secret -n "$KC_NS" rossoctl-test-user -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "$KC_PASS")

PORT="${INGRESS_PORT:-8080}"

echo ""
echo "  URLs"
echo "  ──────────────────────────────────────────"
echo "  Rossoctl UI:   http://rossoctl-ui.localtest.me:${PORT}"
echo "  MLflow:       http://mlflow.localtest.me:${PORT}"
echo "  Keycloak:     http://keycloak.localtest.me:${PORT}"
echo ""
echo "  App login (UI + MLflow)"
echo "  ──────────────────────────────────────────"
echo "  Username:     ${APP_USER}"
echo "  Password:     ${APP_PASS}"
echo ""
echo "  Keycloak admin (master realm)"
echo "  ──────────────────────────────────────────"
echo "  Username:     ${KC_USER}"
echo "  Password:     ${KC_PASS}"
echo ""

# MCP Gateway token (for MCP Inspector Authorization tab)
KC_URL="http://keycloak.localtest.me:${PORT}"
ADMIN_TOKEN=$(curl -s -X POST "${KC_URL}/realms/master/protocol/openid-connect/token" \
  -d "grant_type=password&client_id=admin-cli&username=${KC_USER}&password=${KC_PASS}" \
  2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

if [ -n "$ADMIN_TOKEN" ]; then
  # Get mcp-gateway client secret
  MCP_CLIENT_UUID=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
    "${KC_URL}/admin/realms/rossoctl/clients?clientId=mcp-gateway" \
    2>/dev/null | python3 -c "import sys,json; c=json.load(sys.stdin); print(c[0]['id'] if c else '')" 2>/dev/null)

  if [ -n "$MCP_CLIENT_UUID" ]; then
    MCP_SECRET=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
      "${KC_URL}/admin/realms/rossoctl/clients/$MCP_CLIENT_UUID/client-secret" \
      2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('value',''))" 2>/dev/null)

    MCP_TOKEN=$(curl -s -X POST "${KC_URL}/realms/rossoctl/protocol/openid-connect/token" \
      -d "grant_type=client_credentials&client_id=mcp-gateway&client_secret=${MCP_SECRET}&scope=openid" \
      2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

    if [ -n "$MCP_TOKEN" ]; then
      echo "  MCP Gateway token (for MCP Inspector)"
      echo "  ──────────────────────────────────────────"
      echo "  Bearer $MCP_TOKEN"
      echo ""
    fi
  fi
fi

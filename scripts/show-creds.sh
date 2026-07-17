#!/usr/bin/env bash
# Show admin credentials and service URLs for the demo cluster.
set -euo pipefail

KC_NS="keycloak"

# Keycloak admin (master realm)
KC_USER=$(kubectl get secret -n "$KC_NS" keycloak-initial-admin -o jsonpath='{.data.username}' 2>/dev/null | base64 -d 2>/dev/null || echo "N/A")
KC_PASS=$(kubectl get secret -n "$KC_NS" keycloak-initial-admin -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "N/A")

# App user (kagenti realm — used for UI + MLflow login)
APP_USER=$(kubectl get secret -n "$KC_NS" kagenti-test-user -o jsonpath='{.data.username}' 2>/dev/null | base64 -d 2>/dev/null || echo "$KC_USER")
APP_PASS=$(kubectl get secret -n "$KC_NS" kagenti-test-user -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || echo "$KC_PASS")

PORT="${INGRESS_PORT:-8080}"

echo ""
echo "  URLs"
echo "  ──────────────────────────────────────────"
echo "  Kagenti UI:   http://kagenti-ui.localtest.me:${PORT}"
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

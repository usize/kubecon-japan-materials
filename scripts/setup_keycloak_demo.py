#!/usr/bin/env python3
"""Keycloak setup for the Kubecon Japan finance-news-agent demo.

Replaces the old SPARC-demo keycloak script. Idempotent. Run AFTER the
finance-news-agent is deployed (the operator auto-registers the agent's
Keycloak client at admission; scopes can only be assigned to a client
that exists).

Creates/assigns:
  1. Audience scope `agent-team1-finance-news-agent-aud` — puts the agent's
     SPIFFE id in the token `aud`, so scripted (ROPC) calls pass the agent
     sidecar's inbound jwt-validation. Assigned as DEFAULT on the ROPC client.
     (The rossoctl UI mints agent-audienced tokens via its own exchange, so
     browser chats don't need this.)
  2. Public direct-access (ROPC) client `finance-news-e2e` — scripted
     end-to-end tests without a browser.
  3. Demo user alice/alice123.
  4. Client `mcp-gateway` — the audience the MCP Gateway's RequestAuthentication
     enforces (audiences: ["mcp-gateway"]). AuthBridge's outbound token-exchange
     requests audience=mcp-gateway; Keycloak puts it in the exchanged token's
     `aud`.
  5. Optional client scope `mcp-gateway-aud` (audience mapper → mcp-gateway),
     assigned as OPTIONAL on the agent's registered client so token-exchange
     grants with scope="openid mcp-gateway-aud" succeed.

Run via:
  uv run --no-project --with python-keycloak python scripts/setup_keycloak_demo.py

Env overrides: KEYCLOAK_URL, KEYCLOAK_REALM, KEYCLOAK_ADMIN_USERNAME,
KEYCLOAK_ADMIN_PASSWORD, NAMESPACE, AGENT_SA, SPIFFE_TRUST_DOMAIN,
ROPC_CLIENT_ID, GATEWAY_CLIENT_ID.
"""
import os
import sys

from keycloak import KeycloakAdmin

KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://keycloak.localtest.me:8080")
KEYCLOAK_REALM = os.environ.get("KEYCLOAK_REALM", "rossoctl")
ADMIN_USER = os.environ.get("KEYCLOAK_ADMIN_USERNAME", "admin")
ADMIN_PASS = os.environ.get("KEYCLOAK_ADMIN_PASSWORD", "admin")
NAMESPACE = os.environ.get("NAMESPACE", "team1")
AGENT_SA = os.environ.get("AGENT_SA", "finance-news-agent")
SPIFFE_TRUST_DOMAIN = os.environ.get("SPIFFE_TRUST_DOMAIN", "localtest.me")
ROPC_CLIENT_ID = os.environ.get("ROPC_CLIENT_ID", "finance-news-e2e")
GATEWAY_CLIENT_ID = os.environ.get("GATEWAY_CLIENT_ID", "mcp-gateway")
USER_NAME = "alice"
USER_PASS = "alice123"
USER = {"username": USER_NAME, "email": "alice@example.com",
        "enabled": True, "emailVerified": True, "firstName": "Alice", "lastName": "Demo"}

AGENT_SPIFFE = f"spiffe://{SPIFFE_TRUST_DOMAIN}/ns/{NAMESPACE}/sa/{AGENT_SA}"
AGENT_AUD_SCOPE = f"agent-{NAMESPACE}-{AGENT_SA}-aud"
GATEWAY_AUD_SCOPE = "mcp-gateway-aud"


def get_or_create_scope(kc, name, audience):
    scope_id = next((s["id"] for s in kc.get_client_scopes() if s["name"] == name), None)
    if not scope_id:
        scope_id = kc.create_client_scope({
            "name": name, "protocol": "openid-connect",
            "attributes": {"include.in.token.scope": "true",
                           "display.on.consent.screen": "false"},
        }, skip_exists=True)
    print(f"  client scope {name} -> {scope_id}")
    try:
        kc.add_mapper_to_client_scope(scope_id, {
            "name": name + "-mapper", "protocol": "openid-connect",
            "protocolMapper": "oidc-audience-mapper",
            "config": {"included.custom.audience": audience,
                       "id.token.claim": "false", "access.token.claim": "true"},
        })
    except Exception as e:
        print(f"  (mapper exists or: {e})")
    return scope_id


def add_scope(kc, client_internal_id, scope_id, kind, label):
    try:
        if kind == "default":
            kc.add_client_default_client_scope(client_internal_id, scope_id, {})
        else:
            kc.add_client_optional_client_scope(client_internal_id, scope_id, {})
        print(f"  added {kind} scope on {label}")
    except Exception as e:
        print(f"  ({label} {kind} scope: {e})")


def main() -> int:
    print(f"Keycloak: {KEYCLOAK_URL}  realm={KEYCLOAK_REALM}")
    print(f"Agent SPIFFE id: {AGENT_SPIFFE}")

    kc = KeycloakAdmin(server_url=KEYCLOAK_URL, username=ADMIN_USER, password=ADMIN_PASS,
                       realm_name=KEYCLOAK_REALM, user_realm_name="master")

    # 1) Agent audience scope (inbound jwt-validation for scripted calls)
    agent_scope_id = get_or_create_scope(kc, AGENT_AUD_SCOPE, AGENT_SPIFFE)

    # 2) Public ROPC client for scripted end-to-end drives
    if not kc.get_client_id(ROPC_CLIENT_ID):
        kc.create_client({"clientId": ROPC_CLIENT_ID, "name": "finance-news E2E (direct access)",
                          "enabled": True, "publicClient": True, "standardFlowEnabled": True,
                          "directAccessGrantsEnabled": True}, skip_exists=True)
    ropc_internal = kc.get_client_id(ROPC_CLIENT_ID)
    print(f"  ROPC client {ROPC_CLIENT_ID} -> {ropc_internal}")
    add_scope(kc, ropc_internal, agent_scope_id, "default", "ROPC client")

    # 3) Demo user
    user_id = next((u["id"] for u in kc.get_users({"username": USER_NAME})
                    if u["username"] == USER_NAME), None)
    if not user_id:
        user_id = kc.create_user(USER)
    kc.set_user_password(user_id, USER_PASS, temporary=False)
    print(f"  user {USER_NAME}/{USER_PASS} -> {user_id}")

    # 4) mcp-gateway audience client (token-exchange target; also what the
    #    gateway's RequestAuthentication checks in `aud`)
    if not kc.get_client_id(GATEWAY_CLIENT_ID):
        kc.create_client({"clientId": GATEWAY_CLIENT_ID, "name": "MCP Gateway (audience)",
                          "enabled": True, "publicClient": False,
                          "standardFlowEnabled": False,
                          "serviceAccountsEnabled": True}, skip_exists=True)
    gw_internal = kc.get_client_id(GATEWAY_CLIENT_ID)
    print(f"  gateway audience client {GATEWAY_CLIENT_ID} -> {gw_internal}")

    # 5) Gateway audience scope, OPTIONAL on the agent's registered client so
    #    explicit scope="openid mcp-gateway-aud" grants succeed
    gw_scope_id = get_or_create_scope(kc, GATEWAY_AUD_SCOPE, GATEWAY_CLIENT_ID)
    for candidate in (AGENT_SPIFFE, AGENT_SA):
        agent_internal = kc.get_client_id(candidate)
        if agent_internal:
            print(f"  agent client found: {candidate}")
            add_scope(kc, agent_internal, gw_scope_id, "optional", "agent client")
            break
    else:
        print(f"  WARNING: agent client not found (tried {AGENT_SPIFFE!r}, {AGENT_SA!r}).")
        print("           Is finance-news-agent deployed? Re-run after deployment.")

    print("Keycloak demo setup complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

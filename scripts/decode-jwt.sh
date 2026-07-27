#!/usr/bin/env bash
# ============================================================================
# Decode and pretty-print a JWT token's header and payload.
# Usage:
#   ./scripts/decode-jwt.sh <token>
#   ./scripts/decode-jwt.sh            # reads from stdin
#   pbpaste | ./scripts/decode-jwt.sh  # paste from clipboard
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TOKEN="${1:-$(cat)}"
TOKEN="${TOKEN#Bearer }"  # strip "Bearer " prefix if present
TOKEN="${TOKEN// /}"      # strip whitespace

if [[ -z "$TOKEN" || "$TOKEN" != *.*.* ]]; then
  echo "Usage: $0 <jwt-token>" >&2
  exit 1
fi

python3 - "$TOKEN" <<'PYEOF'
import sys, base64, json
from datetime import datetime, timezone

token = sys.argv[1]
parts = token.split(".")

def decode_part(s):
    s += "=" * (4 - len(s) % 4)
    return json.loads(base64.urlsafe_b64decode(s))

header = decode_part(parts[0])
payload = decode_part(parts[1])

C = "\033[0;36m"   # cyan
Y = "\033[0;33m"   # yellow
G = "\033[0;32m"   # green
B = "\033[1m"      # bold
D = "\033[0;90m"   # dim
N = "\033[0m"      # reset

print()
print(f"{C}{'═' * 60}{N}")
print(f"{C}  {B}JWT Header{N}")
print(f"{C}{'═' * 60}{N}")
print(f"  {Y}alg{N}  {header.get('alg', '?')}")
print(f"  {Y}typ{N}  {header.get('typ', '?')}")
if "kid" in header:
    print(f"  {Y}kid{N}  {header['kid']}")

print()
print(f"{C}{'═' * 60}{N}")
print(f"{C}  {B}JWT Payload{N}")
print(f"{C}{'═' * 60}{N}")

# Key fields in a meaningful order
KEY_ORDER = ["iss", "sub", "aud", "azp", "scope", "typ",
             "preferred_username", "email",
             "realm_access", "resource_access",
             "iat", "exp", "jti"]

def fmt_time(ts):
    dt = datetime.fromtimestamp(ts, tz=timezone.utc)
    return f"{dt.strftime('%Y-%m-%d %H:%M:%S UTC')}"

def fmt_value(k, v):
    if k in ("iat", "exp") and isinstance(v, (int, float)):
        remaining = ""
        if k == "exp":
            delta = v - datetime.now(timezone.utc).timestamp()
            if delta > 0:
                mins = int(delta) // 60
                secs = int(delta) % 60
                remaining = f"  {D}({mins}m {secs}s remaining){N}"
            else:
                remaining = f"  \033[0;31m(EXPIRED)\033[0m"
        return f"{fmt_time(v)}{remaining}"
    if isinstance(v, list):
        if len(v) == 1:
            return str(v[0])
        lines = [f"{G}{item}{N}" for item in v]
        return "\n         ".join(lines)
    if isinstance(v, dict):
        return json.dumps(v, indent=2).replace("\n", "\n         ")
    return str(v)

shown = set()
for k in KEY_ORDER:
    if k in payload:
        shown.add(k)
        label = f"  {Y}{k:<5}{N}"
        print(f"{label}{fmt_value(k, payload[k])}")

# Any remaining fields
remaining = {k: v for k, v in payload.items() if k not in shown}
if remaining:
    print(f"\n  {D}── other ──{N}")
    for k, v in remaining.items():
        label = f"  {Y}{k:<5}{N}"
        print(f"{label}{fmt_value(k, payload[k])}")

print(f"\n{C}{'═' * 60}{N}")
sig_preview = parts[2][:20]
print(f"  {Y}sig{N}  {D}{sig_preview}...{N}  ({len(parts[2])} chars)")
print(f"{C}{'═' * 60}{N}")
print()
PYEOF

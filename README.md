# Fintech Demo — Kubecon Japan

End-to-end demo showing four infrastructure patterns for running agentic AI on Kubernetes, using a financial agent as the through-line.

## What it shows

| Stage | Pattern | What you see |
|-------|---------|-------------|
| 0 | Platform Setup | Kind cluster + kagenti stack (SPIRE, MCP Gateway, UI, MLflow) |
| 1 | Tool Aggregation | Multiple MCP backends behind one gateway endpoint |
| 2 | Workload Identity | SPIFFE auto-injection, trusted vs untrusted contrast |
| 3 | Happy Path | Live financial query through the full stack |
| 4a | Argument Grounding | SPARC catches hallucinated tool arguments |
| 4b | Intent Verification | IBAC blocks prompt-injection exfiltration |

## Prerequisites

- `kind`, `kubectl`, `helm` (v3)
- `docker` or `podman`
- `make`, `python3`, `uv`
- Ollama on the host with models pulled (for SPARC/IBAC LLM judges)

## Quick start

```bash
# Full demo (creates cluster, runs all stages)
./scripts/demo.sh

# Reuse existing cluster
./scripts/demo.sh --skip-platform

# Start from a specific stage (assumes earlier stages completed)
./scripts/demo.sh --skip-platform --start-from 3

# Run individual stages
./scripts/0-platform.sh
./scripts/1-tools.sh
./scripts/2-identity.sh
./scripts/3-happy-path.sh
./scripts/4a-sparc.sh
./scripts/4b-ibac.sh

# Cleanup
./scripts/teardown.sh                  # Remove demo workloads
./scripts/teardown.sh --destroy-cluster # Also delete the Kind cluster
```

## How it works

Each script uses `set -eux` for full command visibility and pauses at key moments for the presenter to narrate. The master `demo.sh` chains all stages with inter-stage pauses.

Stage 4a/4b delegate to existing Makefiles in the SPARC and IBAC demo directories rather than duplicating commands. The `fintech-demo/k8s/` manifests handle MCP Gateway registration.

## Directory layout

```
fintech-demo/
├── README.md
├── kubecon-japan-demo-playbook.md    # Full demo playbook
├── env.sh                            # Shared environment defaults
├── scripts/
│   ├── lib.sh                        # Shared helpers (colors, pause, banner)
│   ├── 0-platform.sh                 # Kind cluster + platform stack
│   ├── 1-tools.sh                    # Build/deploy MCP tools + gateway registration
│   ├── 2-identity.sh                 # SPIFFE identity, trusted/untrusted contrast
│   ├── 3-happy-path.sh              # Live query + MLflow traces
│   ├── 4a-sparc.sh                  # Argument grounding (before/after)
│   ├── 4b-ibac.sh                   # Intent verification (before/after)
│   ├── demo.sh                      # Master orchestrator
│   └── teardown.sh                  # Cleanup
└── k8s/
    ├── finance-tool-deployment.yaml  # Market data server (placeholder)
    ├── finance-tool-httproute.yaml   # Gateway API HTTPRoute
    ├── finance-tool-registration.yaml # MCPServerRegistration (market_)
    ├── finance-mcp-httproute.yaml    # Gateway API HTTPRoute
    ├── finance-mcp-registration.yaml # MCPServerRegistration (txn_)
    └── untrusted-pod.yaml           # Curl pod with no SPIFFE
```

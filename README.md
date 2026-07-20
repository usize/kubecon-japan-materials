# Securing Agentic AI at the Infrastructure Layer

Demo materials for the Kubecon Japan 2026 talk on identity, authorization, and runtime guardrails for agentic systems.

## Running the demo

### Prerequisites

- `kind`, `kubectl`, `helm` (v3)
- `docker` or `podman`
- `make`, `python3`, `uv`
- [Ollama](https://ollama.com) running on the host with `llama3.2:3b` pulled

```bash
ollama pull llama3.2:3b
```

### Quick start

```bash
# Full demo — creates Kind cluster, installs platform, runs all stages
bash scripts/demo.sh

# Skip cluster creation (reuse existing)
bash scripts/demo.sh --skip-platform

# Jump to a specific stage (assumes earlier stages completed)
bash scripts/demo.sh --skip-platform --start-from 3
```

Each stage pauses for Enter at key moments. Press Enter to advance, Ctrl-C to stop.

### Individual stages

| Script | What it does |
|--------|-------------|
| `scripts/0-platform.sh` | Creates a Kind cluster and installs the kagenti platform (SPIRE, Keycloak, MCP Gateway, MLflow, UI) |
| `scripts/1-tools.sh` | Builds and deploys MCP tool servers, registers them with the MCP Gateway |
| `scripts/2-identity.sh` | Deploys the agent with SPIFFE identity, contrasts with an untrusted pod |
| `scripts/3-happy-path.sh` | Configures auth, guides a live financial query through the UI |
| `scripts/4a-mlflow-judge.sh` | Deploys the news agent with OTEL tracing, runs the injection scenario, evaluates with a custom MLflow judge |
| `scripts/4b-ibac.sh` | Shows the same injection blocked in real-time by the IBAC sidecar plugin |

### Utility scripts

| Script | What it does |
|--------|-------------|
| `scripts/show-creds.sh` | Prints service URLs and login credentials for the running cluster |
| `scripts/demo-mcp-auth.sh` | Demonstrates MCP Gateway auth enforcement (no-token vs valid-token) |
| `scripts/teardown.sh` | Removes demo workloads (add `--destroy-cluster` to delete the Kind cluster) |

### Platform source

The platform is installed from a fork of [kagenti/kagenti](https://github.com/kagenti/kagenti) with a fix for the MLflow scorer job runner ([#1605](https://github.com/kagenti/kagenti/issues/1605)). The `env.sh` file auto-clones from `usize/kagenti` on the `fix/mlflow-scorer-job-runner` branch if `thirdparty/kagenti` is not present.

## Talk narrative

**Part One — Establishing a secure baseline.** Agents need robust global identity. We use SPIFFE/SPIRE for cryptographic workload identity and Keycloak for token exchange, enforcing authorization via mTLS across a trust domain. The MCP Gateway aggregates tool servers behind a single authenticated endpoint.

**Part Two — Demonstrating the unique failure mode.** Identity and access control are necessary but not sufficient. A prompt injection hidden in a news article tricks the agent into exfiltrating data — the attack succeeds despite the agent having proper identity. MLflow captures the full trace.

**Part Three — Closing the loop.** We use MLflow's built-in judges to score the agent's behavior post-hoc, detecting the injection in recorded traces. Then we apply the same judge logic as a real-time guardrail (IBAC sidecar plugin) that blocks the exfiltration before it leaves the pod. No agent code changes — infrastructure handles it.

## Slide deck

Slides are in `slides.md` (Marp format).

```bash
npm install
npm run serve      # Live preview with hot-reload
npm run build      # Build static site to docs/
npm run build:pdf  # Export to PDF
```

## Directory layout

```
├── env.sh                           # Shared environment (auto-clones kagenti)
├── slides.md                        # Talk slides (Marp)
├── kubecon-japan-demo-playbook.md   # Detailed demo playbook
├── scripts/
│   ├── demo.sh                     # Master orchestrator
│   ├── 0-platform.sh .. 4b-ibac.sh # Stage scripts
│   ├── show-creds.sh               # Credential helper
│   ├── demo-mcp-auth.sh            # MCP Gateway auth demo
│   ├── mlflow-judge/run_judge.py   # Custom prompt injection judge
│   └── lib.sh                      # Shared helpers (colors, pause)
├── finance-ibac/                    # IBAC demo (agent, news server, tainted server)
├── k8s/                            # Kubernetes manifests (MCP registrations, auth policies)
├── thirdparty/                     # Auto-cloned dependencies (gitignored)
│   ├── kagenti/                    # Platform (usize/kagenti fork)
│   └── kagenti-extensions/         # AuthBridge, demos
└── docs/                           # Static site (GitHub Pages)
```

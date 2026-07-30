🇯🇵 [日本語版READMEはこちら](README.ja.md)

# Architecting Secure Agentic Workflows on Kubernetes

Demo materials for the KubeCon Japan 2026 talk on identity, authorization, and runtime guardrails for agentic AI systems.

[![Built on Rossoctl](images/rossoctl.png)](https://github.com/rossoctl/rossoctl)

Built on the [Rossoctl](https://github.com/rossoctl/rossoctl) agent platform.

## Prerequisites

- `kind`, `kubectl`, `helm` (v3)
- `docker` or `podman`
- `make`, `python3`, `uv`
- [Ollama](https://ollama.com) running on the host with `llama3.2:3b` pulled

```bash
ollama pull llama3.2:3b
```

## Running the demo

A single script walks through the entire demo step by step. It creates a Kind cluster, installs the platform, and runs each stage in sequence — pausing for Enter at key moments so you can follow along.

```bash
bash scripts/demo.sh
```

The stages are:

1. **Platform** — Creates a Kind cluster and installs SPIRE, Keycloak, MCP Gateway, MLflow, and the Rossoctl UI.
2. **Tool servers** — Builds and deploys the MCP tool backends (market data, transactions, news) and registers them with the gateway.
3. **Identity** — Deploys the agent with a SPIFFE identity and shows that an untrusted pod is rejected.
4. **Happy path** — Configures auth and walks through a live financial query via the UI.
5. **Prompt injection + MLflow judge** — Deploys a news-capable agent, demonstrates a prompt injection attack, and evaluates the trace with a custom MLflow judge.
6. **IBAC guardrail** — Replays the same attack, now blocked in real-time by the IBAC sidecar plugin.

If you already have a cluster running, you can skip platform setup or jump to a specific stage:

```bash
bash scripts/demo.sh --skip-platform
bash scripts/demo.sh --skip-platform --start-from 3
```

To tear everything down:

```bash
bash scripts/teardown.sh               # Remove demo workloads
bash scripts/teardown.sh --destroy-cluster  # Also delete the Kind cluster
```

## Talk narrative

**Part One — Establishing a secure baseline.** Agents need robust global identity. We use SPIFFE/SPIRE for cryptographic workload identity and Keycloak for token exchange, enforcing authorization via mTLS across a trust domain. The MCP Gateway aggregates tool servers behind a single authenticated endpoint.

**Part Two — Demonstrating the unique failure mode.** Identity and access control are necessary but not sufficient. A prompt injection hidden in a news article tricks the agent into exfiltrating data — the attack succeeds despite the agent having proper identity. MLflow captures the full trace.

**Part Three — Closing the loop.** We use MLflow's custom judges to score the agent's behavior post-hoc, detecting the injection in recorded traces. Then we apply the same judge logic as a real-time guardrail (IBAC sidecar plugin) that blocks the exfiltration before it leaves the pod. No agent code changes — infrastructure handles it.

## Platform source

The platform is installed from a fork of [rossoctl/rossoctl](https://github.com/rossoctl/rossoctl) with a fix for the MLflow scorer job runner ([#1605](https://github.com/rossoctl/rossoctl/issues/1605)). The `env.sh` file auto-clones from `usize/rossoctl` on the `fix/mlflow-scorer-job-runner-v2` branch if `thirdparty/rossoctl` is not present.

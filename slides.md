---
marp: true
theme: default
paginate: true
style: |
  @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600&family=IBM+Plex+Mono:wght@300;400;500&display=swap');
  /* Rossoctl — dark theme: red, black, gold, warm white */
  :root {
    --bg: #0e0e0e;
    --bg-surface: #161616;
    --bg-raised: #1e1e1e;
    --red: #c0272d;
    --red-light: #e8584f;
    --gold: #d4a843;
    --gold-dim: #a68832;
    --amber: #f5c96a;
    --text: #e8e4df;
    --text-mid: #b0aaa2;
    --text-dim: #706b64;
    --white: #fff;
    --code-green: #7ec699;
  }
  section {
    font-family: 'IBM Plex Sans', 'Helvetica Neue', sans-serif;
    font-size: 26px;
    font-weight: 400;
    color: var(--text);
    background: var(--bg);
    padding: 40px 60px;
    letter-spacing: 0.01em;
  }
  /* Lead / title slides */
  section.lead {
    text-align: center;
    background: linear-gradient(160deg, #0a0a0a 0%, #111 40%, #1a0808 100%);
    color: var(--white);
  }
  section.lead h1 {
    font-size: 46px;
    font-weight: 400;
    margin-bottom: 8px;
    color: var(--white);
    letter-spacing: -0.01em;
  }
  section.lead h2 {
    font-size: 26px;
    font-weight: 300;
    color: var(--gold);
    margin-top: 0;
  }
  section.lead p {
    color: var(--text-mid);
    font-size: 22px;
  }
  /* Headings */
  h1 {
    color: var(--white);
    font-size: 34px;
    font-weight: 500;
    margin-bottom: 16px;
    letter-spacing: -0.01em;
  }
  h2 {
    color: var(--gold);
    font-size: 28px;
    font-weight: 400;
  }
  h3 {
    font-weight: 500;
    font-size: 24px;
    color: var(--text);
  }
  /* Text styles */
  strong {
    font-weight: 600;
    color: var(--white);
  }
  em {
    color: var(--red-light);
    font-style: normal;
    font-weight: 500;
  }
  a {
    color: var(--gold);
  }
  li {
    color: var(--text);
  }
  /* Blockquotes */
  blockquote {
    border-left: 3px solid var(--red);
    padding: 8px 16px;
    background: var(--bg-raised);
    font-style: italic;
    margin: 16px 0;
    color: var(--text-mid);
  }
  /* Tables */
  table {
    font-size: 20px;
    width: 100%;
  }
  th {
    background: var(--red);
    color: var(--white);
    padding: 8px 12px;
    font-weight: 500;
    letter-spacing: 0.02em;
  }
  td {
    padding: 8px 12px;
    border-bottom: 1px solid #2a2a2a;
    color: var(--text);
  }
  tr:nth-child(even) td {
    background: var(--bg-raised);
  }
  tr:nth-child(odd) td {
    background: var(--bg-surface);
  }
  /* Code */
  code {
    font-family: 'IBM Plex Mono', 'Menlo', monospace;
    font-size: 18px;
    font-weight: 400;
    background: var(--bg-raised);
    color: var(--amber);
    padding: 2px 6px;
    border-radius: 3px;
  }
  pre {
    font-size: 16px;
    background: var(--bg-surface);
    color: var(--code-green);
    padding: 16px;
    border-radius: 8px;
    border: 1px solid #2a2a2a;
  }
  pre code {
    background: none;
    padding: 0;
    color: inherit;
    font-weight: 400;
  }
  /* Layout */
  .columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
  }
  .highlight {
    color: var(--red);
    font-weight: 600;
  }
  .subtle {
    color: var(--text-dim);
    font-size: 20px;
  }
  /* Pagination */
  section::after {
    color: var(--text-dim);
  }
  /* Demo slides */
  section.demo {
    background: var(--bg);
  }
  section.demo h1 {
    display: none;
  }
  section.demo em {
    color: var(--red-light);
  }
  section.demo code {
    background: var(--bg-raised);
    color: var(--amber);
  }
  section.demo pre, section.demo pre code {
    background: var(--bg-surface);
    color: var(--code-green);
  }
  section.demo blockquote {
    background: var(--bg-raised);
    border-left-color: var(--red);
  }
  .demo-header {
    display: flex;
    align-items: center;
    gap: 14px;
    margin-bottom: 12px;
  }
  .demo-label {
    display: inline-block;
    background: var(--red);
    color: var(--white);
    padding: 4px 14px;
    border-radius: 3px;
    font-family: 'IBM Plex Mono', monospace;
    font-size: 13px;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 2px;
    flex-shrink: 0;
  }
  .demo-title {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 13px;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: var(--text-mid);
  }
---

<!-- _class: lead -->

# Securing Agentic AI at the Infrastructure Layer

## Identity, Authorization, and Runtime Guardrails

<br>

**Vincent Caldeira** — APAC CTO
**Morgan Foster** — Senior Principal Software Engineer

KubeCon Japan 2026

<!--
Welcome. Today we're going to talk about securing agentic AI workloads — not at the application layer, but at the infrastructure layer. Using Kubernetes, CNCF projects, and open standards. With live demos. No agent code was harmed in the making of this talk.
-->

---

# "Agents are workloads. But they break our assumptions."

- **Traditional workloads:** request in, response out, deterministic
- **Agents:** reason, discover tools, take autonomous actions

Running agentic workloads in production introduces new infrastructure challenges:

| Challenge | Question |
|-----------|----------|
| **Tool discovery & access** | How does the agent find and call tools securely? |
| **Workload identity** | Who is this agent, and what is it allowed to do? |
| **Inter-agent communication** | How do agents talk to each other safely? |
| **Runtime guardrails** | The agent is authorized — but is it doing the right thing? |

<!--
Every platform team running agents in production hits these questions. Today we'll show how to solve them at the infrastructure layer — using Kubernetes, CNCF projects, and open standards. No agent code changes.
-->

---

# Reference Architecture at a Glance 

<div class="columns">
<div>

**Platform Namespace** - Identity provider(s), Agent lifecycle management and inference.
```
+----------------------------+
|  Rossoctl Operator         |
|  SPIRE Server              |
|  Keycloak                  |
|  Ollama                    |
+----------------------------+
```

**MCP Gateway** - three finance relevant tool servers behind a single control plane.
```
+----------------------------+
|  market-data  (finance)    |
|  transactions (refunds)    |
|  news         (articles)   |
+----------------------------+
```

</div>
<div>

**Agent Namespace** - Agents deployed here are managed and added to our trust domain.
```
+--------------------------------+
|  Finance Agent Pod             |
|  +--------+ +--------------+  |
|  |        | | RossoCortex  |  |
|  |        | |   sidecar    |  |
|  |        | | +---------+  |  |
|  | Agent  | | |inbound  |  |  |
|  |        | | |pipeline |  |  |
|  |        | | +---------+  |  |
|  |        | | |outbound |  |  |
|  |        | | |pipeline |  |  |
|  |        | | +---------+  |  |
|  +--------+ +--------------+  |
|  SPIFFE Identity               |
+--------------------------------+
 ```

</div>
</div>

<!--
The agent is a regular pod. The operator injects a sidecar — RossoCortex — that handles identity, token exchange, and guardrails. The MCP Gateway aggregates tool backends behind a single endpoint. Communication uses two open protocols: A2A for agent-to-agent messaging, MCP for tool access. The platform also supports building agents from git via Tekton — develop, deploy, and secure from one cluster.
-->

---

# Zero-Trust Workload Identity

Every agent pod gets a **SPIFFE ID** at birth:

```
spiffe://trust-domain/ns/team1/sa/finance-agent
```

X.509 SVID — auto-rotated — bound to service account

<div class="columns">
<div>

### Inbound (AuthN)
- JWT validation on every request
- Reject unauthenticated callers
- No identity == no access

</div>
<div>

### Outbound (Token Exchange)
- SPIFFE credential becomes scoped JWT 
- Injected per-backend automatically == auth without token management 

</div>
</div>

<br>

**No API keys. No shared secrets. All auth policy is configuration, not code.**

<!--
SPIFFE gives the agent a cryptographic identity. The sidecar uses it for mTLS and token exchange. The agent binary never touches a credential. And if a workload doesn't have identity, it doesn't get in — we'll show that in a moment.
-->

---

# Our Networking Layer Understands A2A and MCP

```
Inbound (A2A):                  Outbound (MCP / HTTP):

+----------------+              +------------------+
| a2a-parser     | -> captures  | token-exchange   | -> injects auth
|                |    intent    |                  |
+----------------+              +------------------+
| jwt-validation | -> authN     | inference-parser | -> captures LLM
|                |              |                  |    reasoning
+----------------+              +------------------+
                                | mcp-parser       | -> captures tool
                                |                  |    calls
                                +------------------+
                                | guardrail plugin | -> evaluates
                                +------------------+
```

- Not just an API Gateway -- it **parses A2A and MCP protocol traffic**
- This means guardrail plugins have *full semantic context*

<!--
This is the key design point. Because the sidecar understands the protocols — A2A for inter-agent communication, MCP for tool calls — it can make semantic decisions, not just network-level ones. It knows what the user asked for and what the agent is trying to do. And the pipeline is composable — you add or remove guardrails with a config change.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">MCP Gateway</span></div>

<video controls src="videos/01-mcp-gateway.mp4" muted width="100%"></video>

<!--
This is the MCP Gateway — a CNCF project from Kuadrant. It federates multiple tool backends behind a single endpoint. Three backends registered: market data, transactions, and news. The agent connects to one URL and discovers all 10 tools automatically.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Deploying an Agent</span></div>

<video controls src="videos/02-deploy-agent-spiffe.mp4" muted width="100%"></video>

<!--
Deploy from the UI: set namespace, image, enable the RossoCortex sidecar and SPIRE identity, configure the token exchange route. The agent starts as 2/2 — agent plus sidecar. Show the SPIFFE ID via kubectl exec — a cryptographic identity issued automatically at pod birth.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Zero-Trust Rejection</span></div>

<video controls src="videos/03-untrusted-pod-rejected.mp4" muted width="100%"></video>

<!--
An untrusted pod — no sidecar, no SPIFFE identity — tries to call the agent. Rejected with 401: missing Authorization header. If you don't have cryptographic identity, you don't get in.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">The Happy Path</span></div>

<video controls src="videos/04-happy-path.mp4" muted width="100%"></video>

<!--
The full stack working end-to-end. A2A request in, JWT validated, LLM reasons, MCP tool call out through the gateway, token injected automatically. Now let's see what can go wrong.
-->

---

# The Agent Is Authorized. But Is It Doing the Right Thing?

This is the key difference in Agentic systems. Runtime behaviors are unpredictable. 


| Threat | What happens | OWASP Agentic AI |
|--------|-------------|-----------------|
| **Hallucinated arguments** | Agent fabricates data sent to APIs | #3: Missing Guardrails |
| **Prompt injection** | Poisoned data hijacks agent actions | #1: Excessive Agency |

<br>

- Both **bypass authentication** — the agent IS who it says it is
- Both require **semantic understanding** to detect
- Both can be caught at the **infrastructure layer**

<!--
These aren't authentication failures. The agent's identity is valid. Its token is valid. The problem is what the agent DOES with its valid access. We need guardrails, but each threat has a different shape — so each guardrail works differently.
-->

---

# Observability First, Then Guardrails

**Insight**: Before adding runtime guardrails, establish observability — you can't guard what you can't see.


| | **MLflow Judge** (Post-Hoc) | **IBAC** (Real-Time) |
|---|---|---|
| **When** | After the trace is recorded | Before the request leaves the pod |
| **How** | Custom `make_judge()` evaluates traces | Sidecar plugin evaluates every outbound call |
| **Detects** | Prompt injection patterns in recorded behavior | Actions misaligned with user intent |
| **Action** | Flags for review — generates verdict + rationale | Blocks the request (403) |

<br>

Same LLM judge concept. Different enforcement point.
**From detection to prevention.**

<!--
We're going to show two approaches to the same problem — prompt injection. First, MLflow observability with a custom judge that detects injection after the fact. Then, the IBAC sidecar plugin that blocks it in real-time. Same LLM judge concept, different enforcement points. Detection first, then prevention.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">MLflow Traces — Injection Succeeds</span></div>

- Deploy agent with **OTEL/MLflow tracing** — traces route to `team1` experiment
- Ask: *"What's the latest news about AAPL?"*
- Poisoned news article triggers exfiltration — **no guardrails, attack succeeds**
- Open **MLflow UI** — full trace visible: LLM reasoning, tool calls, exfiltration POST

> The trace captured everything. The attack is visible — but it already happened.

<!--
We deployed the agent with OTEL env vars that route traces to a named MLflow experiment. The attack succeeded — portfolio data was exfiltrated. But MLflow recorded the entire trace. We can see every tool call, every LLM decision, the exfiltration POST. Observability captured the attack chain. Now let's analyze it.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Custom Judge Detects Injection</span></div>

- `mlflow.genai.judges.make_judge()` — custom prompt injection detector
- Runs against local Ollama (`llama3.2:3b`) — no external API needed
- Fetches latest trace, evaluates agent behavior

**Judge verdict:**
```
Verdict:   injected
Rationale: The agent followed instructions embedded in a news article
           and made an HTTP POST to an unknown server, exfiltrating
           portfolio data the user never requested.
```

> Post-hoc detection works. Next: **real-time blocking with IBAC**.

<!--
We built a custom judge using mlflow make_judge. It fetched the latest trace, examined the inputs and outputs, and classified the interaction as "injected." The judge runs locally on Ollama — no external API calls. This establishes the pattern: an LLM judge evaluating agent behavior. Now let's move that judge to the infrastructure layer, where it can block attacks before they succeed.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">IBAC off — Prompt Injection</span></div>

<video controls src="videos/05-ibac-incident-and-patch.mp4" muted width="100%"></video>

<!--
Every security layer passed. Identity — valid. Token — valid. The attack worked because nothing checked whether the agent's actions matched what the user actually asked for. This video covers the full IBAC flow: incident discovery, analysis, patching the guardrail live, and replaying the attack.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">IBAC on — Prompt Injection</span></div>

*Continues from previous video*

- Apply IBAC pipeline patch live — *no pod restart*
- Replay: "What's the latest news about AAPL?"
- Same poisoned article. Agent tries same exfiltration POST.

**Sidecar verdict:**
```
plugin rejected request   plugin=ibac   status=403   code=ibac.blocked
reason="POSTing data to an unknown external server
        is not aligned with asking about financial news."
```

- Tainted-server logs: **empty** — nothing reached the attacker
- `get_news` → *ibac allow/aligned* | POST → *ibac deny/misaligned*

<!--
The sidecar captured the user's intent from the A2A message on the way in: 'what's the latest news about AAPL.' When the agent tried to POST data to an unknown server, the LLM judge said: that's not aligned. 403. The request never left the pod.
-->

---

# Defense in Depth — Zero Agent Code Changes

| Layer | What it solves | How |
|-------|---------------|-----|
| **MCP Gateway** | Tool discovery & routing | Protocol-aware gateway, unified endpoint |
| **SPIFFE / SPIRE** | Workload identity | Cryptographic identity at pod birth |
| **Token exchange** | Authenticated tool access | Sidecar injects scoped credentials |
| **MLflow + IBAC** | Observability & guardrails | Detect injection post-hoc, block in real-time |

<br>


Importantly, **all configured at the platform level.**

Developers focus on using and building agents, while platform operators enforce security.

<!--
Four layers of defense. A protocol-aware gateway for tool access. Cryptographic identity for zero-trust. Automatic credential injection. And semantic guardrails that understand what the agent is doing. All infrastructure concerns, handled at the infrastructure layer.
-->

---

<!-- _class: lead -->

# Try It, Break It, Tell Us What's Missing

<br>

**Rossoctl** — rossoctl.dev
**RossoCortex + IBAC** - github.com/rossoctl/rossoctl-extensions
**MLflow** - mlflow.org — custom judges via `mlflow.genai.judges`
**MCP Gateway** - CNCF project from Kuadrant

<br>

Everything runs in your K8s cluster - try it today.

<br>

<span class="subtle">Thank you.</span>

<!--
All open source. Spin up a Kind cluster, deploy an agent, try to break the guardrails. We want to know what's missing. Thank you.
-->

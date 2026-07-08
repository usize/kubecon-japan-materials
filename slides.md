---
marp: true
theme: default
paginate: true
style: |
  @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600&family=IBM+Plex+Mono:wght@300;400;500&display=swap');
  /* Rossoctl — red, black, gold, white */
  section {
    font-family: 'IBM Plex Sans', 'Helvetica Neue', sans-serif;
    font-size: 26px;
    font-weight: 400;
    color: #222;
    padding: 40px 60px;
    letter-spacing: 0.01em;
  }
  section.lead {
    text-align: center;
    background: linear-gradient(135deg, #0a0a0a 0%, #1a1a1a 50%, #2a0a0a 100%);
    color: #fff;
  }
  section.lead h1 {
    font-size: 46px;
    font-weight: 400;
    margin-bottom: 8px;
    color: #fff;
    letter-spacing: -0.01em;
  }
  section.lead h2 {
    font-size: 26px;
    font-weight: 300;
    color: #d4a843;
    margin-top: 0;
  }
  section.lead p {
    color: #ddd;
    font-size: 22px;
  }
  section.section-header {
    background: #111;
    color: #fff;
  }
  section.section-header h1 {
    font-size: 40px;
    font-weight: 400;
    border-bottom: 2px solid #c0272d;
    padding-bottom: 12px;
    display: inline-block;
  }
  h1 {
    color: #111;
    font-size: 34px;
    font-weight: 500;
    margin-bottom: 16px;
    letter-spacing: -0.01em;
  }
  h2 {
    color: #222;
    font-size: 28px;
    font-weight: 400;
  }
  h3 {
    font-weight: 500;
    font-size: 24px;
  }
  strong {
    font-weight: 600;
  }
  blockquote {
    border-left: 4px solid #c0272d;
    padding: 8px 16px;
    background: #fdf6f0;
    font-style: italic;
    margin: 16px 0;
    color: #333;
  }
  table {
    font-size: 20px;
    width: 100%;
  }
  th {
    background: #1a1a1a;
    color: #fff;
    padding: 8px 12px;
    font-weight: 500;
    letter-spacing: 0.02em;
  }
  td {
    padding: 8px 12px;
    border-bottom: 1px solid #ddd;
    color: #222;
  }
  code {
    font-family: 'IBM Plex Mono', 'Menlo', monospace;
    font-size: 18px;
    font-weight: 400;
    background: #f5f0eb;
    padding: 2px 6px;
    border-radius: 3px;
  }
  pre {
    font-size: 16px;
    background: #111;
    color: #e8e0d8;
    padding: 16px;
    border-radius: 8px;
  }
  pre code {
    background: none;
    padding: 0;
    color: inherit;
    font-weight: 400;
  }
  .columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24px;
  }
  .highlight {
    color: #c0272d;
    font-weight: 600;
  }
  .subtle {
    color: #999;
    font-size: 20px;
  }
  em {
    color: #c0272d;
    font-style: normal;
    font-weight: 500;
  }
  /* Demo slides — dark bg, force all text white */
  section.demo, section.demo * {
    color: #fff;
  }
  section.demo {
    background: #0e0e0e;
  }
  section.demo h1 {
    display: none;
  }
  section.demo em {
    color: #e8584f;
  }
  section.demo code {
    background: #2a2a2a;
    color: #f5c96a;
    font-weight: 400;
  }
  section.demo pre, section.demo pre code {
    background: #1a1a1a;
    color: #e8e0d8;
  }
  section.demo blockquote {
    background: #1a1a1a;
    border-left-color: #c0272d;
  }
  section.demo blockquote p {
    color: #ddd;
  }
  .demo-header {
    display: flex;
    align-items: center;
    gap: 14px;
    margin-bottom: 12px;
  }
  .demo-label {
    display: inline-block;
    background: #c0272d;
    color: #fff;
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
    color: #fff;
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

# Two Guardrails, Two Shapes

**Insight**: LLM flexibility allows us to guard against runtime anomalies.


| | **SPARC** (Argument Grounding) | **IBAC** (Intent Verification) |
|---|---|---|
| **Parses** | MCP tool calls | A2A user messages |
| **Detects** | Ungrounded tool arguments | Actions misaligned with user intent |
| **Catches** | Agent fabricates data for an API call | Agent follows injected instructions |
| **Action** | Returns clarification instead of executing | Blocks the request (403) |

<br>

Both run as sidecar plugins. Both are hot-reloadable.
**Both live outside the agent.**

<!--
We know guardrails are important — but each guardrail solves a unique problem and has a unique shape. SPARC parses MCP requests and detects bad tool arguments. IBAC parses A2A requests and detects deviations from the user's intent — a good proxy for prompt injection. Let me show you both.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">SPARC off — Hallucinated Arguments</span></div>

*Video TBD*

**User asks:** "Refund my duplicate $450 subscription charge from last week."

- Agent has `issue_refund` tool but *no search/lookup tool*
- It **fabricates a transaction ID** and calls `issue_refund` with a hallucinated value
- The call reaches the API unchecked
- Agent confidently reports "refund processed" with a **made-up ID**

> In production, that's a fabricated argument hitting a real financial API.

<!--
The agent invented a transaction ID. No tool call verified it. In production, that's a fabricated argument hitting a real financial API.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">SPARC on — Hallucinated Arguments</span></div>

*Video TBD*

- Apply SPARC pipeline patch live (`make patch-config`) — *no pod restart*
- Replay: "Refund my $450 charge."

**What happens:**
1. Agent tries fabricated call → SPARC scores **0.00** (ungrounded)
2. Returns *clarification* as tool result instead of executing
3. Agent asks user for the real transaction ID
4. User provides "TX4827" → SPARC scores **1.00** (grounded) → refund succeeds

**Forensic view:** `modify/reflected` → `allow/grounded`

<!--
Same agent, same question. The sidecar parsed the MCP tool call, saw the argument couldn't be traced to the conversation, and returned a clarification instead of executing. The agent got a natural correction loop — no code change, no redeployment.
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
| **SPARC + IBAC** | Runtime guardrails | Parse MCP + A2A traffic, enforce semantically |

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
**RossoCortex + SPARC + IBAC** - github.com/rossoctl/rossoctl-extensions
**MCP Gateway** - CNCF project from Kuadrant

<br>

Everything runs in your K8s cluster - try it today.

<br>

<span class="subtle">Thank you.</span>

<!--
All open source. Spin up a Kind cluster, deploy an agent, try to break the guardrails. We want to know what's missing. Thank you.
-->

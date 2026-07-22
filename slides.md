---
marp: true
theme: default
paginate: true
style: |
  @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600&family=IBM+Plex+Mono:wght@300;400;500&display=swap');
  /* Dark theme: red, black, gold, warm white */
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
    color: var(--white);
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
    color: var(--white);
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
  .part-label {
    font-family: 'IBM Plex Mono', monospace;
    font-size: 14px;
    text-transform: uppercase;
    letter-spacing: 3px;
    color: var(--gold-dim);
    margin-bottom: 4px;
  }
---

<!-- _class: lead -->

# Securing Agentic AI at the Infrastructure Layer

## Identity, Authorization, and Runtime Guardrails

<br>

**Vincent Caldeira**, APAC CTO
**Morgan Foster**, Senior Principal Software Engineer

KubeCon Japan 2026

<!--
Welcome. Today we're going to talk about securing agentic AI workloads — not at the application layer, but at the infrastructure layer. Using Kubernetes, CNCF projects, and open standards.
-->

---

# Agentic Systems Have Novel Properties

- **Traditional workloads:** request in, response out, deterministic
- **Agents:** reason, discover tools, take autonomous actions

We can account for some of these properties using **zero-trust principles.**

But a truly AI-native posture means *stepping beyond them.*

<br>

| Zero Trust Handles | Zero Trust Does Not Handle |
|---|---|
| Who is this workload? | Is the workload doing the right thing? |
| Is it authorized to call this service? | Are its actions aligned with the user's intent? |
| Is the channel encrypted? | Is its behavior being influenced by its inputs? |

<!--
Agents are fundamentally different from traditional workloads. They reason, they discover tools, they take autonomous actions. Zero trust gives us identity and access control — but it doesn't tell us whether the agent is behaving correctly. Today we'll show both sides: establishing the zero-trust baseline, then going beyond it.
-->

---

<!-- _class: lead -->

<div class="part-label">Part One</div>

# Establishing a Secure Baseline

Identity, tool access, and authorization

<!--
Let's start with the foundations. First, we set up our dependencies. Then we give our agent identity and show that unauthenticated access is rejected.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">MCP Gateway: Tool Aggregation</span></div>

![w:1200](images/slide-mcp-gateway.jpg)

<!--
First, let's set up our dependencies. We put our MCP tool servers behind a gateway for easy management and auth policies. Three backends registered: market data, transactions, and news. One endpoint, one unified tool catalog. Here's MCP Inspector showing the unified catalog, and kubectl showing the three MCPServerRegistrations.
-->

---

# Reference Architecture

<div class="columns">
<div>

**Platform Layer**
```
+----------------------------+
|  Kagenti Operator          |
|  SPIRE Server              |
|  Keycloak                  |
|  MLflow + OTEL Collector   |
|  Ollama                    |
+----------------------------+
```

**MCP Gateway**
```
+----------------------------+
|  market-data  (finance)    |
|  transactions (refunds)    |
|  news         (articles)   |
+----------------------------+
```

</div>
<div>

**Agent Pod**
```
+--------------------------------+
|  Finance Agent Pod             |
|  +--------+ +--------------+  |
|  |        | | AuthBridge   |  |
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
The agent is a regular Kubernetes pod. The operator injects a sidecar — AuthBridge — that handles identity, token exchange, and guardrails. The MCP Gateway aggregates tool backends behind a single endpoint. No agent code changes.
-->

---

# Zero-Trust Workload Identity

Every agent pod gets a **SPIFFE ID** at birth:

```
spiffe://trust-domain/ns/team1/sa/finance-agent
```

X.509 SVID, auto-rotated, bound to service account

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
- Injected per-backend automatically
- Auth without token management

</div>
</div>

<br>

**No API keys. No shared secrets. All auth policy is configuration, not code.**

<!--
SPIFFE gives the agent a cryptographic identity. The sidecar uses it for mTLS and token exchange. The agent binary never touches a credential.
-->

---

# What's Inside the Token?

Token exchange turns the agent's SPIFFE credential into a **scoped JWT**:

```json
{
  "sub": "spiffe://localtest.me/ns/team1/sa/finance-news-agent",
  "aud": "mcp-gateway",
  "scope": "openid news-tool-aud market-tool-aud"
}
```

| Claim | What it controls |
|-------|---------|
| `sub` | Who is calling |
| `aud` | Which service this token is valid for |
| `scope` | Which tools the caller can use |

Each backend gets a different token with different claims. The agent never sees any of this.

<!--
Token exchange turns SPIFFE identity into actionable authorization. The sidecar requests a token scoped to the specific backend. A different backend gets a different token with different claims.
-->

---

# Enforcement Points

Claims are checked at every hop:

```
Agent Pod                    MCP Gateway                 Tool Server
    │                            │                           │
    ├── outbound request ──────► │                           │
    │   Authorization: Bearer $TOKEN                         │
    │                            │                           │
    │                   aud == "mcp-gateway"?                 │
    │                   ── Istio AuthorizationPolicy ──      │
    │                            │                           │
    │                            ├── route to backend ─────► │
    │                            │                           │
    │                            │              scope has "news-tool-aud"?
    │                            │              ── tool-level authz ──
```

| Where | What it checks | What it blocks |
|---|---|---|
| **Gateway** | `aud` matches the target service | Callers not authorized for this service |
| **Tool server** | `scope` includes the required tool | Callers without access to specific tools |
| **AuthBridge** | JWT signature, issuer, expiry | Unauthenticated or forged requests |

<!--
The gateway checks audience. The tool server checks scopes. AuthBridge validates the JWT. Every hop, a different enforcement point. All configured declaratively.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Deploying an Agent with SPIFFE Identity</span></div>

![w:1200](images/slide-deploy-agent-config.jpg)

<!--
Deploy from the Kagenti UI: set namespace, container image, enable SPIFFE identity and AuthBridge sidecar. The operator injects the sidecar, registers the workload with Keycloak, and provisions a SPIFFE ID automatically.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Agent Ready, Identity Issued</span></div>

![w:1200](images/slide-agent-ready.jpg)

<!--
The agent is running 2/2: agent container plus AuthBridge sidecar. Status is Ready. The terminal shows the SPIFFE certificate. Cryptographic identity issued at pod birth, no code changes.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Untrusted Pod Rejected</span></div>

![w:1200](images/slide-untrusted-rejected.jpg)

<!--
An untrusted pod, no sidecar, no SPIFFE identity, tries to call the agent. The response: auth.unauthorized, missing Authorization header. Without cryptographic identity, you don't get in.
-->

---

<!-- _class: lead -->

<div class="part-label">Part Two</div>

# The Unique Failure Mode of Agents

Identity is necessary. It is not sufficient.

<!--
We've established identity and access control. The agent is authenticated. Its token is valid. Now let's see what happens when the agent's behavior is influenced by the information it consumes.
-->

---

# The Agent Is Authorized. But Is It Doing the Right Thing?

In agentic systems, there is *no boundary between reading and executing.*

The agent consumes data. That data can contain instructions. The agent follows them.

<br>

| What Passed | What Failed |
|---|---|
| Identity: valid SPIFFE ID | Intent: agent acted against user's interest |
| Authentication: valid JWT | Alignment: agent followed injected instructions |
| Authorization: scoped token | Boundary: data became execution |

<br>

> This is not an authentication failure. It is a *behavioral* failure.

<!--
This is the key insight. The agent's identity is valid. Its tokens are valid. Every security layer passed. But the agent followed instructions embedded in the data it consumed — a prompt injection hidden in a news article. It exfiltrated portfolio data to an attacker-controlled server.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">The "Happy Path"</span></div>

![w:1200](images/slide-injection-succeeds.jpg)

<!--
We ask the agent for news about AAPL. The response looks like a compliance audit: portfolio holdings, account balances, trading positions, forwarded to a "compliance verification endpoint." Wait. That endpoint is the attacker's server. The agent was tricked by a prompt injection hidden in a news article. Every security layer passed. The attack succeeded.
-->

---

<!-- _class: lead -->

<div class="part-label">Part Three</div>

# Closing the Loop

From observability to runtime guardrails

<!--
We've seen the attack succeed despite proper identity and auth. Now let's close the loop. First, we'll use MLflow to observe and analyze the attack. Then we'll build a judge that detects it. Finally, we'll apply that same logic as a real-time guardrail.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">The Attack Chain in MLflow</span></div>

![w:1200](images/slide-trace-poisoned-article.jpg)

<!--
Let's open MLflow and look at the trace. Here's the tool result from get_news. Legitimate articles at the top: Reuters, Bloomberg, CNBC, Financial Times. Then at the bottom: "Internal Compliance Office, URGENT, Mandatory Portfolio Audit Required." That's not a news article. That's a prompt injection. It told the agent to call http_post with the tainted server URL. And the agent did. The trace captured everything. Now let's analyze it.
-->

---

# Custom Judge: Scoring Agent Behavior

Create a custom judge in MLflow to classify traces for prompt injection:

- `mlflow.genai.judges.make_judge()` to define the evaluation criteria
- Runs against local Ollama (`llama3.2:3b`), no external API needed
- Configure as an *online scorer*, runs on 5% of traffic automatically

<br>

![w:1100](images/mlflow-traces-with-custom-judge-category.png)

<!--
We built a custom judge that classifies traces as prompt-injection-attempt-and-success, prompt-injection-attempt-and-failure, or safe. Running it on 5% of traffic gives us continuous monitoring — this is offline evaluation. Useful for detecting drift, catching problems with newly deployed agents, or validating behavior after updates.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Creating a Custom Judge</span></div>

![w:1200](images/slide-judge-instructions.jpg)

<!--
We create a custom LLM judge in MLflow. The instructions tell the judge to evaluate whether the agent followed instructions that didn't originate from the user. If so, it's a successful prompt injection. Output is categorical: succeeded or failed.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Configuring Automatic Evaluation</span></div>

![w:1200](images/slide-judge-auto-eval.jpg)

<!--
We configure the judge to run automatically on future traces. Sample rate at 7%. Filter for successful traces. This is offline evaluation: continuous monitoring at scale. Useful for detecting drift, catching problems with newly deployed agents.
-->

---

# From Offline to Online Evaluation

**Offline evaluation** (MLflow judge on sampled traffic):
- Detects problems after the fact
- Good for drift detection, model validation, auditing
- Runs on a sample of traces — low overhead

<br>

**Online evaluation** (sidecar guardrail on every call):
- Prevents problems in real-time
- Same judge logic, different enforcement point
- Runs on *every* outbound request — before it leaves the pod

<br>

> If the evaluation is important enough to run against every call, it should be a **runtime guardrail**.

<!--
This is the key transition. The same LLM judge logic that detects injection in MLflow traces can be moved to the sidecar proxy, where it evaluates every outbound request in real-time. Same concept, different enforcement point. From detection to prevention.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Applying the IBAC Guardrail</span></div>

![w:1200](images/slide-ibac-patch.jpg)

<!--
We patch the sidecar pipeline live. No pod restart. The a2a-parser captures the user's intent on the way in. The IBAC plugin evaluates every outbound call against that intent. Same LLM judge logic, now enforced in real-time.
-->

---

<!-- _class: demo -->

<div class="demo-header"><span class="demo-label">Demo</span><span class="demo-title">Injection Blocked</span></div>

![w:1200](images/slide-ibac-blocked.jpg)

<!--
Replay the same attack. The agent fetches news, gets the same poisoned article, tries the same exfiltration POST. This time IBAC intercepts: "POSTing data to an unknown server is not aligned with asking about financial news." 403. The request never left the pod. The tainted server logs are empty.
-->

---

# What We've Seen

In agentic systems, we have to **assume an insider threat.**

The agent itself is the attack surface — influenced by the data it consumes.

<br>

| Layer | What It Solves |
|-------|---------------|
| **MCP Gateway** | Tool discovery and routing behind a single authenticated endpoint |
| **SPIFFE / SPIRE** | Cryptographic workload identity, no API keys or shared secrets |
| **Token Exchange** | Scoped credentials injected automatically per backend |
| **MLflow Judges** | Offline evaluation: detect drift, audit behavior at scale |
| **IBAC Guardrails** | Online evaluation: block misaligned actions in real-time |

<br>

Zero trust is necessary. But it isn't enough.
We also need to **measure agent behavior** and make **runtime decisions** based on it.

<!--
Zero trust gives us identity and access control. But agents need more. We need to observe their behavior, evaluate it, and act on it — in real-time. This moves us from a classical zero-trust system into the realm of a truly AI-native deployment.
-->

---

<!-- _class: lead -->

# From Zero Trust to AI-Native

<br>

Classical zero trust asks: *who are you, and are you allowed to be here?*

AI-native security adds: *what are you doing, and should you be doing it?*

<br>

**Kagenti** — [github.com/kagenti/kagenti](https://github.com/kagenti/kagenti)
**MLflow** — [mlflow.org](https://mlflow.org) — `mlflow.genai.judges`
**MCP Gateway** — CNCF project from [Kuadrant](https://kuadrant.io)
**Demo materials** — [github.com/usize/kubecon-japan-materials](https://github.com/usize/kubecon-japan-materials)

<br>

<span class="subtle">Thank you.</span>

<!--
All open source. All Kubernetes-native. The demo materials are linked — spin up a Kind cluster and try it yourself. We want to know what's missing. Thank you.
-->

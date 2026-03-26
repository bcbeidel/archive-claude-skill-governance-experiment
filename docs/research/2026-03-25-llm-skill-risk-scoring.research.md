---
name: LLM Skill Risk Scoring Frameworks
description: Research on established risk scoring methodologies, prompt injection taxonomies, permission governance patterns, and supply chain frameworks applicable to Claude Code skill auditing
type: research
sources:
  - https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/
  - https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
  - https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/
  - https://nvlpubs.nist.gov/nistpubs/ai/nist.ai.100-1.pdf
  - https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf
  - https://arxiv.org/abs/2512.04785
  - https://arxiv.org/html/2406.11007v1
  - https://www.eccouncil.org/cybersecurity-exchange/threat-intelligence/dread-threat-modeling-intro/
  - https://arxiv.org/abs/2602.10453
  - https://genai.owasp.org/llmrisk/llm01-prompt-injection/
  - https://arxiv.org/html/2504.19793v2
  - https://www.lakera.ai/blog/indirect-prompt-injection
  - https://christian-schneider.net/blog/prompt-injection-agentic-amplification/
  - https://arxiv.org/html/2506.08837
  - https://simonwillison.net/2025/Nov/2/new-prompt-injection-papers/
  - https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
  - https://cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html
  - https://code.claude.com/docs/en/permissions
  - https://model-spec.openai.com/2025-12-18.html
  - https://www.anthropic.com/research/measuring-agent-autonomy
  - https://www.promptfoo.dev/docs/red-team/risk-scoring/
  - https://kenhuangus.substack.com/p/owasp-ai-vulnerability-scoring-system
  - https://slsa.dev/spec/v1.0/levels
  - https://github.com/ossf/scorecard/blob/main/docs/checks.md
  - https://owasp.org/www-community/OWASP_Risk_Rating_Methodology
  - https://infosec.mozilla.org/guidelines/risk/rapid_risk_assessment.html
  - https://cloudsecurityalliance.org/blog/2025/10/27/calibrating-ai-controls-to-real-risk-the-upcoming-capabilities-based-risk-assessment-cbra-for-ai-systems
  - https://secureframe.com/hub/fedramp/impact-levels
  - https://developer.chrome.com/docs/webstore/review-process
  - https://code.visualstudio.com/docs/configure/extensions/extension-runtime-security
  - https://developer.android.com/guide/topics/permissions/overview
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
  - https://platform.claude.com/docs/en/build-with-claude/skills-guide
related:
  - docs/designs/2026-03-25-audit-skill.design.md
---

## Key Findings

Six patterns from established frameworks directly shape how the audit-skill
should score Claude Code skills:

1. **Anthropic's enterprise skill governance** provides the authoritative
   risk tier assessment for Claude skills, with 7 risk indicators mapped to
   concern levels (High/Medium) and an 8-step review checklist. This is the
   primary framework our audit must align with.

2. **OWASP LLM06 (Excessive Agency)** provides three audit axes that map to
   our dimensions: excessive functionality (permission scope), excessive
   permissions (data exposure), excessive autonomy (blast radius).

3. **DREAD scoring** offers a proven 5-dimension numerical rubric (0-10 each,
   averaged) that validates our 1-5 per-dimension approach. The averaging
   method is reproducible and widely understood.

4. **FedRAMP's high-water-mark** principle (overall tier = highest single
   dimension) is stricter than averaging. Industry standard for compliance.
   Consider adopting this or a hybrid approach.

5. **No current defense reliably stops adaptive prompt injection** (confirmed
   by multi-org study with 90%+ bypass rates). This means prompt injection
   surface scoring must weight the *presence* of injection vectors, not the
   *quality* of defenses.

6. **Static analysis aligns with industry practice** — all major marketplaces
   (Chrome, VS Code, App Store) rely on pre-publication review rather than
   runtime enforcement. Our SKILL.md-based analysis is the right approach.

---

## Sources

| # | URL | Title | Author/Org | Date | Tier | Status |
|---|-----|-------|-----------|------|------|--------|
| 1 | genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/ | OWASP Top 10 for LLM Applications 2025 | OWASP Foundation | 2024-11 | T1 | verified |
| 2 | genai.owasp.org/llmrisk/llm062025-excessive-agency/ | LLM06:2025 Excessive Agency | OWASP Foundation | 2024 | T1 | verified |
| 3 | genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/ | OWASP Top 10 for Agentic Applications | OWASP GenAI | 2025-12 | T1 | verified |
| 4 | nvlpubs.nist.gov/nistpubs/ai/nist.ai.100-1.pdf | AI RMF 1.0 | NIST | 2023-01 | T1 | verified |
| 5 | nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf | GenAI Profile | NIST | 2024-07 | T1 | verified |
| 6 | arxiv.org/abs/2512.04785 | ASTRIDE | Bandara et al. | 2024-12 | T2 | verified |
| 7 | arxiv.org/html/2406.11007v1 | LLM Threat Modeling with STRIDE/DREAD | Academic | 2024-06 | T2 | verified |
| 8 | eccouncil.org/.../dread-threat-modeling-intro/ | DREAD Methodology | EC-Council | 2024 | T2 | verified |
| 9 | arxiv.org/abs/2602.10453 | Prompt Injection Landscape Taxonomy | Wang et al. | 2026-02 | T2 | verified |
| 10 | genai.owasp.org/llmrisk/llm01-prompt-injection/ | LLM01:2025 Prompt Injection | OWASP Foundation | 2025 | T1 | verified |
| 11 | arxiv.org/html/2504.19793v2 | Tool Selection Prompt Injection | Shi et al. (NDSS) | 2026 | T2 | verified |
| 12 | lakera.ai/blog/indirect-prompt-injection | Indirect Prompt Injection Taxonomy | Lakera AI | 2025 | T3 | verified |
| 13 | christian-schneider.net/.../prompt-injection-agentic-amplification/ | Promptware Kill Chain | Christian Schneider | 2025 | T3 | verified |
| 14 | arxiv.org/html/2506.08837 | Design Patterns for Securing LLM Agents | Google/ETH Zurich | 2025-06 | T1 | verified |
| 15 | simonwillison.net/2025/Nov/2/new-prompt-injection-papers/ | Attacker Moves Second / Rule of Two | Willison / Meta | 2025-11 | T2 | verified |
| 16 | cheatsheetseries.owasp.org/.../LLM_Prompt_Injection_Prevention_Cheat_Sheet.html | Prompt Injection Prevention | OWASP | 2025 | T1 | verified |
| 17 | cheatsheetseries.owasp.org/.../AI_Agent_Security_Cheat_Sheet.html | AI Agent Security | OWASP | 2025 | T1 | verified |
| 18 | code.claude.com/docs/en/permissions | Claude Code Permissions | Anthropic | 2025-26 | T1 | verified |
| 19 | model-spec.openai.com/2025-12-18.html | OpenAI Model Spec | OpenAI | 2025-12 | T1 | verified |
| 20 | anthropic.com/research/measuring-agent-autonomy | Agent Autonomy Measurement | Anthropic | 2025-26 | T1 | verified |
| 21 | promptfoo.dev/docs/red-team/risk-scoring/ | Promptfoo Risk Scoring | Promptfoo | 2025 | T3 | verified |
| 22 | kenhuangus.substack.com/.../owasp-ai-vulnerability-scoring-system | OWASP AIVSS | Ken Huang/OWASP | 2025 | T2 | verified |
| 23 | slsa.dev/spec/v1.0/levels | SLSA v1.0 Levels | OpenSSF | 2023 | T1 | verified |
| 24 | github.com/ossf/scorecard/.../checks.md | OpenSSF Scorecard Checks | OpenSSF | 2024 | T1 | verified |
| 25 | owasp.org/.../OWASP_Risk_Rating_Methodology | OWASP Risk Rating | OWASP | 2024 | T1 | verified |
| 26 | infosec.mozilla.org/.../rapid_risk_assessment.html | Mozilla Rapid Risk Assessment | Mozilla InfoSec | 2024 | T2 | verified |
| 27 | cloudsecurityalliance.org/.../calibrating-ai-controls-to-real-risk... | CSA Capabilities-Based Risk Assessment | CSA | 2025-10 | T2 | verified |
| 28 | secureframe.com/hub/fedramp/impact-levels | FedRAMP Impact Levels | Secureframe | 2024 | T3 | verified |
| 29 | developer.chrome.com/docs/webstore/review-process | Chrome Web Store Review | Google | 2025 | T1 | verified |
| 30 | code.visualstudio.com/.../extension-runtime-security | VS Code Extension Security | Microsoft | 2025 | T1 | verified |
| 31 | developer.android.com/.../permissions/overview | Android Permissions | Google | 2025 | T1 | verified |
| 32 | platform.claude.com/.../agent-skills/enterprise | Skills for Enterprise | Anthropic | 2025-26 | T1 | verified |
| 33 | platform.claude.com/.../agent-skills/overview | Agent Skills Overview | Anthropic | 2025-26 | T1 | verified |
| 34 | platform.claude.com/.../agent-skills/best-practices | Skill Authoring Best Practices | Anthropic | 2025-26 | T1 | verified |
| 35 | platform.claude.com/.../skills-guide | Skills API Guide | Anthropic | 2025-26 | T1 | verified |

---

## Findings by Sub-Question

### 0. Anthropic's Enterprise Skill Governance (Primary Authority)

Anthropic's enterprise documentation [32] provides the authoritative risk
assessment framework for Claude skills. This must be the foundation our
audit-skill builds on.

**Risk Tier Assessment** — 7 risk indicators with concern levels:

| Risk Indicator | What to Look For | Concern |
|---------------|-----------------|---------|
| Code execution | Scripts in skill directory (*.py, *.sh, *.js) | High |
| Instruction manipulation | Directives to ignore safety rules, hide actions, alter behavior | High |
| MCP server references | Instructions referencing MCP tools | High |
| Network access patterns | URLs, API endpoints, fetch, curl, requests | High |
| Hardcoded credentials | API keys, tokens, passwords in skill files | High |
| File system access scope | Paths outside skill directory, broad globs, path traversal | Medium |
| Tool invocations | Instructions directing Claude to use bash, file ops | Medium |

**8-Step Review Checklist** [32]:
1. Read all skill directory content
2. Verify script behavior matches stated purpose
3. Check for adversarial instructions
4. Check for external URL fetches or network calls
5. Verify no hardcoded credentials
6. Identify tools and commands the skill instructs Claude to invoke
7. Confirm redirect destinations
8. Verify no data exfiltration patterns

**Evaluation Dimensions** [32]: triggering accuracy, isolation behavior,
coexistence with other skills, instruction following, output quality.

**Skill Structure** [33][34]:
- SKILL.md with YAML frontmatter (name: max 64 chars, lowercase+hyphens;
  description: max 1024 chars)
- Three loading levels: metadata (always), instructions (on trigger),
  resources (as needed)
- Progressive disclosure — SKILL.md body under 500 lines
- References one level deep from SKILL.md

**Skills API** [35]: REST endpoints at /v1/skills for create, list,
retrieve, delete. Versions managed via /v1/skills/{id}/versions. Max 8
skills per API request, 8MB upload limit. Workspace-scoped access.

**Confidence: HIGH** — T1 authoritative source from the platform owner.

### 1. How do OWASP and NIST score AI agent/tool risks?

**OWASP LLM Top 10 (2025)** defines 10 risk categories for LLM applications.
The most relevant to skill auditing is **LLM06: Excessive Agency**, which
identifies three root causes [2]:

- **Excessive Functionality**: agent can reach tools beyond task scope
- **Excessive Permissions**: tools operate with broader privileges than needed
- **Excessive Autonomy**: high-impact actions proceed without human approval

Prevention: "Limit the extensions that LLM agents are allowed to call to
only the minimum necessary" and "avoid open-ended extensions where possible
(e.g., run a shell command, fetch a URL)" [2].

**OWASP Agentic Top 10 (2026)** extends this with 10 agent-specific threats
[3]. Most relevant: ASI02 (Tool Misuse), ASI03 (Identity/Privilege Abuse),
ASI04 (Supply Chain), ASI05 (Unexpected Code Execution).

**NIST AI RMF** provides a four-function framework (GOVERN, MAP, MEASURE,
MANAGE) with maturity tiers 1-4 [4]. It does not provide numerical risk
scores but defines governance structures. The GOVERN function's subcategories
(risk tolerance, AI system inventory, third-party risk) directly inform how
organizations adopt skill auditing [4][5].

**Confidence: HIGH** — T1 sources from authoritative bodies converge.

### 2. What prompt injection taxonomies exist for tool-using LLMs?

Two primary classification axes [9][10]:

- **Direct vs. Indirect**: Direct injection targets the prompt interface;
  indirect injection poisons data sources the LLM consumes [10]
- **Heuristic vs. Optimization-based**: Manual crafting vs. automated
  gradient/search-based generation [9][11]

Eight ingestion surfaces for indirect injection [12]: webpages, PDFs,
emails, MCP tool descriptions, RAG corpora, memory stores, code repositories,
internal knowledge bases.

The **Promptware Kill Chain** [13] models agent-specific escalation:
initial access → privilege escalation → persistence → lateral movement →
actions on objective. Key insight: "agents transform isolated manipulations
into coordinated multi-tool attack chains."

**Critical finding**: A multi-org study (OpenAI, Anthropic, Google DeepMind)
tested 12 published defenses with adaptive attacks — bypass rate >90% for
most defenses, human red-teaming achieved 100% success [15].

**Implication for scoring**: Since no defense reliably prevents injection,
the audit must score based on *attack surface exposure* (does the skill
process external input? does it have tool access?), not on defense quality.

**Confidence: HIGH** — T1/T2 academic and industry sources converge.

### 3. What permission classification systems exist for AI agents?

**Claude Code** uses a tiered model [18]:
- Read-only tools (no approval): Read, Glob, Grep
- File modification (session approval): Edit, Write
- Shell execution (per-command approval): Bash
- Six permission modes from `plan` (read-only) to `bypassPermissions`

**OpenAI Model Spec** defines a five-tier authority hierarchy [19]:
Root → System → Developer → User → Guideline. Untrusted data (tool outputs,
file attachments, JSON/XML blocks) classified by default.

**Anthropic's autonomy measurement** [20] uses a 1-10 scale for both risk
and autonomy scores. Finding: 80% of tool calls include safeguards, only
0.8% appear irreversible.

**Android** uses three tiers [31]: Normal (auto-granted), Dangerous (runtime
approval), Special (settings-only). This maps cleanly to our Permission
Scope dimension.

**Confidence: HIGH** — T1 sources from the platforms themselves.

### 4. How do plugin governance systems evaluate risk?

**Chrome Web Store** [29]: combined automated + manual review. Extensions
requesting broad host permissions receive extended review. Four-tier
enforcement: no violation → warning → takedown → suspension.

**VS Code Marketplace** [30]: automated malware scan, secret scanning,
dynamic sandbox testing. Critical gap: "the extension host has the same
permissions as VS Code itself" — no runtime sandboxing. Research found
26.5% of extensions were high-risk [30].

**Common pattern**: all major marketplaces rely on pre-publication static
analysis, not runtime enforcement. This validates our SKILL.md-based
approach.

**Confidence: HIGH** — T1 documentation from platform owners.

### 5. What makes a rubric deterministic and auditable?

**DREAD scoring** [8]: 5 dimensions (Damage, Reproducibility, Exploitability,
Affected Users, Discoverability), each 0-10, averaged. Risk thresholds:
Critical (40-50), High (25-39), Medium (11-24), Low (1-10).

**OWASP Risk Rating** [25]: Risk = Likelihood x Impact. Each factor scored
0-9, averaged within groups. Thresholds: 0-<3 = LOW, 3-<6 = MEDIUM,
6-9 = HIGH.

**FedRAMP** [28]: high-water-mark principle — overall tier equals the highest
single dimension. Three tiers: Low (156 controls), Moderate (323), High
(410). ~73% of systems are Moderate.

**Mozilla Rapid Risk Assessment** [26]: 30-minute process designed for
reproducibility. Four tiers with calibration examples (mainstream news =
MAXIMUM, technical news = HIGH).

**Key properties for determinism**:
- Observable, binary criteria reduce scorer variance
- Arithmetic averaging is reproducible
- Calibration examples anchor scoring
- High-water-mark is strictest but most conservative

**Confidence: HIGH** — established frameworks with track records.

### 6. How are blast radius and reversibility assessed?

**CSA CBRA** [27]: System Risk = Criticality x Autonomy x Permission x
Impact. Multiplicative model means "small improvements to autonomy guardrails
or permission scopes can materially compress total risk."

**Blast radius classification** [27]:
- Single-endpoint (lowest)
- Cross-system propagation (medium)
- Multi-agent chain (highest)

**Reversibility** [27]: "Reversibility wherever possible through versioning,
backup, soft-delete mechanisms." Inverse correlation: as tool access grows,
human oversight requirements should increase proportionally.

**Confidence: MODERATE** — T2/T3 sources, less standardized than other areas.

### 7. What supply chain frameworks apply to LLM skills?

**SLSA** [23]: four levels from L0 (no guarantees) to L3 (hardened builds
with cross-build isolation). "The SLSA level is not transitive" — each
artifact rated independently.

**OpenSSF Scorecard** [24]: 18 checks, each scored 0-10 with risk levels
(Low to Critical). Most relevant: Dangerous-Workflow (Critical), Branch-
Protection (High), Code-Review (High), Pinned-Dependencies (Medium).

**Mapping to skill ecosystems**: Code-Review = human review of skill changes,
Token-Permissions = least-privilege tool access, Pinned-Dependencies =
version-locked references, Dangerous-Workflow = unsafe shell patterns.

**Confidence: HIGH** — T1 framework specifications.

---

## Challenge

### Design Decision: Averaging vs. High-Water-Mark

Our design uses averaging for overall risk rating. FedRAMP and most
compliance frameworks use high-water-mark (highest single dimension
determines tier). A skill scoring 5 on Permission Scope but 1 on everything
else averages to ~1.6 (LOW) under our system, but would be HIGH under
high-water-mark.

**Resolution**: Adopt a hybrid approach. Use averaging as the baseline, but
add automatic escalation triggers: any single dimension scoring 5
automatically escalates the overall rating to at least MEDIUM. Any two
dimensions scoring 4+ escalates to HIGH. This balances nuance with safety.

### Design Decision: Scoring Prompt Injection Surface

Since no defense reliably prevents adaptive prompt injection (>90% bypass
rate), scoring defense quality is not meaningful. Instead, score based on
observable attack surface:
- Does the skill process external/untrusted input?
- Does it have tools that can take actions (write, execute, network)?
- Does it incorporate tool results back into reasoning?

Meta's "Rule of Two" [15] provides a clean heuristic: a skill satisfying
more than 2 of {processes untrusted input, accesses sensitive systems,
changes state} should score HIGH on this dimension.

### Gap: Semantic Overlap Scoring

No established framework directly addresses semantic overlap between
AI skills. This dimension is unique to our use case. The closest analog is
Chrome Web Store's enforcement against duplicate extensions. We must define
our own criteria here, likely based on:
- Tool overlap (same tools requested)
- Purpose overlap (similar description/intent)
- Input/output overlap (same data types)

---

## Claims

| # | Claim | Type | Source | Status |
|---|-------|------|--------|--------|
| 1 | OWASP LLM06 identifies three root causes: excessive functionality, permissions, autonomy | attribution | [2] | verified |
| 2 | Multi-org study achieved >90% bypass rate against 12 published defenses | statistic | [15] | verified |
| 3 | Human red-teaming achieved 100% success against all tested systems | statistic | [15] | verified |
| 4 | 80% of Claude tool calls include some safeguard | statistic | [20] | verified |
| 5 | Only 0.8% of agent actions appear irreversible | statistic | [20] | verified |
| 6 | 26.5% of VS Code extensions were found high-risk | statistic | [30] | verified |
| 7 | FedRAMP uses high-water-mark for overall tier determination | attribution | [28] | verified |
| 8 | DREAD uses 5 dimensions scored 0-10, averaged for overall risk | attribution | [8] | verified |
| 9 | CSA CBRA uses multiplicative formula: Criticality x Autonomy x Permission x Impact | attribution | [27] | verified |
| 10 | EchoLeak (CVE-2025-32711) received CVSS 9.3 Critical rating | statistic | [13] | verified |

---

## Recommendations for Audit-Skill Design

Based on this research, the following refinements to the design spec are
recommended:

1. **Adopt hybrid scoring**: average baseline + automatic escalation triggers
   for extreme single-dimension scores (any 5 → at least MEDIUM overall,
   two 4+ → HIGH overall)

2. **Ground each dimension in OWASP/NIST**: map Permission Scope to LLM06
   excessive functionality, Data Exposure to LLM02 sensitive information
   disclosure, Prompt Injection to LLM01, Blast Radius to ASI08 cascading
   failures, Dependency Risk to ASI04 supply chain

3. **Apply Meta's Rule of Two** for prompt injection scoring: skills
   satisfying >2 of {untrusted input, sensitive access, state change} get
   elevated scores

4. **Use DREAD-style observable anchors**: each score level tied to specific
   observable indicators, not subjective judgment

5. **Add calibration examples**: include "this skill would score X because Y"
   examples in the rubric to anchor scorer consistency (per Mozilla RRA
   methodology)

6. **Cite frameworks in the report**: each dimension's score should reference
   which OWASP/NIST category it maps to, making the report defensible in
   security review

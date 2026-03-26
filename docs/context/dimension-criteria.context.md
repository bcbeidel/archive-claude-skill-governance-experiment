---
name: Dimension Criteria
description: Observable scoring criteria for each of the 7 risk dimensions, grounded in Anthropic's enterprise risk indicators, OWASP LLM06, and Meta's Rule of Two
type: context
sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise
  - https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
  - https://genai.owasp.org/llmrisk/llm01-prompt-injection/
  - https://simonwillison.net/2025/Nov/2/new-prompt-injection-papers/
  - https://slsa.dev/spec/v1.0/levels
  - https://cloudsecurityalliance.org/blog/2025/10/27/calibrating-ai-controls-to-real-risk-the-upcoming-capabilities-based-risk-assessment-cbra-for-ai-systems
related:
  - docs/research/2026-03-25-llm-skill-risk-scoring.research.md
  - docs/context/scoring-methodology.context.md
  - docs/context/scoring-calibration.context.md
  - docs/designs/2026-03-25-audit-skill.design.md
---

## Dimension Criteria

Each dimension below lists observable indicators per score level. Indicators
are derived from Anthropic's enterprise risk tier assessment, OWASP
categories, and established security frameworks.

### 1. Permission Scope

*Maps to: Anthropic "Tool invocations" indicator, OWASP LLM06 Excessive
Functionality*

What tools and resources does the skill instruct Claude to use?

| Score | Indicators |
|-------|-----------|
| 1 | No tool use beyond reading its own files |
| 2 | Read-only tools only (Read, Glob, Grep) |
| 3 | File modification tools (Edit, Write) scoped to specific paths |
| 4 | Bash with constrained commands (e.g., git, npm, specific CLIs) |
| 5 | Unrestricted Bash, or Bash without command constraints |

### 2. Data Exposure

*Maps to: Anthropic "Hardcoded credentials" and "File system access scope"
indicators, OWASP LLM02 Sensitive Information Disclosure*

Can the skill access, transmit, or log sensitive data?

| Score | Indicators |
|-------|-----------|
| 1 | Accesses only files within its own skill directory |
| 2 | Reads project files in scoped directories, no external output |
| 3 | Reads across the project, outputs summaries to user |
| 4 | Accesses env vars, config files, or paths outside project (../) |
| 5 | Accesses credentials/secrets, or transmits data to external URLs |

**Auto-escalation**: Hardcoded API keys/tokens/passwords in skill files →
score 5 regardless of other indicators.

### 3. Prompt Injection Surface

*Maps to: Anthropic "Instruction manipulation" indicator, OWASP LLM01
Prompt Injection, Meta's Rule of Two*

How vulnerable is the skill to injection via user input or tool results?

| Score | Indicators |
|-------|-----------|
| 1 | No external input; operates on static/known content only |
| 2 | Processes structured input with clear boundaries (e.g., file paths) |
| 3 | Processes user-provided text but does not act on it (analysis only) |
| 4 | Incorporates external content into reasoning AND has tool access |
| 5 | Processes untrusted input AND accesses sensitive data AND changes state |

**Meta's Rule of Two**: A skill satisfying more than 2 of these 3 properties
scores 5:
- (A) Processes untrusted/external input
- (B) Accesses sensitive systems or private data
- (C) Changes state or communicates externally

**Auto-escalation**: Directives to ignore safety rules, hide actions, or
alter behavior conditionally → score 5.

### 4. Blast Radius

*Maps to: OWASP ASI08 Cascading Failures, CSA CBRA Impact dimension*

What is the worst-case impact if the skill misbehaves?

| Score | Indicators |
|-------|-----------|
| 1 | No side effects — pure read/analysis |
| 2 | Modifies files in a single, scoped directory |
| 3 | Modifies files across the project |
| 4 | Executes system commands, modifies config, or affects git state |
| 5 | Can affect external systems, deploy code, send data, or delete broadly |

### 5. Reversibility

*Maps to: CSA CBRA, Anthropic's deployment lifecycle guidance*

Are the skill's actions reversible or destructive?

| Score | Indicators |
|-------|-----------|
| 1 | Pure read operations — fully reversible by definition |
| 2 | File edits within git-tracked directories — reversible via git |
| 3 | Creates/deletes files or modifies untracked content — reversible with effort |
| 4 | System-level changes (env vars, installed packages, config) — partially reversible |
| 5 | Destructive/irreversible actions (force push, data deletion, external API calls with side effects) |

### 6. Semantic Overlap

*No direct framework mapping — unique to skill governance*

Does the skill duplicate or conflict with existing skills?

| Score | Indicators |
|-------|-----------|
| 1 | Unique purpose, no tool or description overlap with other skills |
| 2 | Tangential overlap — shares some tools but clearly distinct purpose |
| 3 | Partial overlap — similar description keywords, some shared workflows |
| 4 | Significant overlap — could confuse skill selection, consolidation recommended |
| 5 | Near-duplicate of an existing skill |

**Note**: This dimension requires knowledge of the broader skill set.
When auditing in isolation, score based on description specificity and
breadth. Overly broad descriptions (Anthropic warns these "steal triggers
from existing Skills") score higher.

### 7. Dependency Risk

*Maps to: OWASP ASI04 Supply Chain Vulnerabilities, SLSA levels, OpenSSF
Scorecard*

External dependencies, version pinning, supply chain concerns.

| Score | Indicators |
|-------|-----------|
| 1 | No external dependencies — uses only built-in Claude tools |
| 2 | References well-known, pinned packages available in the runtime |
| 3 | References external packages with version constraints |
| 4 | References external APIs, unpinned dependencies, or MCP server tools |
| 5 | Complex dependency chain, unvetted external code, or dynamic code loading |

**Auto-escalation**: MCP server references → at least score 4 (per
Anthropic's "High concern" classification for MCP tool references).

# Pipeline Plugin Design

**Date:** 2026-02-27
**Status:** Approved

---

## Philosophy

Code is a liability; judgement is an asset. Every phase in this pipeline exists to eliminate ambiguity before it reaches the implementation layer. Every transition is a quality gate that blocks forward progress until validation passes. Context never contains more than what is in scope for the current task.

The pipeline:

```
idea → /arm → /design → /ar → /plan → /build → /qa
         ↓        ↓       ↓      ↓       ↓        ↓
       brief   design  approved  plan  complete  clean
                doc     design
```

---

## Plugin Identity

- **Name:** `claude-agents-custom`
- **Type:** Vanilla Claude Code plugin — zero runtime dependencies beyond explicitly listed tools
- **Scope:** Personal use, opinionated, no abstraction layer

---

## Dependencies

| Dependency | Role | Required |
|---|---|---|
| Context7 | Live library docs grounding in `/design` and `/ar` | Yes |
| OpenAI MCP | Codex access for adversarial review and code validation | Yes |
| TypeScript LSP | Type-aware analysis for TS/JS projects | Optional |
| Go LSP | Symbol resolution for Go projects | Optional |
| Python LSP | Type inference and import analysis for Python projects | Optional |
| C# LSP | Symbol resolution and type-aware audits for .NET projects | Optional |

LSP dependencies degrade gracefully — when absent, skills fall back to static analysis without failure.

---

## Plugin Structure

```
claude-agents-custom/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── arm/SKILL.md
│   ├── design/SKILL.md
│   ├── ar/SKILL.md
│   ├── plan/SKILL.md
│   ├── pmatch/SKILL.md
│   ├── build/SKILL.md
│   ├── qa/SKILL.md
│   ├── denoise/SKILL.md
│   ├── qf/SKILL.md
│   ├── qb/SKILL.md
│   ├── qd/SKILL.md
│   └── security-review/SKILL.md
├── hooks/
│   └── pipeline_gate.sh
└── README.md
```

---

## State Model

Each phase writes a state artifact to `.pipeline/` at the project root. The hook script reads these files to enforce quality gates. The `.pipeline/` directory is gitignored by default.

```
.pipeline/
├── brief.md          # written by /arm on completion
├── design.md         # written by /design on completion
├── design.approved   # empty marker written by /ar when loop resolves
├── plan.md           # written by /plan on completion
└── build.complete    # empty marker written by /build after /pmatch passes
```

**Resetting state:** Delete the `.pipeline/` directory or individual files to reopen gates.

### Gate Map

| Skill | Requires | Blocked message |
|---|---|---|
| `/arm` | nothing | — |
| `/design` | `.pipeline/brief.md` | "No brief found. Run /arm first." |
| `/ar` | `.pipeline/design.md` | "No design doc found. Run /design first." |
| `/plan` | `.pipeline/design.approved` | "Design not approved. Run /ar until resolved." |
| `/build` | `.pipeline/plan.md` | "No plan found. Run /plan first." |
| `/pmatch` | `.pipeline/plan.md` | "No plan found. Run /plan first." |
| `/denoise` | `.pipeline/build.complete` | "Build not complete. Run /build first." |
| `/qf` | `.pipeline/build.complete` | "Build not complete. Run /build first." |
| `/qb` | `.pipeline/build.complete` | "Build not complete. Run /build first." |
| `/qd` | `.pipeline/build.complete` | "Build not complete. Run /build first." |
| `/security-review` | `.pipeline/build.complete` | "Build not complete. Run /build first." |
| `/qa` | `.pipeline/build.complete` | "Build not complete. Run /build first." |

---

## Cognitive Tiering

| Phase | Model | Rationale |
|---|---|---|
| `/arm` | Opus | Signal extraction from fuzzy input requires judgment |
| `/design` | Opus | First-principles analysis, constraint classification |
| `/ar` — strategic critique | Opus | Design-level blind spot detection |
| `/ar` — code-grounded critique | Codex via OpenAI MCP | Grounded in actual code, not just reasoning |
| `/ar` — lead (dedup + cost/benefit) | Opus | Synthesizes both, runs loop decision |
| `/plan` | Opus | Atomic task decomposition, test case authoring at plan time |
| `/pmatch` — agent 1 | Sonnet | Independent claim extraction |
| `/pmatch` — agent 2 | Codex via OpenAI MCP | Independent claim extraction, code-grounded |
| `/pmatch` — lead | Opus | Validates findings, mitigates drift |
| `/build` — lead | Opus | Coordinates and unblocks, never writes code |
| `/build` — builders | Sonnet | Implementation, one agent per task group |
| `/qa`, `/denoise`, `/qf`, `/qb`, `/qd`, `/security-review` | Sonnet | Mechanical audits, no strategy needed |

---

## Skill Specifications

### `/arm` — Requirements Crystallization

**Model:** Opus
**Gate:** None
**Writes:** `.pipeline/brief.md`

Opus conducts conversational Q&A to extract requirements, constraints, non-goals, style, and key concepts from fuzzy input. Searches episodic memory for similar past briefs before starting. Detects project language(s) and records them in the brief for downstream LSP routing. Forces remaining decisions in a single structured checkpoint before writing the brief. Output is a brief, not a design.

---

### `/design` — First-Principles Design

**Model:** Opus
**Gate:** `.pipeline/brief.md`
**Writes:** `.pipeline/design.md`

Opus reads the brief and performs first-principles analysis. Every constraint is evaluated and classified (hard vs. soft). Soft constraints treated as hard are flagged. Before drawing any conclusions about libraries or patterns, Opus calls Context7 for live docs and web search for known pitfalls. Routes to the appropriate LSP if detected in the brief. Reconstructs the optimal approach from validated truths only. Iterates with the user until alignment. Output is a formal design document.

---

### `/ar` — Adversarial Review

**Model:** Opus (lead + strategic critic) + Codex via OpenAI MCP (code-grounded critic)
**Gate:** `.pipeline/design.md`
**Writes:** `.pipeline/design.approved` (empty marker on loop exit)

Opus and Codex are dispatched in parallel via the Task tool. Each receives the design document and codebase access. Opus grounds its critique with Context7 before forming opinions. Codex grounds its critique with filesystem access. Lead Opus receives both reports, deduplicates findings, fact-checks each against the actual codebase, runs cost/benefit analysis on every finding, and outputs a structured report for human review. Loop continues until no remaining findings warrant mitigation per cost/benefit analysis. On exit, writes `.pipeline/design.approved`.

---

### `/plan` — Atomic Execution Planning

**Model:** Opus
**Gate:** `.pipeline/design.approved`
**Writes:** `.pipeline/plan.md`

Opus transforms the approved design into an execution document precise enough that build agents never ask clarifying questions. ~5 tasks per agent group. No file conflicts between groups. Exact file paths. Complete code examples showing patterns. Named test cases with setup and assertions defined at plan time. Tasks are atomic with non-negotiable acceptance criteria. Plan explicitly flags which task groups are safe for parallel execution and which must be sequential — this informs the `/build` mode choice.

---

### `/pmatch` — Drift Detection

**Model:** Sonnet (agent 1) + Codex via OpenAI MCP (agent 2) + Opus (lead)
**Gate:** `.pipeline/plan.md`
**Writes:** nothing (report only)

Two agents are dispatched in parallel. Each independently extracts claims from the source-of-truth document and verifies each claim against the target. Lead Opus receives both reports, validates findings, reconciles conflicts between agents, and mitigates drift where needed. Outputs a structured drift report.

---

### `/build` — Parallel Build

**Model:** Opus (lead) + Sonnet (builders)
**Gate:** `.pipeline/plan.md`
**Writes:** `.pipeline/build.complete` (after `/pmatch` passes post-build)
**Flags:** `--parallel` | `--sequential` (prompts if omitted)

**`--parallel` mode:** Sonnets run as independent agents, each assigned a task group from the plan with its own context. Opus lead monitors progress, unblocks agents, and never writes code directly. After all agents complete, Opus runs `/pmatch` to verify implementation against plan. On pass, writes `build.complete`.

**`--sequential` mode:** Task groups are executed one at a time by a Sonnet subagent in the current session. Opus lead coordinates sequencing, handles blockers, and runs `/pmatch` post-completion. On pass, writes `build.complete`.

The lead's rule: coordinate and unblock. Never write implementation code.

---

### `/qa` — Post-Build QA Pipeline Orchestrator

**Model:** Sonnet (all auditors)
**Gate:** `.pipeline/build.complete`
**Flags:** `--parallel` | `--sequential` (prompts if omitted)

**`--parallel` mode:** Dispatches `/denoise`, `/qf`, `/qb`, `/qd`, `/security-review` simultaneously as independent agents. Safe because each audits an independent concern with no shared write state.

**`--sequential` mode:** Runs in order: denoise → qf → qb → qd → security-review. Each completes before the next begins.

Individual QA skills remain available standalone — each still requires `build.complete`.

---

### `/denoise` — Dead Code Removal

**Model:** Sonnet
**Gate:** `.pipeline/build.complete`

Uses LSP (if available for the project language) to definitively identify unused symbols, unreachable branches, and dead imports. Falls back to heuristic static analysis when LSP is absent. Removes confirmed dead code without touching live paths.

---

### `/qf` — Frontend Style Audit

**Model:** Sonnet
**Gate:** `.pipeline/build.complete`

Audits frontend code against project-specific style guide. Uses TypeScript LSP when available for type-aware analysis. Reports violations with file paths and line numbers.

---

### `/qb` — Backend Style Audit

**Model:** Sonnet
**Gate:** `.pipeline/build.complete`

Audits backend code against project-specific style guide. Uses Go LSP, Python LSP, or C# LSP based on project language detected in the brief. Reports violations with file paths and line numbers.

---

### `/qd` — Documentation Freshness

**Model:** Sonnet
**Gate:** `.pipeline/build.complete`

Validates that documentation reflects the current implementation. Flags stale references, outdated API signatures, and missing documentation for new public interfaces.

---

### `/security-review` — OWASP Security Scan

**Model:** Sonnet
**Gate:** `.pipeline/build.complete`

Scans for OWASP Top 10 vulnerabilities. Uses LSP-provided data flow information when available for taint analysis. Reports findings with severity, location, and remediation guidance.

---

## Hook Implementation

A single `pipeline_gate.sh` script handles all gate enforcement. Registered in `plugin.json` as a `PreToolCall` hook on the Skill tool.

**Behavior:**
1. Reads tool call JSON from stdin
2. Extracts the skill name from the invocation
3. Looks up the gate requirement for that skill
4. Checks for the required `.pipeline/` artifact in the current working directory
5. Exits 0 (allow) if artifact exists or skill has no gate
6. Exits non-zero with a human-readable blocked message if artifact is missing

---

## Build Phasing

### Phase 1 — Foundation

Single agent, no external tools, no orchestration. After this phase: a gated arm → QA pipeline is usable.

1. Plugin scaffold (`plugin.json`, directory structure)
2. `pipeline_gate.sh` hook script
3. README (full documentation)
4. `/arm` skill
5. `/denoise` skill
6. `/qf` skill
7. `/qb` skill
8. `/qd` skill
9. `/security-review` skill

### Phase 2 — External Tool Integration

Single agent with Context7, web search, and LSP grounding.

1. `/design` skill
2. `/plan` skill

### Phase 3 — Multi-Agent Orchestration

Parallel sub-agent dispatch and synthesis.

1. `/ar` skill
2. `/pmatch` skill
3. `/build` skill (both modes)
4. `/qa` skill (both modes)

---

## README Scope

The README covers:
- Philosophy and pipeline overview
- Prerequisites and installation (dev marketplace setup, plugin install, hook registration, OpenAI MCP config)
- `.pipeline/` state model — what each file means, how to reset
- Command reference — every skill with arguments, gate requirements, and outputs
- End-to-end walkthrough — `/arm` through `/qa` on a real example
- Mode flag guide — when to use `--parallel` vs `--sequential`
- Language support matrix — what each LSP adds per skill
- Troubleshooting — common gate failures, MCP issues, resetting state

---

## Key Principles

- **Context is noise.** Give agents only the narrow, curated signal they need for their phase.
- **Cognitive tiering.** Opus for strategy. Sonnet for implementation.
- **Audit the auditor.** The agent that builds cannot validate. Separate contexts for execution and validation.
- **Stress-test assumptions.** Distinct models critique the same design, exposing blind spots a single perspective misses.
- **Grounding, not guessing.** Context7 and live docs override training data. LSP overrides heuristics.
- **Deterministic execution.** Test cases defined at plan time, not after the build.

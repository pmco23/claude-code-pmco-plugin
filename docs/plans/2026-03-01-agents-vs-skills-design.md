# Design: Skills vs Agents — Plugin Architecture Refactor

**Date:** 2026-03-01
**Status:** Approved

---

## Context

The plugin currently uses Skills exclusively — 16 SKILL.md files that instruct Claude to use the Agent tool inline. Research into Claude Code's agent primitive revealed a meaningful architectural distinction that the plugin does not yet exploit:

- **Skills** — loaded into the main conversation context. Good for conversational workflows, interactive approvals, and orchestration.
- **Agents** (`.claude/agents/`) — run in isolated context with their own window, restricted tools, and preloaded knowledge. Good for self-contained analysis that returns a report.

Six current skills are pure *read → analyse → report* workflows with no conversational steps. These are the target for conversion.

---

## Fitness Criterion

A skill should become an agent when it satisfies **all three**:

1. **Self-contained** — no mid-task questions to the user; input comes from the codebase, output is a report
2. **Read-only** — no writes, edits, or file creation as part of its core task
3. **Verbose output** — findings that would pollute the main conversation if kept inline

---

## Conversion Map

| Skill | Decision | Reason |
|-------|----------|--------|
| `/brief` | SKILL | Conversational — asks clarifying questions |
| `/design` | SKILL | Conversational — approves sections with user |
| `/review` | SKILL | Interactive approval step after presenting |
| `/plan` | SKILL | Produces plan with user guidance |
| `/build` | SKILL | Interactive — writes code, shows progress |
| `/quick` | SKILL | Interactive fix workflow |
| `/init` | SKILL | Conversational — overwrite/skip/merge per file |
| `/git-workflow` | SKILL | Conversational — asks about PR, branch |
| `/qa` | SKILL | Orchestrator layer — stays as coordinator |
| `/status` | SKILL | Too lightweight for agent overhead |
| `/drift-check` | **→ AGENT** | Self-contained: reads plan + code + docs, returns report |
| `/cleanup` | **→ AGENT** | Self-contained: scans for dead code, returns findings |
| `/frontend-audit` | **→ AGENT** | Self-contained: audits frontend, returns findings |
| `/backend-audit` | **→ AGENT** | Self-contained: audits backend, returns findings |
| `/doc-audit` | **→ AGENT** | Self-contained: checks doc freshness, returns findings |
| `/security-review` | **→ AGENT** | Self-contained: OWASP scan, returns findings |

**Result: 6 agents, 10 skills.**

---

## File Structure

```
.claude/
  agents/
    cleanup.md
    frontend-audit.md
    backend-audit.md
    doc-audit.md
    security-review.md
    drift-check.md

skills/
  cleanup/SKILL.md          ← thin wrapper (8-10 lines)
  frontend-audit/SKILL.md   ← thin wrapper
  backend-audit/SKILL.md    ← thin wrapper
  doc-audit/SKILL.md        ← thin wrapper
  security-review/SKILL.md  ← thin wrapper
  drift-check/SKILL.md      ← thin wrapper
  qa/SKILL.md               ← simplified dispatch
  plugin-architecture/SKILL.md  ← NEW: decision guide

docs/
  guides/
    agents-vs-skills.md     ← NEW: human-readable companion
```

---

## Agent File Pattern

Each agent file uses restricted tools — read-only operations only:

```yaml
---
name: <audit-name>
description: <one-line description of what it audits>
tools: Read, Grep, Glob, Bash, mcp__ide__getDiagnostics
model: claude-sonnet-4-6
---

# <Full audit instructions, moved verbatim from SKILL.md>
```

No Write, Edit, or Agent tool access. Audit agents observe but do not modify.

---

## Thin Wrapper SKILL.md Pattern

```yaml
---
name: <audit-name>
description: <same description as before — user-facing entry point>
---

# <Audit Name>

Check that `.pipeline/build.complete` exists. If missing: "Build required — run /build first."

Invoke the `<audit-name>` subagent with this context:
- .pipeline/build.complete exists

Return the agent's findings verbatim.
```

---

## `/qa` Simplification

Before (current): each of the 5 dispatch prompts embeds a full paragraph describing the audit task.

After: each dispatch is a one-liner referencing the named agent:

```
Dispatch 5 agents simultaneously:
1. cleanup — ".pipeline/build.complete exists. Report all findings."
2. frontend-audit — ".pipeline/build.complete exists. Report all findings."
3. backend-audit — ".pipeline/build.complete exists. Report all findings."
4. doc-audit — ".pipeline/build.complete exists. Report all findings."
5. security-review — ".pipeline/build.complete exists. Report all findings."
```

---

## Guide Deliverables

### `skills/plugin-architecture/SKILL.md`

Invocable as `/plugin-architecture`. Content:
- Core distinction (2-3 sentences each primitive)
- Fitness criterion (binary rules)
- Three composition patterns with short examples
- Decision tree
- Anti-patterns

Target length: 60-80 lines.

### `docs/guides/agents-vs-skills.md`

Human-readable companion with:
- Prose explanation of each primitive
- Full conversion table (all 16 skills, with reasoning)
- Before/after examples from this plugin's refactoring
- When to revisit the decision

---

## Deliverables Summary

| # | File | Action |
|---|------|--------|
| 1 | `.claude/agents/cleanup.md` | Create |
| 2 | `.claude/agents/frontend-audit.md` | Create |
| 3 | `.claude/agents/backend-audit.md` | Create |
| 4 | `.claude/agents/doc-audit.md` | Create |
| 5 | `.claude/agents/security-review.md` | Create |
| 6 | `.claude/agents/drift-check.md` | Create |
| 7 | `skills/cleanup/SKILL.md` | Replace with thin wrapper |
| 8 | `skills/frontend-audit/SKILL.md` | Replace with thin wrapper |
| 9 | `skills/backend-audit/SKILL.md` | Replace with thin wrapper |
| 10 | `skills/doc-audit/SKILL.md` | Replace with thin wrapper |
| 11 | `skills/security-review/SKILL.md` | Replace with thin wrapper |
| 12 | `skills/drift-check/SKILL.md` | Replace with thin wrapper |
| 13 | `skills/qa/SKILL.md` | Simplify dispatch prompts |
| 14 | `skills/plugin-architecture/SKILL.md` | Create |
| 15 | `docs/guides/agents-vs-skills.md` | Create |

---
name: plugin-architecture
description: Use when designing or evaluating Claude Code plugins — explains when to use skills vs agents and how to compose them correctly.
---

# Plugin Architecture — Skills vs Agents

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`). If running on Haiku, output quality may be reduced for tasks requiring judgment.

You are a Claude Code plugin architecture advisor. Present the framework below and apply it to the user's specific question.

## Core Distinction

**Skills** (SKILL.md) run inline in the main conversation. The user invokes with `/skill-name`. Claude reads the instructions and acts directly in context. Use for conversational workflows, orchestration, and anything that requires mid-task interaction with the user.

**Agents** (`.claude/agents/<name>.md`) run in an isolated context window with their own tool access list. They return a result to the parent conversation. Use for self-contained work that produces a report and needs no back-and-forth.

## Fitness Criterion

Convert a skill to an agent only when it satisfies **all three**:

1. **Self-contained** — no mid-task questions to the user; all input comes from files or the prompt
2. **Read-only** — no writes, edits, or file creation as part of its core task
3. **Verbose output** — produces findings that would pollute the main context if kept inline

If any criterion fails, keep it as a skill. If criteria 1 and 3 pass but 2 fails, use the split pattern.

## Agent Frontmatter

```yaml
---
name: <name>
description: <one-line description Claude uses to choose this agent>
tools: Read, Grep, Glob, Bash    # restrict to what the agent actually needs
model: claude-sonnet-4-6         # or claude-opus-4-6 for complex reasoning tasks
---
```

Omit `Write`, `Edit`, and `Agent` for read-only agents. Listing `tools:` is the only hard enforcement — without it the agent gets full tool access.

## Thin Wrapper Pattern

When a SKILL.md exists only to gate a precondition and dispatch an agent:

```markdown
---
name: <name>
description: <user-facing description>
---

# <Title>

Check [precondition]. If not met: "[error message]." Stop.

Invoke the `<agent-name>` subagent with this context:
- [key context items]

Return the agent's findings verbatim.
```

**Cost of this pattern:** two files to maintain per skill. If the agent's output format changes, the wrapper must also be updated. Only use this when the isolation or tool restriction benefit is concrete, not theoretical.

## Split Pattern

When a task has an interactive phase and an analysis phase:

- **Agent:** analysis only — reads files, returns a findings list
- **Skill:** interaction — shows findings, asks user to confirm, then acts

Example: a dead-code remover. The agent scans and reports. The skill asks "remove all?" and then edits.

## Composition Rules

| Scenario | Use |
|----------|-----|
| Pure analysis → report | Agent; skill is thin wrapper (if user entry point needed) |
| Analysis + user confirmation | Agent for analysis; skill for interaction |
| Orchestrating multiple analyses | Skill dispatches multiple agents via Agent tool |
| Conversational workflow | Skill only |
| Nested agents | Not supported — use a skill as orchestrator instead |

## Decision Tree

```
Requires mid-task user interaction?
├─ YES → Skill (or Skill + Agent for the analysis sub-phase)
└─ NO  → Read-only AND produces verbose output?
    ├─ YES → Agent (tool-restricted) + thin wrapper Skill if user entry point needed
    └─ NO  → Skill
```

## Anti-Patterns

- **Agent writing files:** the task belongs in a skill, or split into agent (find) + skill (write)
- **Skill embedding full agent prompt:** move the logic to a named agent file and reference it
- **Agent without `tools:` field:** omitting it grants full tool access — always specify
- **Two files for a theoretical risk:** don't create the thin-wrapper split until a real problem justifies the maintenance cost
- **Nested agents:** agents cannot spawn agents; chain from a skill instead

# Agents vs Skills in Claude Code Plugins

## Overview

Claude Code plugins have two primitives for extending Claude's behaviour: **Skills** and **Agents**. They look similar on the surface (both are markdown files with YAML frontmatter) but serve distinct purposes and run in fundamentally different execution contexts.

Understanding which to use — and when a skill should delegate to an agent — prevents a common trap: refactoring for architectural cleanliness when the current code already works, and adding indirection that creates two files to maintain instead of one.

---

## The Primitives

### Skills (`skills/<name>/SKILL.md`)

Skills are loaded into the **main conversation context**. When a user runs `/skill-name`, Claude reads the SKILL.md instructions and executes them inline — the work happens in the same context window the user is looking at.

Skills can also be marked `disable-model-invocation: true` when they are
stateful or destructive. This plugin uses that for pipeline transitions and
safety gates so those workflows only run when the user explicitly types the
slash command.

Skills are the right choice for:
- Conversational workflows (asking the user clarifying questions, getting approval on sections)
- Orchestration (dispatching multiple agents, sequencing steps)
- Interactive multi-step tasks (confirm before modifying, overwrite/skip/merge decisions)
- Anything where the user watches progress as it happens

### Agents (`.claude/agents/<name>.md`)

Agents run in an **isolated context window** with their own tool access list. Claude dispatches them via the Task tool, they do their work independently, and return a result to the parent conversation.

Agents are the right choice for:
- Self-contained analysis that produces a structured report
- Tasks where verbose output would pollute the main conversation
- Work that genuinely needs tool restrictions enforced at the runtime level (not just by prompt instruction)

The key word is *genuine*. A skill that says "do not modify any files" is almost always sufficient. An agent with `tools: Read, Grep, Glob, Bash` is only better when you need hard enforcement — for example, when the same agent is invoked from multiple skills and you can't trust all callers to pass the right instructions.

---

## Fitness Criterion

A task should become an agent only when it satisfies **all three** tests:

**1. Self-contained** — No mid-task questions to the user. All input comes from files or the prompt. The agent runs to completion and returns a result without needing to pause for user input.

**2. Scoped writes** — If the agent writes files, those writes must be confined to a well-defined scope (e.g., one task group's file list). Agents that orchestrate open-ended edits across the full codebase belong as skills, not agents. If the task has both analysis and open-ended modification, use the split pattern.

**3. Verbose output** — The findings are detailed enough that keeping them inline would meaningfully consume the main context. A three-line result doesn't justify the overhead.

If a task fails any test, keep it as a skill.

---

## Evaluating This Plugin's 21 Skills

The following table applies the fitness criterion to every skill in this plugin. It documents the reasoning so future decisions can follow the same logic rather than re-litigating from scratch.

| Skill | Decision | Reason |
|-------|----------|--------|
| `/brief` | **Skill** | Conversational — asks clarifying questions one at a time |
| `/design` | **Skill** | Conversational — approves sections iteratively with the user |
| `/review` | **Skill** | Has an interactive approval step after presenting the report |
| `/plan` | **Skill** | Produces a plan with user guidance and revision cycles |
| `/build` | **Skill** | Interactive — writes code and shows progress in real time |
| `/quick` | **Skill** | Interactive fix workflow — targets specific items the user selects |
| `/init` | **Skill** | Conversational — asks overwrite/skip/merge for each existing file |
| `/git-workflow` | **Skill** | Destructive-op safety gate — confirms before force-push, reset --hard, branch -D, or rebasing published commits |
| `/qa` | **Skill** | Orchestrator — coordinates five audits; interaction in sequential mode |
| `/status` | **Skill** | Lightweight report from `.pipeline/` files; no verbose output |
| `/pack` | **Skill** | Single-command Repomix wrapper; non-interactive, but output is used by the user immediately — no isolation benefit |
| `/drift-check` | **Borderline** | Asks user for source/target when run standalone (fails criterion 1); auto when called from `/build`. Could be split — agent for the verification phase, skill for the source/target prompt. Not worth splitting until the current approach causes a real problem. |
| `/cleanup` | **Borderline** | Finds dead code (read-only) then asks user to confirm before removing (interactive). Could be split — agent for the scanning phase, skill for the confirmation and removal. Same judgement: don't split until there's a concrete reason. |
| `/frontend-audit` | **Agent candidate** | Self-contained, read-only, produces structured findings. Passes all three tests. |
| `/backend-audit` | **Agent candidate** | Same as frontend-audit. |
| `/doc-audit` | **Agent candidate** | Same pattern — reads docs and code, returns freshness report. |
| `/security-review` | **Agent candidate** | Same pattern — reads code, returns OWASP findings. |
| `/test` | **Skill** | Interactive — prefers structured prompts for runner selection and failure handling, with plain-text fallback when unavailable; offers `/quick` on test failures |
| `/rollback` | **Skill** | Requires per-group confirmation, safety backups, and repo-root-safe path validation before destructive file removal |

**Note:** `/commit`, `/push`, `/commit-push-pr`, `/sync`, `/clean-branches`, and `/release` are **commands** (not skills or agents). Commands are lightweight one-shot markdown files with injected context — they don't need the skill/agent evaluation.

### Why the four agent candidates were kept as skills

The four strong agent candidates (`/frontend-audit`, `/backend-audit`, `/doc-audit`, `/security-review`) were evaluated for conversion and the decision was **not to convert** them. The reasons:

1. **Context isolation is already achieved.** When `/qa --parallel` dispatches them, it uses the Task tool, which already runs in an isolated context. The findings are returned as a result, not streamed inline. Converting to `.claude/agents/` files would not change this behaviour.

2. **Tool restrictions address a theoretical risk.** Every audit skill explicitly instructs Claude not to modify files. There is no incident history of an audit skill accidentally writing. Adding hard enforcement adds maintenance cost for a problem that hasn't occurred.

3. **Two files to maintain instead of one.** Converting to an agent creates a thin wrapper SKILL.md (gate + dispatch) and an agent file (logic). These can drift out of sync. The current single-file approach is simpler.

4. **The test against the litmus criteria used to evaluate this plugin:**
   - *Reduces tokens?* No — same content in more files.
   - *Adds determinism?* Marginally (tool restrictions). Not enough to justify the overhead.
   - *Narrows search space?* No.
   - *Can go stale safely?* Worse — two files to keep in sync.
   - *Measurable value?* Not demonstrable in practice.

**Conclusion:** The current architecture is correct. Revisit if a concrete problem emerges.

---

## Patterns

### Pattern 1: Pure Skill

The default. One SKILL.md file. Claude reads it and executes inline.

```
User: /frontend-audit
Claude: [reads SKILL.md, executes audit, presents findings inline]
```

### Pattern 2: Skill Dispatches Agents (Orchestration)

A skill coordinates multiple agents using the Task tool. The agents run in isolation; the skill collects and synthesises results.

```
User: /qa --parallel
Skill: dispatches 5 Task tool calls simultaneously
       ← [each agent runs isolated, returns findings]
Skill: collects all findings, presents consolidated report
```

This is the current pattern in `/qa`. No agent files required — the Task tool handles isolation.

### Pattern 3: Thin Wrapper Skill + Agent File

When tool restrictions need hard enforcement, or when the same agent logic is invoked from multiple skills and duplication would be a maintenance burden.

```
User: /frontend-audit
Skill (thin wrapper): gates on .pipeline/build.complete, invokes `frontend-audit` agent
Agent file: contains the full audit logic with tools: Read, Grep, Glob, Bash
```

**Use this pattern only when:** the tool restriction is genuinely necessary (not just theoretical), OR the agent is invoked from 3+ different places and centralising the logic prevents real duplication.

### Pattern 4: Split (Interactive + Analysis)

When a task has an analysis phase (read-only, could be isolated) and an interactive phase (user confirmation, then modification).

```
User: /cleanup
Skill: invokes cleanup agent → receives findings list
       → presents findings via AskUserQuestion (or plain-text fallback): "Remove all / Review each / Skip"
       → if "Remove all": applies edits using Edit tool
Agent file: Steps 1-2 only (scan, return findings list — analysis only) with tools: Read, Grep, Glob, Bash
```

**Use this pattern only when:** the analysis phase is genuinely expensive or verbose enough that isolating it provides a real benefit.

---

## When to Revisit

Convert a skill to an agent (or introduce the split pattern) when one of these signals appears:

- **An audit skill modifies a file it shouldn't.** This is the concrete safety signal. Tool restrictions at the agent level would prevent it.
- **The same audit logic is invoked from three or more skills.** Centralising it in an agent file eliminates duplication.
- **A `/qa` dispatch prompt grows beyond a paragraph.** Named agents with dedicated files become cleaner than long embedded prompts.
- **A skill's output is so verbose it makes the conversation hard to read.** Proper agent isolation moves that output out of the main thread.

Until one of these signals is present, the current architecture is correct and simpler.

---

## Reference

This guide covers the fitness criterion, patterns, decision tree, and anti-patterns for choosing between skills and agents.

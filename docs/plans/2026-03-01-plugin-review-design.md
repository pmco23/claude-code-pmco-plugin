# Plugin Review Design: Manifest Compliance

**Date:** 2026-03-01
**Goal:** Apply the "signal vs. bloat" manifest to the claude-agents-custom plugin and produce a prioritized fix plan.

## Review Method

Finding-first: group by problem category, map each finding to affected components, order fix plan by severity. Swarms, prompts, and style overlap are explicitly evaluated against the manifest's five litmus tests.

## Findings Map

| ID | Category | Severity | Affected Components |
|----|----------|----------|---------------------|
| F1 | Missing reference files | CRITICAL | `git-workflow`, `/quick` (commit step), `/build` agent commits |
| F2 | PostToolUse hook fires on every tool call | MEDIUM | `hooks/context-monitor.sh`, `hooks/hooks.json` |
| F3 | Stale plugin metadata + orphan file | MEDIUM | `.claude-plugin/plugin.json`, `echo` (root) |
| F4 | Hard dependencies with no documented fallback | MEDIUM | `/design` (Context7), `/review` + `/drift-check` (Codex MCP) |
| F5 | Embedded prose prompts | LOW | `/review` Agent 1 prompt (64-line blob) |

### F1 — Missing reference files (CRITICAL)

`git-workflow` Step 2 reads `references/code-path.md` (trunk-based workflow) and
`references/infra-path.md` (three-environment workflow). Neither file exists in the repo.
Every invocation of `/git-workflow` silently fails at Step 2.

Cascade: `/quick` (Step 5: "invoke git-workflow before committing") and `/build` agent
prompt ("invoke git-workflow before committing") both delegate to the broken skill.

Fix: create both reference files with the workflow specs the skill expects.

### F2 — PostToolUse hook fires on every tool call (MEDIUM)

`context-monitor.sh` has `matcher: "*"` — it spawns bash + python3 after every tool
use (Read, Grep, Edit, Bash, Agent, etc.). The purpose is valid: inject context-usage
ground truth into Claude's own context so it knows when to /compact. The problem is
firing frequency. At 70%+ context, every Read and Grep injects the same warning,
consuming the context it warns about.

Manifest litmus:
- Adds ground truth? YES — context % is not otherwise visible to Claude itself.
- Narrows search space? YES — informs compact decision for lead agents.
- Reduces tokens long-term? ONLY if noise is controlled; currently degrades under load.

Fix (Option A): narrow `matcher` from `"*"` to high-cost tool calls only (Bash, Agent).
Read/Grep/Edit are cheap and don't materially change context — skip monitoring them.

### F3 — Stale plugin metadata + orphan file (MEDIUM)

`plugin.json` description: `"arm → design → ar → plan → build → qa"` — uses pre-rename
skill names (arm=brief, ar=review). Skills were renamed in commit `5fa267e`.

`echo` (empty file at repo root): accidental shell-command artifact, not tracked in
git as intentional.

Fix: update `plugin.json` description to current skill names; delete `echo`.

### F4 — Hard dependencies with no documented fallback (MEDIUM)

`/design` Hard Rule 1: "Never recommend a library or pattern without grounding it first.
Call Context7 to get the live docs." No fallback if Context7 is unavailable.

`/review` and `/drift-check`: Agent 2 calls `mcp__codex__codex` directly. No fallback
if Codex MCP is not connected.

Manifest litmus: can it go stale safely? Only if absence of the tool is handled
explicitly. Currently, absence causes the skill to silently violate its own invariants.

Fix: add graceful degradation notes to each affected skill specifying behavior when
the dependency is absent.

### F5 — Embedded prose prompts (LOW)

`/review` Agent 1 prompt is a 64-line block embedded in the skill. This is the dispatch
template — it can't be removed. Flagged against the manifest's caution about
mega-instructions. No action taken; documented for awareness.

## Swarm Evaluation

All multi-agent patterns in this plugin are evaluated as justified:

| Skill | Swarm shape | Justification |
|-------|------------|---------------|
| `/review` | Opus (strategic) + Codex (code-grounded) | Separable tasks, deterministic integration (dedup + cost/benefit + approval marker) |
| `/drift-check` | Sonnet + Codex | Separable tasks (independent claim extraction), deterministic merge |
| `/build` | Opus lead + N Sonnets | Parallel-safe task groups, lead coordinates; deterministic integration via drift-check |
| `/qa --parallel` | 5 independent audits | Fully independent concerns, no shared state |

## Out of Scope

- F5: embedded prompt is the dispatch template, not removable
- `/cleanup` × `/backend-audit` unused-import overlap: documented and expected, not worth fragmenting
- Multi-agent swarms: all pass the manifest's "separable tasks + deterministic integration" test

## Deliverables

**Document 1 — Review report:** `docs/plans/2026-03-01-plugin-review.md`
Structure: executive summary, findings (F1–F5), per-component verdict, out-of-scope items.

**Document 2 — Fix plan:** `docs/plans/2026-03-01-plugin-review-fix-plan.md`
Four tasks ordered by severity with exact file paths, diff-level change specs, and
verification steps per task.

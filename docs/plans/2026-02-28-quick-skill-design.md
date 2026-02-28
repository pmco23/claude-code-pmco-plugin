# Quick Skill Design

**Date:** 2026-02-28
**Status:** Approved

---

## Purpose

A standalone skill for implementing quick features and fixes directly, without the full pipeline. Completely independent of the arm → design → ar → plan → build → qa flow.

---

## Scope

Adapts to task size — tiny (single-function fixes, typos, config tweaks) or medium (small features touching 2-5 files). The skill assesses scope from the description and proceeds accordingly.

---

## Invocation

```
/quick                         # Sonnet, prompts for task
/quick fix the null check in UserCard.tsx
/quick --deep refactor the auth middleware   # escalates to Opus
```

---

## Model Routing

| Flag | Model |
|------|-------|
| default | Sonnet |
| `--deep` | Opus |

---

## Gate Behavior

Pipeline-aware but never blocked. The `pipeline_gate.sh` hook adds a `/quick` case that:
- Detects active pipeline state from `.pipeline/` artifacts
- Outputs a descriptive warning to stdout (visible to Claude as context)
- Always exits 0

**State detection (priority order):**

| State | Warning |
|-------|---------|
| `build.complete` exists | "Pipeline at QA phase — /quick will not affect pipeline artifacts." |
| `plan.md` exists, no `build.complete` | "⚠ Build in progress — /quick may conflict with active builders if touching the same files." |
| `design.approved` exists, no `plan.md` | "Pipeline at planning phase — no active build in progress." |
| `design.md` exists, no `design.approved` | "Pipeline at design/review phase — no code has been written yet." |
| `brief.md` exists, no `design.md` | "Pipeline at brief phase — no code has been written yet." |
| No `.pipeline/` dir | (no warning) |

---

## Workflow

1. Parse args — detect `--deep`, route to Opus; strip flag from task description
2. Surface pipeline warning if hook output one
3. Assess scope — if task is ambiguous, ask one clarifying question max
4. Check project context — read only relevant files; use LSP for affected symbols if available
5. Implement — follow existing patterns in touched files
6. Self-review — review own diff for obvious mistakes (wrong assumptions, broken callers, missed edge cases)
7. Optional audit prompt — ask after implementation, not before

---

## Optional Audit (lightweight)

Checks on touched files only:
- LSP diagnostics on modified files
- Obvious security patterns in changed code (hardcoded secrets, unsanitized input at entry points)
- Whether touched files have corresponding test files — if yes, remind user to run them

Does NOT invoke `/qf`, `/qb`, `/qd`, `/security-review` as full skills. Does NOT write any `.pipeline/` artifacts.

---

## Files Affected

- Modify: `hooks/pipeline_gate.sh` — add `/quick` case
- Create: `skills/quick/SKILL.md`
- Modify: `hooks/test_gate.sh` — add tests for `/quick` warning behavior

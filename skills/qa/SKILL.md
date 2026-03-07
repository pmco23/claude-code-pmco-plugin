---
name: qa
description: Use after /build to run the full post-build QA pipeline. Supports --parallel (all audits simultaneously) or --sequential (denoise → qf → qb → qd → security-review in order). Requires .pipeline/build.complete.
argument-hint: [--parallel | --sequential]
disable-model-invocation: true
---

# QA — Post-Build QA Pipeline

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are Sonnet acting as a QA pipeline orchestrator. Acquire a Repomix snapshot, then dispatch the five isolated audit tasks according to the selected mode.

## Repomix Preamble

Before dispatching any audit tasks, ensure Repomix snapshots are available:

1. Check if `.pipeline/repomix-pack.json` exists
2. If it exists, read `packedAt` — if less than 1 hour old, read the `snapshots` map
3. If missing or stale, invoke the `/pack` skill — it generates three snapshots (code, docs, full) and writes `.pipeline/repomix-pack.json`
4. After `/pack` completes, read the `snapshots` map from `.pipeline/repomix-pack.json`
5. If `/pack` fails or Repomix is unavailable, proceed without snapshots — agents fall back to native Glob/Read/Grep

Hold the snapshot map in context. Each audit task gets its mapped variant:

| Agent | Snapshot variant |
|-------|-----------------|
| Dead Code Removal (`/cleanup`) | `snapshots.code.filePath` |
| Frontend Audit | `snapshots.code.filePath` |
| Backend Audit | `snapshots.code.filePath` |
| Security Review | `snapshots.code.filePath` |
| Documentation Freshness (`/doc-audit`) | `snapshots.docs.filePath` |

## PASS Criteria

An overall PASS requires:
- Zero findings in /cleanup, /frontend-audit, /backend-audit, and /doc-audit
- Zero CRITICAL or HIGH findings in /security-review (MEDIUM and LOW do not block PASS)

These criteria apply to both parallel and sequential mode and are shown in the Overall QA Verdict table at the end of each run.

## Mode Selection

Check the invocation arguments:
- If `/qa --parallel` was used: parallel mode
- If `/qa --sequential` was used: sequential mode
- If no flag: ask the user before proceeding

Prefer AskUserQuestion with:
  question: "Which QA mode?"
  header: "QA mode"
  options:
    - label: "Parallel"
      description: "All 5 audits run simultaneously — faster, independent concerns"
    - label: "Sequential"
      description: "One audit at a time in order — review each result before continuing"

If structured prompts are unavailable in this runtime, ask a single plain-text question instead: "Which QA mode: parallel or sequential?"

## Process

### Parallel Mode

Read `references/agent-prompts.md` from this skill's base directory. Dispatch all five audit tasks simultaneously via the Task tool, substituting `<code-snapshot-path>` and `<docs-snapshot-path>` with the appropriate paths from the snapshot map (or omitting the Repomix instruction if unavailable).

If the Task tool is unavailable in this runtime, announce: "Parallel QA unavailable — Task tool not present. Falling back to sequential mode." Then continue with Sequential Mode instead of stopping.

Wait for all five to complete, then present the consolidated report and Overall QA Verdict using the format in `references/report-template.md`. Apply PASS Criteria (defined above).

### Sequential Mode

Run in order, presenting each result before proceeding. When invoking each skill, prepend the Repomix context with the agent's mapped snapshot variant path (code or docs). Example: "Repomix code snapshot available at .pipeline/repomix-code.xml — use Grep/Read on it for file discovery." For /doc-audit, use the docs snapshot path instead. If no snapshot was acquired, omit this.

1. `cleanup` — present findings — ask "Continue to /frontend-audit? (yes / fix first — then re-run /qa to verify)"
2. `frontend-audit` — present findings — ask "Continue to /backend-audit?"
3. `backend-audit` — present findings — ask "Continue to /doc-audit?"
4. `doc-audit` — present findings — ask "Continue to /security-review?"
5. `security-review` — present final findings

After all five complete, present the Overall QA Verdict using `references/report-template.md`. Apply PASS Criteria (defined above).

## Output

Present consolidated or sequential findings to the user. No file written to `.pipeline/`.

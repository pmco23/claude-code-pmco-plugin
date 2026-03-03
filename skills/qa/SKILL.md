---
name: qa
description: Use after /build to run the full post-build QA pipeline. Supports --parallel (all audits simultaneously) or --sequential (denoise → qf → qb → qd → security-review in order). Requires .pipeline/build.complete.
---

# QA — Post-Build QA Pipeline

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are Sonnet acting as a QA pipeline orchestrator. Acquire a Repomix pack, then dispatch the five audit agents according to the selected mode.

## Repomix Preamble

Before dispatching any agents, acquire a Repomix outputId for the codebase:

1. Check if `.pipeline/repomix-pack.json` exists
2. If it exists, read `packedAt` — if less than 1 hour old, use the stored `outputId`
3. If missing or stale, invoke the `/pack` skill — it packs the codebase and writes `.pipeline/repomix-pack.json` with the correct schema.
4. After `/pack` completes, read `outputId` from `.pipeline/repomix-pack.json`.
5. If `/pack` fails or Repomix is unavailable, proceed without an outputId — omit the Repomix instruction from agent prompts; agents fall back to native Glob/Read/Grep.

Hold the outputId in context for use in the agent prompts below.

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

Use AskUserQuestion with:
  question: "Which QA mode?"
  header: "QA mode"
  options:
    - label: "Parallel"
      description: "All 5 audits run simultaneously — faster, independent concerns"
    - label: "Sequential"
      description: "One audit at a time in order — review each result before continuing"

## Process

### Parallel Mode

Dispatch all five QA skills simultaneously via the Task tool. Each agent receives only the context for its specific audit.

Use the Task tool to launch 5 subagents at once. Prompt for each:

**Agent 1 — Dead Code Removal**
Prompt: `Follow the cleanup skill process: find dead code (unused symbols, unused imports, unreachable branches, commented-out code). .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings with file:line references.`

**Agent 2 — Frontend Audit**
Prompt: `Follow the frontend-audit skill process: audit frontend TypeScript/JavaScript/CSS/HTML against the project's own style guide (infer from existing code if no explicit guide). .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings with file:line references.`

**Agent 3 — Backend Audit**
Prompt: `Follow the backend-audit skill process: audit backend code (Go/Python/TypeScript/C#) against the project's own style guide. Check error handling, logging, naming, public API surface. .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings with file:line references.`

**Agent 4 — Documentation Freshness**
Prompt: `Follow the doc-audit skill process: check CHANGELOG.md for Keep a Changelog format compliance, presence of an [Unreleased] section, and coverage of the feature built in this pipeline. .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings.`

**Agent 5 — Security Review**
Prompt: `Follow the security-review skill process: scan for OWASP Top 10 vulnerabilities relevant to this application type. .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings with severity, location, and remediation.`

Wait for all five to complete, then present a consolidated report:

```markdown
# QA Report

## /cleanup
[findings or "clean — no dead code found"]

## /frontend-audit — Frontend
[findings or "no violations found"]

## /backend-audit — Backend
[findings or "no violations found"]

## /doc-audit — Documentation
[findings or "all docs reflect current implementation"]

## /security-review
[findings or "no OWASP Top 10 vulnerabilities found"]
```

After presenting the consolidated report, append an Overall QA Verdict:

```markdown
## Overall QA Verdict

| Audit | Result |
|-------|--------|
| /cleanup | [PASS — no dead code found / FAIL — N items found] |
| /frontend-audit | [PASS / FAIL — N violations] |
| /backend-audit | [PASS / FAIL — N violations] |
| /doc-audit | [PASS / FAIL — N stale or missing entries] |
| /security-review | [PASS / FAIL — N findings (X CRITICAL, Y HIGH)] |

**Overall: PASS** *(all audits clean)*
— or —
**Overall: FAIL** *([N] audits have findings requiring action)*
```

Apply PASS Criteria (defined above).

### Sequential Mode

Run in order, presenting each result before proceeding. When invoking each skill, prepend this to the invocation: "Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents." If no outputId was acquired in the preamble, omit this instruction:

1. Follow the `cleanup` skill process — present findings — ask "Continue to /frontend-audit? (yes / fix first — then re-run /qa to verify before continuing)"
2. Follow the `frontend-audit` skill process — present findings — ask "Continue to /backend-audit? (yes / fix first — then re-run /qa to verify before continuing)"
3. Follow the `backend-audit` skill process — present findings — ask "Continue to /doc-audit? (yes / fix first — then re-run /qa to verify before continuing)"
4. Follow the `doc-audit` skill process — present findings — ask "Continue to /security-review? (yes / fix first — then re-run /qa to verify before continuing)"
5. Follow the `security-review` skill process — present final findings

After /security-review completes, present the Overall QA Verdict table (same format as parallel mode above), summarising results from all five audits. Apply PASS Criteria (defined above).

## Output

Present consolidated or sequential findings to the user. No file written to `.pipeline/`.

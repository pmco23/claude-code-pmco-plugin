---
name: qa
description: Use after /build to run the full post-build QA pipeline. Supports --parallel (all audits simultaneously) or --sequential (denoise → qf → qb → qd → security-review in order). Requires .pipeline/build.complete.
---

# QA — Post-Build QA Pipeline

## Repomix Preamble

Before dispatching any agents, acquire a Repomix outputId for the codebase:

1. Check if `.pipeline/repomix-pack.json` exists
2. If it exists, read `packedAt` — if less than 1 hour old, use the stored `outputId`
3. If missing or stale, call `mcp__repomix__pack_codebase` on the current working directory with `compress: true` and update `.pipeline/repomix-pack.json` with the new outputId and current timestamp

Store the outputId for use in agent prompts below.

## Mode Selection

Check the invocation arguments:
- If `/qa --parallel` was used: parallel mode
- If `/qa --sequential` was used: sequential mode
- If no flag: ask the user before proceeding

```
QA mode:
  --parallel   All audits run simultaneously (faster, independent concerns)
  --sequential One audit at a time in order (review each before next)

Which mode? (parallel / sequential)
```

## Process

### Parallel Mode

Dispatch all five QA skills simultaneously via the Task tool. Each agent receives only the context for its specific audit.

Use the Task tool to launch 5 subagents at once. Prompt for each:

**Agent 1 — Dead Code Removal**
Prompt: `Invoke the cleanup skill to audit this codebase for dead code. .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings.`

**Agent 2 — Frontend Audit**
Prompt: `Invoke the frontend-audit skill to audit frontend code quality. .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings.`

**Agent 3 — Backend Audit**
Prompt: `Invoke the backend-audit skill to audit backend code quality. .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings.`

**Agent 4 — Documentation Freshness**
Prompt: `Invoke the doc-audit skill to check documentation freshness. .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings.`

**Agent 5 — Security Review**
Prompt: `Invoke the security-review skill to scan for OWASP Top 10 vulnerabilities. .pipeline/build.complete exists. Repomix outputId: <outputId> — use mcp__repomix__grep_repomix_output for file discovery and mcp__repomix__read_repomix_output for file contents. Report all findings.`

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

**PASS criteria:** zero findings in /cleanup, /frontend-audit, /backend-audit, /doc-audit, AND zero CRITICAL or HIGH findings in /security-review. MEDIUM and LOW security findings do not block PASS.

### Sequential Mode

Run in order, presenting each result before proceeding:

1. Invoke the `cleanup` skill — present findings — ask "Continue to /frontend-audit? (yes / fix first)"
2. Invoke the `frontend-audit` skill — present findings — ask "Continue to /backend-audit? (yes / fix first)"
3. Invoke the `backend-audit` skill — present findings — ask "Continue to /doc-audit? (yes / fix first)"
4. Invoke the `doc-audit` skill — present findings — ask "Continue to /security-review? (yes / fix first)"
5. Invoke the `security-review` skill — present final findings

After /security-review completes, present the Overall QA Verdict table (same format as parallel mode above), summarising results from all five audits.

**PASS criteria:** zero findings in /cleanup, /frontend-audit, /backend-audit, /doc-audit, AND zero CRITICAL or HIGH findings in /security-review. MEDIUM and LOW security findings do not block PASS.

## Output

Present consolidated or sequential findings to the user. No file written to `.pipeline/`.

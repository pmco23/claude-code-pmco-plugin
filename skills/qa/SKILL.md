---
name: qa
description: Use after /build to run the full post-build QA pipeline. Supports --parallel (all audits simultaneously) or --sequential (denoise → qf → qb → qd → security-review in order). Requires .pipeline/build.complete.
---

# QA — Post-Build QA Pipeline

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
Prompt: `Invoke the denoise skill to audit this codebase for dead code. .pipeline/build.complete exists. Report all findings.`

**Agent 2 — Frontend Audit**
Prompt: `Invoke the qf skill to audit frontend code quality. .pipeline/build.complete exists. Report all findings.`

**Agent 3 — Backend Audit**
Prompt: `Invoke the qb skill to audit backend code quality. .pipeline/build.complete exists. Report all findings.`

**Agent 4 — Documentation Freshness**
Prompt: `Invoke the qd skill to check documentation freshness. .pipeline/build.complete exists. Report all findings.`

**Agent 5 — Security Review**
Prompt: `Invoke the security-review skill to scan for OWASP Top 10 vulnerabilities. .pipeline/build.complete exists. Report all findings.`

Wait for all five to complete, then present a consolidated report:

```markdown
# QA Report

## /denoise
[findings or "clean — no dead code found"]

## /qf — Frontend
[findings or "no violations found"]

## /qb — Backend
[findings or "no violations found"]

## /qd — Documentation
[findings or "all docs reflect current implementation"]

## /security-review
[findings or "no OWASP Top 10 vulnerabilities found"]
```

### Sequential Mode

Run in order, presenting each result before proceeding:

1. Invoke the `denoise` skill — present findings — ask "Continue to /qf? (yes / fix first)"
2. Invoke the `qf` skill — present findings — ask "Continue to /qb? (yes / fix first)"
3. Invoke the `qb` skill — present findings — ask "Continue to /qd? (yes / fix first)"
4. Invoke the `qd` skill — present findings — ask "Continue to /security-review? (yes / fix first)"
5. Invoke the `security-review` skill — present final findings

## Output

Present consolidated or sequential findings to the user. No file written to `.pipeline/`.

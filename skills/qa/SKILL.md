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

Launch 5 subagents at once:
- Agent 1: runs the denoise skill instructions
- Agent 2: runs the qf skill instructions
- Agent 3: runs the qb skill instructions
- Agent 4: runs the qd skill instructions
- Agent 5: runs the security-review skill instructions

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

1. Run denoise skill instructions — present findings — ask "Continue to /qf? (yes / fix first)"
2. Run qf skill instructions — present findings — ask "Continue to /qb? (yes / fix first)"
3. Run qb skill instructions — present findings — ask "Continue to /qd? (yes / fix first)"
4. Run qd skill instructions — present findings — ask "Continue to /security-review? (yes / fix first)"
5. Run security-review skill instructions — present final findings

## Output

Present consolidated or sequential findings to the user. No file written to `.pipeline/`.

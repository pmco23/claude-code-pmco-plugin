---
name: build
description: Use after /plan to execute the build. Opus leads and coordinates; Sonnets implement. Supports --parallel (independent agent per task group, own context) or --sequential (one task group at a time in current session). Runs /drift-check post-build. Writes .pipeline/build.complete on pass.
---

# BUILD — Parallel Build

## Role

> **Model:** Opus (`claude-opus-4-6`) for the lead role. Sonnet builders are dispatched by the lead — only the lead model matters here.

You are Opus acting as a build lead. You coordinate Sonnet builders. You never write implementation code. Your job is to unblock builders, catch coordination issues, and verify the build against the plan.

## Mode Selection

Check the invocation arguments:
- If `/build --parallel` was used: parallel mode
- If `/build --sequential` was used: sequential mode
- If no flag: ask the user before proceeding

```
Build mode:
  --parallel   Independent agents, each with own context, faster wall-clock time
  --sequential One task group at a time, easier to debug, review between groups

Which mode? (parallel / sequential)
```

## Process

### Step 0: Check for partial build state

Before reading the plan or dispatching any agents, check whether this is a fresh build or a resume.

Scan the working directory for files that would be created by task groups in the plan (if `.pipeline/plan.md` already exists, read it to find the "Files: Create" entries for each group).

If files from a previous partial build are detected, report to the user:
```
Partial build detected. The following task groups appear already complete (their output files exist):
- Group N: [list of existing files]

Resume from here (skip completed groups) or restart from scratch? (resume / restart)
```

- If "restart": delete `.pipeline/build.complete` if present and proceed to Step 1 with all groups active.
- If "resume": proceed to Step 1, mark completed groups as done, dispatch only remaining groups.
- If no prior files found: proceed to Step 1 normally.

### Step 1: Read the plan

Read `.pipeline/plan.md` in full. Extract:
- All task groups
- Their dependency ordering
- Which groups are parallel-safe
- The acceptance criteria for each group

### Step 2A: Parallel Mode

For each independent task group (those with no unmet dependencies), invoke the `task-builder` agent simultaneously. Issue all invocations in the same response turn.

Invocation for each group:
```
Implement Task Group [N] — [Name]
```

Monitor agent outputs. When an agent reports a blocker:
- Investigate the blocker
- Provide specific guidance to unblock
- Do not implement code yourself — describe what needs to change

After all parallel groups complete, run dependent groups in the same way.

### Step 2B: Sequential Mode

For each task group in dependency order:

1. Invoke the `task-builder` agent with the task group assignment (e.g., "Implement Task Group [N] — [Name]")
2. Wait for completion
3. Review the agent's output — did it satisfy the acceptance criteria?
4. If yes: proceed to next group
5. If no: provide specific correction guidance and re-invoke the `task-builder` agent

### Step 3: Post-build verification

After all task groups complete, run drift detection:

Dispatch a subagent via the Task tool with this prompt:
```
You are a drift verifier. Read `.pipeline/plan.md` in full. Extract every verifiable claim — file paths that should exist, function names that should be implemented, test cases that should pass, acceptance criteria that should be met.

For each claim, check whether the current working directory satisfies it:
- EXISTS: fully satisfied
- MISSING: not satisfied — describe what is absent
- PARTIAL: partially satisfied — describe what is missing
- CONTRADICTED: target actively contradicts the claim

Return a structured list: claim_id, claim, status, evidence.
Focus on MISSING and CONTRADICTED findings — these block build completion.
```

### Step 4: Evaluate /drift-check result

If /drift-check finds MISSING or CONTRADICTED claims:
- Identify which task group is responsible
- Re-invoke the `task-builder` agent for that group with specific remediation instructions
- Re-run /drift-check after remediation
- Repeat until /drift-check passes

### Step 5: Write build.complete

When /drift-check passes with no unresolved MISSING or CONTRADICTED findings:

```bash
mkdir -p .pipeline
touch .pipeline/build.complete
```

Confirm: "Build complete and verified. Run `/qa` for post-build audits."

## Lead Rules

1. **Never write implementation code.** If you find yourself about to write code, stop. Describe what the agent needs to do instead.
2. **One job: coordinate and unblock.** Route information between agents. Resolve blockers. Keep context narrow for each agent.
3. **Separate contexts.** Each builder gets only the context for their task group. Do not cross-contaminate.

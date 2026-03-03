---
name: build
description: Use after /plan to execute the build. Opus leads and coordinates; Sonnets implement. Supports --parallel (independent agent per task group, own context) or --sequential (one task group at a time in current session). Invokes drift-verifier agent post-build. Writes .pipeline/build.complete on pass.
---

# BUILD

## Role

> **Model:** Opus (`claude-opus-4-6`) for the lead role. Sonnet builders are dispatched by the lead — only the lead model matters here.

You are Opus acting as a build lead. You coordinate Sonnet builders. You never write implementation code. Your job is to unblock builders, catch coordination issues, and verify the build against the plan.

## Mode Selection

Check the invocation arguments:
- If `/build --parallel` was used: parallel mode
- If `/build --sequential` was used: sequential mode
- If no flag: ask the user before proceeding

Use AskUserQuestion with:
  question: "Which build mode?"
  header: "Build mode"
  options:
    - label: "Parallel"
      description: "Independent agents each with own context — faster wall-clock time"
    - label: "Sequential"
      description: "One task group at a time — easier to debug, review between groups"

## Hard Rules

1. **Never write implementation code.** If you find yourself about to write code, stop. Describe what the agent needs to do textually instead.
2. **One job: coordinate and unblock.** Dispatch builders using the Agent or Task tool with the `task-builder` agent. Route information between agents. Resolve blockers. Keep context narrow for each agent.
3. **Separate contexts.** Each builder gets only the context for their task group. Do not cross-contaminate.

## Process

### Step 0: Check for partial build state

Before reading the plan or dispatching any agents, check whether this is a fresh build or a resume.

First, call TaskList. If tasks from a prior build are present (status: in_progress or completed), use that as the authoritative source of which groups have already run. File-based detection is a secondary cross-check only.

Then scan the working directory for files that would be created by task groups in the plan (if `.pipeline/plan.md` already exists, read it to find the "Files: Create" entries for each group — Step 1 defines the full plan schema).

If tasks or files from a previous partial build are detected, use AskUserQuestion with:
  question: "Partial build detected. Groups [list] appear already complete. How to proceed?"
  header: "Resume build"
  options:
    - label: "Resume"
      description: "Skip completed groups, dispatch only remaining ones"
    - label: "Restart"
      description: "Delete .pipeline/build.complete and re-run all groups from scratch"

- If "Restart": delete `.pipeline/build.complete` if present and proceed to Step 1 with all groups active.
- If "Resume": proceed to Step 1, mark completed groups as done, dispatch only remaining groups.
- If no prior tasks or files found: proceed to Step 1 normally.

### Step 1: Read the plan

Read `.pipeline/plan.md` in full. Extract:
- All task groups
- Their dependency ordering
- Which groups are parallel-safe
- The acceptance criteria for each group

After extracting all task groups, call TaskList. Only call TaskCreate for groups that do NOT already have a corresponding task (match by subject prefix "Task Group [N]"). For groups that already have tasks, use those existing task IDs going forward.

If this is a fresh build (no existing tasks): call TaskCreate for each group:
- subject: "Task Group [N] — [Name]"
- description: "[from the task group's Context for agent section]"
- activeForm: "Building Task Group [N] — [Name]"

This creates a persistent task list that survives context compaction.

### Step 2A: Parallel Mode

For each independent task group (those with no unmet dependencies), invoke the `task-builder` agent simultaneously. Issue all invocations in the same response turn.

Before dispatching each task group agent, call TaskUpdate with status: "in_progress" for that task.

Invocation for each group:
```
Implement Task Group [N] — [Name]
```

Monitor agent outputs. When an agent reports a blocker:
- Investigate the blocker
- Provide specific guidance to unblock
- Do not implement code yourself — describe what needs to change
- Call TaskUpdate to record the blocker in the task description

After each agent reports success and acceptance criteria are verified, call TaskUpdate with status: "completed".

If an agent reports 3 consecutive failures on the same task group without progress, stop retrying. Escalate to the user: present the failing criteria, the agent's last output, and ask how to proceed before making any further attempts.

After all parallel groups complete, run dependent groups in the same way.

### Step 2B: Sequential Mode

For each task group in dependency order:

1. Call TaskUpdate with status: "in_progress" for the task group
2. Invoke the `task-builder` agent with the task group assignment (e.g., "Implement Task Group [N] — [Name]")
3. Wait for completion
4. Review the agent's output — did it satisfy the acceptance criteria?
5. If yes: call TaskUpdate with status: "completed" and proceed to next group
6. If no: call TaskUpdate to record the blocker in the task description, provide specific correction guidance, and re-invoke the `task-builder` agent

Keep a retry counter per task group. After 3 consecutive failures on the same acceptance criteria, stop retrying. Escalate to the user: present the failing criteria, the agent's last output, and ask how to proceed before making any further attempts.

### Step 3: Post-build verification

After all task groups complete, run drift detection:

Invoke the `drift-verifier` agent with:
  Source: `.pipeline/plan.md`
  Target: current working directory

Wait for the agent's structured claim list (claim_id, claim, status, evidence).

### Step 4: Evaluate drift-verifier result

If the drift-verifier finds MISSING or CONTRADICTED claims:
- Identify which task group is responsible
- Re-invoke the `task-builder` agent for that group with specific remediation instructions
- Re-run the drift-verifier agent after remediation

After 2 consecutive drift-verifier failures on the same claim, stop retrying. Escalate to the user: present the failing claims, the agent's last output, and ask how to proceed before making any further attempts.

### Step 5: Write build.complete

When the drift-verifier passes with no unresolved MISSING or CONTRADICTED findings:

```bash
mkdir -p .pipeline
touch .pipeline/build.complete
```

Confirm: "Build complete and verified. Run `/qa` for post-build audits."


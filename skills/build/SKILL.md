---
name: build
description: Use after /plan to execute the build. Opus leads and coordinates; Sonnets implement. Supports --parallel (independent Task-tool subagent per task group, own context) or --sequential (one task group at a time in current session). Invokes drift-verifier post-build. Writes .pipeline/build.complete on pass.
argument-hint: [--parallel | --sequential]
disable-model-invocation: true
---

# BUILD

## Role

> **Model:** Opus (`claude-opus-4-6`) for the lead role. Sonnet builders are dispatched by the lead — only the lead model matters here.

You are Opus acting as a build lead. You coordinate Sonnet build subagents via the Task tool. You never write implementation code. Your job is to unblock builders, catch coordination issues, and verify the build against the plan.

## Mode Selection

Check the invocation arguments:
- If `/build --parallel` was used: parallel mode
- If `/build --sequential` was used: sequential mode
- If no flag: ask the user before proceeding

Prefer AskUserQuestion with:
  question: "Which build mode?"
  header: "Build mode"
  options:
    - label: "Parallel"
      description: "Independent subagents each with own context — faster wall-clock time"
    - label: "Sequential"
      description: "One task group at a time — easier to debug, review between groups"

If structured prompts are unavailable in this runtime, ask a single plain-text question instead: "Which build mode: parallel or sequential?"

## Hard Rules

1. **Never write implementation code.** If you find yourself about to write code, stop. Describe what the agent needs to do textually instead.
2. **One job: coordinate and unblock.** Dispatch builders via the Task tool using the `task-builder` subagent. Route information between runs. Resolve blockers. Keep context narrow for each subagent.
3. **Separate contexts.** Each builder gets only the context for their task group. Do not cross-contaminate.
4. **3-failure escalation.** After 3 consecutive agent failures on the same task group, stop retrying. Escalate to the user: present the failing criteria, the agent's last output, and ask how to proceed before any further attempts.
5. **Progress tracking degrades gracefully.** If TaskList / TaskCreate / TaskUpdate helpers are available, use them. If they are not available in this runtime, keep the same state in a concise inline checklist and continue the build instead of blocking on missing task helpers.

## Process

### Step 0: Check for partial build state

Read the "Partial Build Detection" section in `references/build-procedures.md` from this skill's base directory. Follow it to determine whether to resume or restart.

### Step 1: Read the plan

Read `.pipeline/plan.md` in full. Extract all task groups, their dependency ordering, which groups are parallel-safe, and the acceptance criteria for each group.

Then follow the "Task Creation" section in `references/build-procedures.md` to create or reuse task-tracking entries when the runtime supports them.

### Step 2A: Parallel Mode

For each independent task group (those with no unmet dependencies), invoke the `task-builder` subagent via the Task tool simultaneously. Issue all invocations in the same response turn.

Before dispatching each task group, mark it `in_progress` using TaskUpdate if available. Otherwise add it to the inline checklist as `in_progress`.

Invocation for each group:
```
Implement Task Group [N] — [Name]
```

Monitor subagent outputs. When blocked: investigate, provide textual guidance (never code), and record the blocker in TaskUpdate or the inline checklist. After success + acceptance criteria verified: mark the task `completed`.

Apply 3-failure escalation (Hard Rule #4) if needed. After all parallel groups complete, dispatch dependent groups the same way.

### Step 2B: Sequential Mode

For each task group in dependency order:

1. Mark the task `in_progress` via TaskUpdate or the inline checklist
2. Invoke `task-builder` via the Task tool: "Implement Task Group [N] — [Name]"
3. Review output against acceptance criteria
4. Pass → mark `completed`, next group
5. Fail → record blocker, provide correction guidance, re-invoke

Apply 3-failure escalation (Hard Rule #4) if needed.

### Steps 3–5: Post-build verification

Read the "Post-Build Drift Verification" section in `references/build-procedures.md` from this skill's base directory. Follow it to run drift detection, evaluate results, remediate if needed, and write `.pipeline/build.complete` on pass.

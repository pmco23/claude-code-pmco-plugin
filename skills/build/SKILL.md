---
name: build
description: Use after /plan to execute the build. Opus leads and coordinates; Sonnets implement. Supports --parallel (independent agent per task group, own context) or --sequential (one task group at a time in current session). Runs /pmatch post-build. Writes .pipeline/build.complete on pass.
---

# BUILD — Parallel Build

## Role

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

### Step 1: Read the plan

Read `.pipeline/plan.md` in full. Extract:
- All task groups
- Their dependency ordering
- Which groups are parallel-safe
- The acceptance criteria for each group

### Step 2A: Parallel Mode

For each independent task group (those with no unmet dependencies), dispatch a Sonnet subagent simultaneously via the Task tool.

Agent prompt template for each group:
```
You are a Sonnet build agent implementing one task group from an execution plan.

Read your task group from .pipeline/plan.md: Task Group [N] — [Name]

Your constraints:
- Only touch the files listed in your task group's Files section
- Follow the exact patterns shown in the code examples
- Implement all named test cases with the specified assertions
- Do not modify files from other task groups

When complete, report:
- Files created/modified
- Tests written and their pass/fail status
- Any blockers you encountered
```

Monitor agent outputs. When an agent reports a blocker:
- Investigate the blocker
- Provide specific guidance to unblock
- Do not implement code yourself — describe what needs to change

After all parallel groups complete, run dependent groups in the same way.

### Step 2B: Sequential Mode

For each task group in dependency order:

1. Dispatch one Sonnet subagent with the task group prompt above
2. Wait for completion
3. Review the agent's output — did it satisfy the acceptance criteria?
4. If yes: proceed to next group
5. If no: provide specific correction guidance and re-dispatch

### Step 3: Post-build verification

After all task groups complete, run /pmatch:

Source of truth: `.pipeline/plan.md`
Target: current working directory

Invoke /pmatch by dispatching a subagent with the pmatch skill instructions.

### Step 4: Evaluate /pmatch result

If /pmatch finds MISSING or CONTRADICTED claims:
- Identify which task group is responsible
- Re-dispatch that task group's Sonnet agent with specific remediation instructions
- Re-run /pmatch after remediation
- Repeat until /pmatch passes

### Step 5: Write build.complete

When /pmatch passes with no unresolved MISSING or CONTRADICTED findings:

```bash
mkdir -p .pipeline
touch .pipeline/build.complete
```

Confirm: "Build complete and verified. Run `/qa` for post-build audits."

## Lead Rules

1. **Never write implementation code.** If you find yourself about to write code, stop. Describe what the agent needs to do instead.
2. **One job: coordinate and unblock.** Route information between agents. Resolve blockers. Keep context narrow for each agent.
3. **Separate contexts.** Each builder gets only the context for their task group. Do not cross-contaminate.

---
name: plan
description: Use after /review to transform the approved design into an atomic execution plan. Writes task groups with exact file paths, complete code examples, and named test cases with assertions. Build agents must never need to ask clarifying questions. Writes .pipeline/plan.md.
disable-model-invocation: true
---

# PLAN — Atomic Execution Planning

## Role

> **Model:** Opus (`claude-opus-4-6`).

You are Opus acting as a technical lead writing a build spec. The target audience is a Sonnet agent that knows nothing about this project. If a builder has to guess anything, you have failed.

## Hard Rules

1. **Exact file paths.** No "in the components directory" — give `src/components/UserCard/UserCard.tsx`.
2. **Complete code.** No "add validation here" — write the actual validation code.
3. **Named test cases with assertions.** Define what to test and what the assertion is, not just "write tests".
4. **Non-negotiable acceptance criteria.** Each task either passes its criteria or does not. No ambiguity.
5. **Flag parallelism.** Explicitly mark which task groups can run in parallel and which must be sequential.
6. **TDD task ordering.** Every task group lists tests before implementation: Task N.1 =
   named test cases with assertions, Task N.2 = minimal production code to pass them,
   Task N.3 = verify green + refactor. Never list implementation before tests.
   **Exception:** if `tdd: disabled` is found in the project's `CLAUDE.md`, task ordering
   reverts to implementation-first (Task N.1 = implement, Task N.2 = write tests) and the
   plan header must declare `**TDD:** disabled`.

## Process

### Step 1: Read design and brief

Read `.pipeline/design.md` and `.pipeline/brief.md` in full.

Check the project's `CLAUDE.md` for the line `tdd: disabled`. If found, Hard Rule 6
is waived for this plan run — use implementation-first task ordering (Task N.1 = implement,
Task N.2 = write tests). Record the result: TDD mode is **enabled** (default) or **disabled**.

### Step 2: Ground file paths in the actual project structure

Before writing any task group, scan the real project layout so the plan's file paths match reality.

Run `Glob("**/*")` with depth ≤ 3 and read the primary language config file (`package.json`, `go.mod`, `requirements.txt`, `*.csproj` — whichever exists at root).

Use this to:
- Confirm actual directory names and naming conventions (kebab-case vs snake_case, flat vs nested)
- Correct any file paths in the design that don't match the real layout
- Ensure new files are placed in existing directories where possible
- Flag in the task group if a new directory needs to be created first

### Step 3: Decompose into task groups

Group the work into independent task groups. A task group is a set of tasks that:
- Can be assigned to one agent with one coherent context
- Does not modify files that another concurrent task group modifies
- Produces a testable artifact on its own

Aim for ~5 tasks per group. More than 8 tasks in a group is a smell — split it.

### Step 4: Order and dependency mapping

For each task group:
- Which groups must complete before this one can start?
- Which groups can run in parallel with this one?

Produce a dependency map:
```
Group A ──┬── Group C (depends on A and B)
Group B ──┘
Group D (independent, can run with A and B)
```

### Step 5: Write the plan

Read `references/task-group-template.md` from this skill's base directory. Use that format for every task group in `.pipeline/plan.md`.

### Step 6: Cross-check for conflicts

1. Collect every file path listed under "Modify" or "Create" in each task group's `### Files` section.
2. Build a map: `file path → [list of task groups that touch it]`.
3. For each file that appears in two or more task groups, check whether those groups are marked parallel-safe with each other.
4. If a file is shared between two parallel-safe groups, resolve using one of:
   - **Make sequential:** remove the parallel-safe relationship and add a `Must run after` dependency.
   - **Split the shared edit:** extract the modification into a new task group that runs before both.
5. After resolving all conflicts, verify the map again — no file should appear in two groups that are still marked parallel-safe.

Document any conflicts found and how they were resolved in a `## Conflict Resolution` section at the end of `.pipeline/plan.md`.

## Output

Confirm: "Plan written to `.pipeline/plan.md`. Run `/build --parallel` or `/build --sequential`."

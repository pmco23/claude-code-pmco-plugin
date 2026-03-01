# Plugin Quality Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix all 12 issues identified in the plugin evaluation: 2 high-severity dispatch bugs, 3 medium-severity gaps, and 7 low-severity UX and correctness issues.

**Architecture:** All fixes are SKILL.md prose edits, one new skill file (`status`), and one README update. No hook changes needed (the gate already passes unknown skills through, so `/status` is automatically allowed). Tasks are grouped by file — most are independent and parallel-safe.

**Tech Stack:** Bash (test verification only), Markdown (SKILL.md edits), grep/cat for verification.

---

## Parallelism Map

```
Task 1 (qa)        ──┐
Task 2 (build)     ──┤
Task 3 (ar)        ──┤── All parallel-safe (different files)
Task 4 (qf + qb)   ──┤
Task 5 (denoise)   ──┤
Task 6 (security)  ──┤
Task 7 (qd)        ──┤
Task 8 (init)      ──┘
Task 9 (status)    ── Independent
Task 10 (README)   ── Depends on Task 9 (needs /status docs)
```

---

## Task 1: Fix `/qa` Parallel Dispatch Ambiguity

**Severity:** High — "runs the denoise skill instructions" is not actionable for a subagent

**Files:**
- Modify: `skills/qa/SKILL.md` (lines 27–34, Parallel Mode section)

**What to change:**

Replace the vague "Launch 5 subagents at once" block with explicit Task tool prompts per agent.

**Step 1: Verify current text**

Run:
```bash
grep -n "runs the denoise skill" skills/qa/SKILL.md
```
Expected: match on one line around line 30.

**Step 2: Apply edit**

In `skills/qa/SKILL.md`, replace the Parallel Mode dispatch block:

Old text (lines ~27–34):
```
Dispatch all five QA skills simultaneously via the Task tool. Each agent receives only the context for its specific audit.

Launch 5 subagents at once:
- Agent 1: runs the denoise skill instructions
- Agent 2: runs the qf skill instructions
- Agent 3: runs the qb skill instructions
- Agent 4: runs the qd skill instructions
- Agent 5: runs the security-review skill instructions
```

New text:
```
Dispatch all five QA skills simultaneously via the Task tool. Each agent receives only the context for its specific audit.

Use the Task tool to launch 5 subagents at once. Prompt for each:

**Agent 1 — Dead Code Removal**
```
Invoke the `denoise` skill to audit this codebase for dead code. `.pipeline/build.complete` exists. Report all findings.
```

**Agent 2 — Frontend Audit**
```
Invoke the `qf` skill to audit frontend code quality. `.pipeline/build.complete` exists. Report all findings.
```

**Agent 3 — Backend Audit**
```
Invoke the `qb` skill to audit backend code quality. `.pipeline/build.complete` exists. Report all findings.
```

**Agent 4 — Documentation Freshness**
```
Invoke the `qd` skill to check documentation freshness. `.pipeline/build.complete` exists. Report all findings.
```

**Agent 5 — Security Review**
```
Invoke the `security-review` skill to scan for OWASP Top 10 vulnerabilities. `.pipeline/build.complete` exists. Report all findings.
```
```

Also fix the Sequential Mode section. Replace the vague "Run denoise skill instructions" phrases:

Old text (lines ~61–65):
```
1. Run denoise skill instructions — present findings — ask "Continue to /qf? (yes / fix first)"
2. Run qf skill instructions — present findings — ask "Continue to /qb? (yes / fix first)"
3. Run qb skill instructions — present findings — ask "Continue to /qd? (yes / fix first)"
4. Run qd skill instructions — present findings — ask "Continue to /security-review? (yes / fix first)"
5. Run security-review skill instructions — present final findings
```

New text:
```
1. Invoke the `denoise` skill — present findings — ask "Continue to /qf? (yes / fix first)"
2. Invoke the `qf` skill — present findings — ask "Continue to /qb? (yes / fix first)"
3. Invoke the `qb` skill — present findings — ask "Continue to /qd? (yes / fix first)"
4. Invoke the `qd` skill — present findings — ask "Continue to /security-review? (yes / fix first)"
5. Invoke the `security-review` skill — present final findings
```

**Step 3: Verify edit**

Run:
```bash
grep -n "Invoke the" skills/qa/SKILL.md
```
Expected: 10 matches (5 parallel prompts + 5 sequential steps).

Run:
```bash
grep -c "runs the.*skill instructions" skills/qa/SKILL.md
```
Expected: `0`

**Step 4: Commit**

```bash
git add skills/qa/SKILL.md
git commit -m "fix: clarify /qa subagent dispatch — explicit Skill invocations in parallel and sequential mode"
```

---

## Task 2: Fix `/build` Dispatch Ambiguity + Partial Resume + Model Tiering

**Severity:** High (dispatch) + Medium (resume + model tiering)

**Files:**
- Modify: `skills/build/SKILL.md`

**What to change:**

Three fixes in one file:

### Fix 2a — pmatch dispatch (Step 3)

**Step 1: Verify current text**

Run:
```bash
grep -n "dispatching a subagent with the pmatch skill instructions" skills/build/SKILL.md
```
Expected: one match.

**Step 2: Apply edit**

Old text:
```
Invoke /pmatch by dispatching a subagent with the pmatch skill instructions.
```

New text:
```
Invoke /pmatch by dispatching a subagent via the Task tool with this prompt:
```
Invoke the `pmatch` skill to verify implementation drift.
Source of truth: `.pipeline/plan.md`
Target: current working directory
Report all MISSING, PARTIAL, and CONTRADICTED findings.
```
```

### Fix 2b — Builder model tiering (Step 2A agent prompt)

**Step 3: Verify current text**

Run:
```bash
grep -n "You are a Sonnet build agent" skills/build/SKILL.md
```
Expected: one match.

**Step 4: Apply edit**

The agent prompt in Step 2A opens with:
```
You are a Sonnet build agent implementing one task group from an execution plan.
```

Add an explicit dispatch instruction BEFORE the agent prompt block. Locate the sentence "dispatch a Sonnet subagent simultaneously via the Task tool" and add:

Old text:
```
For each independent task group (those with no unmet dependencies), dispatch a Sonnet subagent simultaneously via the Task tool.

Agent prompt template for each group:
```
You are a Sonnet build agent implementing one task group from an execution plan.
```

New text:
```
For each independent task group (those with no unmet dependencies), dispatch a Sonnet subagent simultaneously via the Task tool. Set `model: sonnet` on each dispatch.

Agent prompt template for each group:
```
You are a Sonnet build agent implementing one task group from an execution plan.
```

Do the same for Step 2B (sequential mode):

Old text:
```
For each task group in dependency order:

1. Dispatch one Sonnet subagent with the task group prompt above
```

New text:
```
For each task group in dependency order:

1. Dispatch one Sonnet subagent with the task group prompt above (set `model: sonnet`)
```

### Fix 2c — Partial build resume (new Step 0)

**Step 5: Apply edit**

Insert a new Step 0 before the existing "Step 1: Read the plan":

New section to insert:
```
### Step 0: Check for partial build state

Before reading the plan or dispatching any agents, check whether this is a fresh build or a resume:

- Run `ls .pipeline/` to see what artifacts exist.
- Scan the working directory for files that would be created by each task group (read their "Files: Create" entries from the plan if the plan exists).

If files from a previous partial build are detected, report to the user:
```
Partial build detected. The following task groups appear to have been completed (their output files exist):
- Group N: [list of existing files]

Resume from where it left off (skip completed groups) or start fresh? (resume / restart)
```

If "restart": delete build artifacts (`rm -f .pipeline/build.complete`) and proceed to Step 1 with all groups active.
If "resume": proceed to Step 1, mark completed groups as done, dispatch only remaining groups.
```

**Step 6: Verify all edits**

Run:
```bash
grep -n "model: sonnet" skills/build/SKILL.md
```
Expected: 2 matches (parallel and sequential dispatch).

Run:
```bash
grep -n "Partial build detected" skills/build/SKILL.md
```
Expected: 1 match.

Run:
```bash
grep -c "dispatching a subagent with the pmatch skill instructions" skills/build/SKILL.md
```
Expected: `0`

**Step 7: Commit**

```bash
git add skills/build/SKILL.md
git commit -m "fix: clarify /build dispatch — explicit pmatch invocation, model tiering, partial build resume"
```

---

## Task 3: Fix `/ar` Model Tiering + Update Design Loop

**Severity:** Medium (both sub-issues)

**Files:**
- Modify: `skills/ar/SKILL.md`

**What to change:**

### Fix 3a — Model tiering for Opus strategic critic

**Step 1: Verify current text**

Run:
```bash
grep -n "Dispatch a subagent with this prompt" skills/ar/SKILL.md
```
Expected: match for Agent 1 dispatch.

**Step 2: Apply edit**

Locate the Agent 1 dispatch instruction (around line 29–30). Add model spec:

Old text:
```
**Agent 1 — Opus Strategic Critic**

Dispatch a subagent with this prompt:
```

New text:
```
**Agent 1 — Opus Strategic Critic**

Dispatch a subagent via the Task tool with `model: opus` and this prompt:
```

### Fix 3b — Update design loop: clarify who writes the revised design

**Step 3: Verify current text**

Run:
```bash
grep -n "update design:" skills/ar/SKILL.md
```
Expected: one match.

**Step 4: Apply edit**

Old text:
```
- **update design:** wait for the user to modify `.pipeline/design.md`, then run the next round (return to Step 2)
```

New text:
```
- **update design:** Based on the findings that require action, draft the specific changes to `.pipeline/design.md`. Present each proposed change as a diff (old text → new text). Wait for the user to confirm each change, apply them to `.pipeline/design.md`, then return to Step 2 for the next review round.
```

**Step 5: Verify both edits**

Run:
```bash
grep -n "model: opus" skills/ar/SKILL.md
```
Expected: 1 match.

Run:
```bash
grep -n "draft the specific changes" skills/ar/SKILL.md
```
Expected: 1 match.

**Step 6: Commit**

```bash
git add skills/ar/SKILL.md
git commit -m "fix: /ar — explicit Opus model for strategic critic, clarify who drafts design updates in review loop"
```

---

## Task 4: Fix TypeScript Scope Overlap + Remediation Guidance in `/qf` and `/qb`

**Severity:** Low (overlap noise + missing guidance)

**Files:**
- Modify: `skills/qf/SKILL.md`
- Modify: `skills/qb/SKILL.md`

### Fix 4a — `/qf`: scope clarification + remediation guidance

**Step 1: Verify current role statement**

Run:
```bash
grep -n "You are Sonnet acting as a frontend code reviewer" skills/qf/SKILL.md
```
Expected: 1 match.

**Step 2: Apply scope clarification**

Old text (Role section):
```
You are Sonnet acting as a frontend code reviewer. Audit against the project's own style guide — not generic best practices. If no style guide exists, infer conventions from the existing codebase.
```

New text:
```
You are Sonnet acting as a frontend code reviewer. Audit frontend TypeScript/JavaScript/CSS/HTML only. For backend TypeScript (Node.js APIs, Express servers, CLI tools), defer to `/qb`. Audit against the project's own style guide — not generic best practices. If no style guide exists, infer conventions from the existing codebase.
```

**Step 3: Add remediation guidance to Output section**

Old text (## Output section):
```
Report to user. No file written to `.pipeline/`.
```

New text:
```
Report to user. No file written to `.pipeline/`.

After reviewing findings, use `/quick` to address individual items. Re-run `/qf` after fixing to confirm they are resolved.
```

### Fix 4b — `/qb`: scope clarification + remediation guidance

**Step 4: Apply scope clarification**

Old text (Role section):
```
You are Sonnet acting as a backend code reviewer. Audit against the project's own style guide and language idioms — not generic linting rules. Match what the codebase already does.
```

New text:
```
You are Sonnet acting as a backend code reviewer. For TypeScript projects, audit backend TypeScript only (Node.js, APIs, CLI tools) — frontend TypeScript components are covered by `/qf`. Audit against the project's own style guide and language idioms — not generic linting rules. Match what the codebase already does.
```

**Step 5: Add remediation guidance to Output section**

Old text:
```
Report to user. No file written to `.pipeline/`.
```

New text:
```
Report to user. No file written to `.pipeline/`.

After reviewing findings, use `/quick` to address individual items. Re-run `/qb` after fixing to confirm they are resolved.
```

**Step 6: Verify both edits**

Run:
```bash
grep -n "defer to" skills/qf/SKILL.md
```
Expected: 1 match.

Run:
```bash
grep -n "frontend TypeScript" skills/qb/SKILL.md
```
Expected: 1 match.

Run:
```bash
grep -c "Re-run" skills/qf/SKILL.md skills/qb/SKILL.md
```
Expected: `1` in each file.

**Step 7: Commit**

```bash
git add skills/qf/SKILL.md skills/qb/SKILL.md
git commit -m "fix: /qf and /qb — clarify TypeScript scope split, add post-fix remediation guidance"
```

---

## Task 5: Fix `/denoise` Overlap Note + Remediation Guidance

**Severity:** Low

**Files:**
- Modify: `skills/denoise/SKILL.md`

**Step 1: Verify current Output section**

Run:
```bash
grep -n "Report: .Removed" skills/denoise/SKILL.md
```
Expected: 1 match.

**Step 2: Add overlap note to Step 2 (static analysis section)**

Locate the "If LSP is not available" block. After the bullet about "imports with no usages in the file", add a note:

Old text (end of static analysis block, around line 29):
```
- Identify functions/methods with no callers (search for their name across codebase)
```

New text:
```
- Identify functions/methods with no callers (search for their name across codebase)

**Note:** If running as part of `/qa --parallel`, `/qb` also checks unused imports for Go and TypeScript. Expect overlapping findings for that category — both reports are correct.
```

**Step 3: Add remediation guidance to Output section**

Old text:
```
Report: "Removed [N] dead code items across [M] files."
```

New text:
```
Report: "Removed [N] dead code items across [M] files."

If items were skipped (user chose "review each"), use `/quick` to address them individually and re-run `/denoise` to confirm.
```

**Step 4: Verify**

Run:
```bash
grep -n "overlapping findings" skills/denoise/SKILL.md
```
Expected: 1 match.

**Step 5: Commit**

```bash
git add skills/denoise/SKILL.md
git commit -m "fix: /denoise — note /qb overlap for unused imports, add remediation guidance"
```

---

## Task 6: Add Remediation Guidance to `/security-review`

**Severity:** Low

**Files:**
- Modify: `skills/security-review/SKILL.md`

**Step 1: Verify current Output section**

Run:
```bash
grep -n "Report to user. No file written" skills/security-review/SKILL.md
```
Expected: 1 match.

**Step 2: Apply edit**

Old text:
```
Report to user. No file written to `.pipeline/`.
```

New text:
```
Report to user. No file written to `.pipeline/`.

After reviewing findings, use `/quick` to address individual items. For CRITICAL and HIGH severity findings, fix and re-run `/security-review` to confirm remediation before merging.
```

**Step 3: Verify**

Run:
```bash
grep -n "re-run" skills/security-review/SKILL.md
```
Expected: 1 match.

**Step 4: Commit**

```bash
git add skills/security-review/SKILL.md
git commit -m "fix: /security-review — add remediation guidance with re-run instruction for critical findings"
```

---

## Task 7: Fix `/qd` CHANGELOG Check + Remediation Guidance

**Severity:** Low (shallow check) + Low (missing guidance)

**Files:**
- Modify: `skills/qd/SKILL.md`

**Step 1: Verify current CHANGELOG step**

Run:
```bash
grep -n "Check CHANGELOG" skills/qd/SKILL.md
```
Expected: 1 match (Step 4 header).

**Step 2: Apply edit to Step 4**

Old text (Step 4):
```
### Step 4: Check CHANGELOG

- Is there an entry for the changes made in this build?
- If no entry exists, flag it: "CHANGELOG has no entry for current build changes."
```

New text:
```
### Step 4: Check CHANGELOG

Read `.pipeline/plan.md` (if it exists) to identify the feature name and scope of what was built.

Check `CHANGELOG.md`:
- Is there an `## [Unreleased]` section?
- Does it contain entries that correspond to the feature described in the plan (matching the plan's feature name or the types of changes made)?
- If no matching entry exists: flag as `CHANGELOG MISSING — no entry for [feature name] build. Add entries under ## [Unreleased] following Keep a Changelog format (Added / Changed / Fixed / Removed).`
- If `.pipeline/plan.md` does not exist (standalone run), check only that `## [Unreleased]` has any content; flag if it is empty.
```

**Step 3: Add remediation guidance to Output section**

Old text:
```
Report to user. No file written to `.pipeline/`.
```

New text:
```
Report to user. No file written to `.pipeline/`.

After reviewing findings, use `/quick` to update stale documentation or add CHANGELOG entries. Re-run `/qd` after fixing to confirm.
```

**Step 4: Verify both edits**

Run:
```bash
grep -n "plan.md" skills/qd/SKILL.md
```
Expected: 2 matches (one in Step 4, one in the fallback condition).

Run:
```bash
grep -n "Re-run" skills/qd/SKILL.md
```
Expected: 1 match.

**Step 5: Commit**

```bash
git add skills/qd/SKILL.md
git commit -m "fix: /qd — ground CHANGELOG check against plan.md, add remediation guidance"
```

---

## Task 8: Fix `/init` Pipeline Orientation at End

**Severity:** Low

**Files:**
- Modify: `skills/init/SKILL.md`

**Step 1: Verify current Step 7 output**

Run:
```bash
grep -n "Run /git-workflow before committing" skills/init/SKILL.md
```
Expected: 1 match.

**Step 2: Apply edit**

Old text (Step 7 confirmation block, last line):
```
Run /git-workflow before committing these files.
```

New text:
```
Run /git-workflow before committing these files.

To start developing a new feature on this project, run /arm to crystallize requirements into a pipeline brief.
```

**Step 3: Verify**

Run:
```bash
grep -n "run /arm" skills/init/SKILL.md
```
Expected: 1 match.

**Step 4: Commit**

```bash
git add skills/init/SKILL.md
git commit -m "fix: /init — add pipeline orientation hint pointing to /arm after boilerplate generation"
```

---

## Task 9: Create `/status` Skill

**Severity:** Low (missing feature)

**Files:**
- Create: `skills/status/SKILL.md`

**Note on the gate:** The hook's `case` statement has no entry for `status`, so it falls through to `exit 0` — the skill is automatically allowed. No hook change needed.

**Step 1: Create the skill directory**

Run:
```bash
mkdir -p skills/status
```

**Step 2: Write `skills/status/SKILL.md`**

Content:
```markdown
---
name: status
description: Use at any time to check the current pipeline state. Reports which .pipeline/ artifacts exist and what phase the pipeline is in. No gate — always available.
---

# STATUS — Pipeline State Check

## Role

You are reporting the current pipeline phase to the user. Read the `.pipeline/` directory and provide a clear, one-glance summary.

## Process

### Step 1: Find the pipeline directory

Walk up from the current working directory looking for a `.pipeline/` directory (same logic as the gate hook). If none found, report "No pipeline active in this directory tree."

### Step 2: Check artifacts

For each artifact, check whether it exists:

| Artifact | Skill that writes it | Status |
|----------|---------------------|--------|
| `.pipeline/brief.md` | `/arm` | exists / missing |
| `.pipeline/design.md` | `/design` | exists / missing |
| `.pipeline/design.approved` | `/ar` | exists / missing |
| `.pipeline/plan.md` | `/plan` | exists / missing |
| `.pipeline/build.complete` | `/build` | exists / missing |

### Step 3: Determine current phase

Derive the current phase from the artifacts:

| Condition | Phase | Next step |
|-----------|-------|-----------|
| No artifacts | Not started | Run `/arm` |
| Only `brief.md` | Requirements crystallized | Run `/design` |
| `brief.md` + `design.md`, no `design.approved` | Design written, pending review | Run `/ar` |
| `design.approved`, no `plan.md` | Design approved | Run `/plan` |
| `plan.md`, no `build.complete` | Plan ready / build in progress | Run `/build` |
| `build.complete` | Build complete | Run `/qa` |

### Step 4: Report

Print a status block:

```
Pipeline status: [phase name]

  brief.md         [✓ exists | ✗ missing]
  design.md        [✓ exists | ✗ missing]
  design.approved  [✓ exists | ✗ missing]
  plan.md          [✓ exists | ✗ missing]
  build.complete   [✓ exists | ✗ missing]

Next: [next step]
```

If `build.complete` exists, also check whether QA findings exist in the session (they are not written to disk). If QA has been run this session, note: "QA ran this session — check session history for findings."

## Output

Status block printed to user. Nothing written to `.pipeline/`.

To reset the pipeline to a specific phase, remove artifacts manually:
- Full reset: `rm -rf .pipeline/`
- Re-open from design: `rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete`
- Re-open from review: `rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete`
- Re-open from plan: `rm .pipeline/plan.md .pipeline/build.complete`
- Re-open from build: `rm .pipeline/build.complete`
```

**Step 3: Verify the file exists and has the frontmatter**

Run:
```bash
grep -n "name: status" skills/status/SKILL.md
```
Expected: 1 match on line 2.

Run:
```bash
grep -c "✓ exists" skills/status/SKILL.md
```
Expected: `5` (one per artifact in the report template).

**Step 4: Commit**

```bash
git add skills/status/SKILL.md
git commit -m "feat: add /status skill — pipeline state inspection, always available, no gate"
```

---

## Task 10: Update README

**Severity:** Low (documentation completeness)

**Dependencies:** Task 9 must be complete (status skill must exist before documenting it).

**Files:**
- Modify: `README.md`

**Changes required:**

### 10a — Add `/status` to the pipeline diagram

**Step 1: Locate the pipeline diagram**

Run:
```bash
grep -n "git-workflow" README.md | head -5
```

Find the line with ` ├─ /git-workflow` in the pipeline diagram.

**Step 2: Add `/status` entry**

The diagram currently shows:
```
 ├─ /quick [--deep]          # fast track — no pipeline, no artifacts
 ├─ /git-workflow             # git discipline — always available, standalone or via /build and /quick
 ├─ /init                    # project boilerplate — README, CHANGELOG, CONTRIBUTING, PR template
```

Add `/status` to the standalone skills group:
```
 ├─ /quick [--deep]          # fast track — no pipeline, no artifacts
 ├─ /git-workflow             # git discipline — always available, standalone or via /build and /quick
 ├─ /init                    # project boilerplate — README, CHANGELOG, CONTRIBUTING, PR template
 ├─ /status                  # inspect current pipeline phase — always available
```

### 10b — Add `/status` to Command Reference

**Step 3: Locate the last command reference section**

Run:
```bash
grep -n "^### /init" README.md
```

Insert a new `/status` section after `/init` (before `## Language Support Matrix`).

New section to insert:
```markdown
### /status — Pipeline State Check

**Gate:** None (always available)
**Writes:** nothing
**Model:** inherits from calling context

Reports the current pipeline phase based on which `.pipeline/` artifacts exist. Use at any point to check where you are in the pipeline.

```
/status
```

Output:
```
Pipeline status: [phase name]
  brief.md         ✓ exists
  design.md        ✗ missing
  ...
Next: Run /design
```

To reset the pipeline to a specific phase, see the `.pipeline/` State Directory section above.

---
```

### 10c — Verify no stale content

**Step 4: Check that /status appears in both places**

Run:
```bash
grep -c "/status" README.md
```
Expected: at least 3 matches (diagram, command reference header, body).

**Step 5: Commit**

```bash
git add README.md
git commit -m "docs: add /status to README — pipeline diagram and command reference"
```

---

## Summary of Commits

| Task | Commit message |
|------|---------------|
| 1 | `fix: clarify /qa subagent dispatch — explicit Skill invocations` |
| 2 | `fix: clarify /build dispatch — explicit pmatch invocation, model tiering, partial build resume` |
| 3 | `fix: /ar — explicit Opus model for strategic critic, clarify update design loop` |
| 4 | `fix: /qf and /qb — clarify TypeScript scope split, add remediation guidance` |
| 5 | `fix: /denoise — note /qb overlap for unused imports, add remediation guidance` |
| 6 | `fix: /security-review — add remediation guidance` |
| 7 | `fix: /qd — ground CHANGELOG check against plan.md, add remediation guidance` |
| 8 | `fix: /init — add pipeline orientation hint pointing to /arm` |
| 9 | `feat: add /status skill — pipeline state inspection, always available` |
| 10 | `docs: add /status to README — pipeline diagram and command reference` |

---
name: rollback
description: Use to undo a completed build. Reads .pipeline/plan.md to identify which files were created or modified by each task group, presents a checklist for confirmation, removes or restores confirmed files, and resets .pipeline/build.complete. Requires .pipeline/build.complete.
---

# ROLLBACK — Undo a Completed Build

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are acting as a rollback coordinator. Read what the build created or modified, confirm with the user which groups to roll back, then cleanly undo the changes.

## Hard Rules

1. **Never delete files without explicit per-group confirmation.** Always show the full file list first — never delete silently.
2. **Modified files get restored, not deleted.** For files that were modified (not created from scratch), use `git checkout -- [file]` to restore the pre-build state. Do not delete them.
3. **Never remove pipeline planning artifacts.** Do not remove `.pipeline/plan.md`, `.pipeline/design.md`, `.pipeline/brief.md`, or `.pipeline/design.approved`. Only `build.complete` is removed.

## Process

### Step 1: Check for completed build

Check for `.pipeline/build.complete`. If absent: "No completed build found to roll back." Stop.

### Step 2: Read the plan

Read `.pipeline/plan.md`. For each task group, extract:
- **Files: Create** entries → these files can be deleted
- **Files: Modify** entries → these files should be restored via `git checkout -- [file]`

If `.pipeline/plan.md` does not exist or has no file entries: "Cannot roll back — `.pipeline/plan.md` is missing or has no file entries. Remove `.pipeline/build.complete` manually if you want to re-run the build."

### Step 3: Present the rollback scope

Output the full file list grouped by task group:

```
Rollback scope:

Task Group 1 — [Name]
  Delete:   [file1], [file2]
  Restore:  [file3] (git checkout --)

Task Group 2 — [Name]
  Delete:   [file4]
  ...
```

Use AskUserQuestion with:
  question: "Which task groups should be rolled back?"
  header: "Rollback scope"
  options:
    - label: "All groups"
      description: "Roll back every task group listed above"
    - label: "Select specific groups"
      description: "Enter a comma-separated list of group numbers"
    - label: "Cancel"
      description: "Abort — make no changes"

If "Select specific groups": ask the user for the group numbers (one focused follow-up question).
If "Cancel": stop with "Rollback cancelled."

### Step 4: Execute rollback

For each confirmed task group:
- Delete each "Create" file using the Bash tool
- Run `git checkout -- [file]` for each "Modify" file

### Step 5: Remove build.complete

Run: `rm .pipeline/build.complete`

### Step 6: Report

Output:
```
Rollback complete.
  Deleted:  [N] files
  Restored: [N] files (via git checkout --)
  Removed:  .pipeline/build.complete

Pipeline state: plan-ready (.pipeline/plan.md exists, no build.complete)
```

### Step 7: Confirm next step

"Rollback complete. Run `/build` to re-execute the plan."

## Output

Files removed or restored. `.pipeline/build.complete` deleted. No other pipeline artifacts touched.

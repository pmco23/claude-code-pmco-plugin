---
name: rollback
description: Use to undo a completed build. Reads .pipeline/plan.md to identify which files were created or modified by each task group, presents a checklist for confirmation, removes or restores confirmed files, and resets .pipeline/build.complete. Requires .pipeline/build.complete.
disable-model-invocation: true
---

# ROLLBACK — Undo a Completed Build

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are acting as a rollback coordinator. Read what the build created or modified, confirm with the user which groups to roll back, then cleanly undo the changes.

## Hard Rules

1. **Never delete files without explicit per-group confirmation.** Always show the full file list first — never delete silently.
2. **Modified files get restored, not deleted.** For files that were modified (not created from scratch), back them up first, then use `git restore --source=HEAD --staged --worktree -- [file]`. Do not delete them.
3. **Never remove pipeline planning artifacts.** Do not remove `.pipeline/plan.md`, `.pipeline/design.md`, `.pipeline/brief.md`, or `.pipeline/design.approved`. Only `build.complete` is removed.
4. **Do not guess which local edits are safe to discard.** If the working tree has dirty files outside the selected rollback scope, stop and tell the user to commit or stash them first.
5. **Create a safety backup before changing anything.** Save the current contents of every selected file that still exists under `.pipeline/rollback-backups/<timestamp>/` before deleting or restoring it.
6. **Reject unsafe paths from the plan.** Normalize every plan-derived path against the project root before acting. If any path escapes the repository root, points into `.git/`, or targets protected pipeline planning artifacts, stop and report the blocked paths.

## Process

### Step 1: Check for completed build

Check for `.pipeline/build.complete`. If absent: "No completed build found to roll back." Stop.

### Step 2: Read the plan and inspect git state

Read `.pipeline/plan.md`. For each task group, extract:
- **Files: Create** entries → these files can be deleted
- **Files: Modify** entries → these files should be restored via `git restore --source=HEAD --staged --worktree -- [file]`

Normalize every extracted path against the project root before continuing. If any path is absolute, escapes the project root via `..`, points into `.git/`, or targets `.pipeline/brief.md`, `.pipeline/design.md`, `.pipeline/design.approved`, or `.pipeline/plan.md`, stop and list the blocked paths.

If `.pipeline/plan.md` does not exist or has no file entries: "Cannot roll back — `.pipeline/plan.md` is missing or has no file entries. Remove `.pipeline/build.complete` manually if you want to re-run the build."

Run:
- `git rev-parse --is-inside-work-tree`
- `git status --short`

If this is not a git repository and any task group contains **Files: Modify** entries, stop:
"Rollback blocked — modified files require a git repository so they can be restored safely."

For every **Files: Modify** entry, verify the path is tracked with `git ls-files --error-unmatch [file]`.
If any modify target is untracked or missing from git history, stop and list the blocked files.

### Step 3: Present the rollback scope and safety checks

Output the full file list grouped by task group:

```
Rollback scope:

Task Group 1 — [Name]
  Delete:   [file1], [file2]
  Restore:  [file3] (git restore --source=HEAD --staged --worktree)

Task Group 2 — [Name]
  Delete:   [file4]
  ...
```

Also show:
- The backup directory you will create: `.pipeline/rollback-backups/<timestamp>/`
- Any selected files that are already missing on disk (these are skipped, not treated as errors)
- A warning that restoring modified files discards the current contents of those files after the backup is taken

Prefer AskUserQuestion with:
  question: "Which task groups should be rolled back?"
  header: "Rollback scope"
  options:
    - label: "All groups"
      description: "Roll back every task group listed above"
    - label: "Select specific groups"
      description: "Enter a comma-separated list of group numbers"
    - label: "Cancel"
      description: "Abort — make no changes"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the user's answer.

If "Select specific groups": ask the user for the group numbers (one focused follow-up question), preferring AskUserQuestion and falling back to a concise plain-text question if needed.
If "Cancel": stop with "Rollback cancelled."

### Step 4: Safety preflight on the selected scope

Once the selected task groups are known, compare the selected file list against `git status --short`.

If any dirty tracked or untracked file exists outside the selected rollback scope, stop:
"Rollback blocked — unrelated working tree changes detected in [paths]. Commit or stash them before retrying."

### Step 5: Create safety backup

Create a timestamped backup directory:

```bash
mkdir -p .pipeline/rollback-backups/<timestamp>
```

For every selected file that still exists on disk, copy its current contents into the backup directory while preserving relative paths.

### Step 6: Execute rollback

For each confirmed task group:
- Delete each existing "Create" file using the Bash tool
- Run `git restore --source=HEAD --staged --worktree -- [file]` for each "Modify" file

Skip files that are already absent and report them as skipped.

### Step 7: Remove build.complete

Run: `rm .pipeline/build.complete`

### Step 8: Report

Output:
```
Rollback complete.
  Deleted:  [N] files
  Restored: [N] files (via git restore --source=HEAD --staged --worktree)
  Skipped:  [N] files already absent
  Removed:  .pipeline/build.complete
  Backup:   .pipeline/rollback-backups/<timestamp>/

Pipeline state: plan-ready (.pipeline/plan.md exists, no build.complete)
```

### Step 9: Confirm next step

"Rollback complete. Run `/build` to re-execute the plan."

## Output

Files removed or restored with a safety backup. `.pipeline/build.complete` deleted. Planning artifacts remain untouched.

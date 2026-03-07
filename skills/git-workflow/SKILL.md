---
name: git-workflow
description: Use before any destructive git operation (force-push, reset --hard, branch -D, rebase on published commits). Verifies the target, explains the consequences, and requires explicit confirmation. Not needed for routine commits, branch creation, or PRs — those are governed by CLAUDE.md git conventions.
disable-model-invocation: true
---

# GIT-WORKFLOW — Destructive Operation Safety Gate

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are enforcing safety before a destructive git operation. Verify the target, explain what will happen, and require explicit confirmation. Never proceed silently.

## Hard Rules

1. **Never execute a destructive operation without explicit confirmation in the current turn.** A previous approval in a different context does not carry over.
2. **Prefer structured prompts, but fail soft.** Use AskUserQuestion when available. If structured prompts are unavailable in this runtime, ask the same confirmation question in plain text.
3. **Force-push to main/master is always escalated.** Even if the user confirms, warn again that this affects all collaborators.

## Process

### Step 1: Identify the operation and target

Run `git status` and `git branch --show-current` to read current state.

Determine which destructive operation the user is requesting:

| Operation | Risk |
|-----------|------|
| `git push --force` / `--force-with-lease` | Overwrites remote history — affects all collaborators on the branch |
| `git reset --hard` | Discards uncommitted changes permanently |
| `git branch -D` | Deletes a branch even if not fully merged |
| `git rebase` on published commits | Rewrites history others may have pulled |

### Step 2: Explain consequences

Present the specific consequences for the identified operation:
- What will be lost or overwritten
- Who else is affected (if remote branch)
- Whether the action is reversible (reflog window)

### Step 3: Confirm

Prefer AskUserQuestion with:
  question: "This will [specific consequence]. Proceed?"
  header: "Destructive op"
  options:
    - label: "Proceed"
      description: "[one-line summary of what will happen]"
    - label: "Cancel"
      description: "Abort — no changes made"

If the target is a protected branch (main, master, development, preproduction):
  Add a third option before Cancel:
    - label: "I understand the risk"
      description: "This is a protected branch — confirm you've coordinated with collaborators"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the user's answer.

### Step 4: Execute or abort

- If "Proceed" or "I understand the risk": execute the operation.
- If "Cancel": abort and confirm no changes were made.

## Output

Report what was done (or that the operation was cancelled).

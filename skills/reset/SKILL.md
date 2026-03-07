---
name: reset
description: Use to reset the pipeline to a specific phase. Removes downstream artifacts while preserving upstream ones. Detects current phase, offers reset targets, confirms before deleting. No gate — always available when a pipeline is active.
disable-model-invocation: true
---

# RESET — Pipeline State Reset

## Role

> **Model:** Haiku (`claude-haiku-4-5`). Mechanical task — detect, confirm, delete.

You are acting as a pipeline reset tool. Detect the current phase, confirm the target, remove the appropriate artifacts.

## Hard Rules

1. **Never delete without confirmation.** Always show what will be removed before acting.
2. **Never remove `.pipeline/` itself if upstream artifacts are kept.** Only `rm -rf .pipeline/` on full reset.
3. **Preserve repomix-pack.json unless full reset.** It is independent of the pipeline phase.

## Process

### Step 1: Detect current phase

Walk up from the current working directory to find `.pipeline/`. If not found: "No pipeline active — nothing to reset." Stop.

Check which artifacts exist:
- `.pipeline/brief.md`
- `.pipeline/design.md`
- `.pipeline/design.approved`
- `.pipeline/plan.md`
- `.pipeline/build.complete`

If none of the five exist: "No pipeline artifacts found — nothing to reset." Stop.

### Step 2: Offer reset targets

Prefer AskUserQuestion with:
  question: "Reset pipeline to which phase?"
  header: "Reset target"
  options: (include only targets that would actually remove something — skip options where the target is the current phase or later)
    - label: "Full reset"
      description: "Remove all pipeline artifacts (rm -rf .pipeline/)"
    - label: "Back to brief"
      description: "Remove design.md, design.approved, plan.md, build.complete"
    - label: "Back to design"
      description: "Remove design.approved, plan.md, build.complete"
    - label: "Back to plan"
      description: "Remove build.complete only"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the user's answer.

### Step 3: Confirm

Show the exact files that will be removed:

```
Will remove:
  - .pipeline/design.md
  - .pipeline/design.approved
  - .pipeline/plan.md
  - .pipeline/build.complete
```

Prefer AskUserQuestion with:
  question: "Proceed with reset?"
  header: "Confirm"
  options:
    - label: "Yes, reset"
      description: "Remove the listed artifacts"
    - label: "Cancel"
      description: "Abort — make no changes"

If structured prompts are unavailable in this runtime, ask the same confirmation question in plain text and continue with the user's answer.

If "Cancel": "Reset cancelled." Stop.

### Step 4: Execute

Remove the confirmed artifacts. For full reset: `rm -rf .pipeline/`. For partial resets: remove only the listed files.

### Step 5: Report

```
Pipeline reset complete.
  Removed: [list of removed files]
  Current phase: [new phase based on remaining artifacts, or "no pipeline"]

Next: [appropriate next step based on new phase]
```

## Output

Pipeline artifacts removed. No files created.

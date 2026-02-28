---
name: status
description: Use at any time to check the current pipeline state. Reports which .pipeline/ artifacts exist and what phase the pipeline is in. No gate — always available.
---

# STATUS — Pipeline State Check

## Role

You are reporting the current pipeline phase to the user. Read the `.pipeline/` directory and provide a clear, one-glance summary.

## Process

### Step 1: Find the pipeline directory

Walk up from the current working directory looking for a `.pipeline/` directory. If none found, report "No pipeline active in this directory tree."

### Step 2: Check artifacts

For each artifact, check whether it exists:

| Artifact | Skill that writes it |
|----------|---------------------|
| `.pipeline/brief.md` | `/brief` |
| `.pipeline/design.md` | `/design` |
| `.pipeline/design.approved` | `/review` |
| `.pipeline/plan.md` | `/plan` |
| `.pipeline/build.complete` | `/build` |

### Step 3: Determine current phase

| Condition | Phase | Next step |
|-----------|-------|-----------|
| No artifacts | Not started | Run `/brief` |
| Only `brief.md` | Requirements crystallized | Run `/design` |
| `brief.md` + `design.md`, no `design.approved` | Design written, pending review | Run `/review` |
| `design.approved`, no `plan.md` | Design approved | Run `/plan` |
| `plan.md`, no `build.complete` | Plan ready / build in progress | Run `/build` |
| `build.complete` | Build complete | Run `/qa` |

### Step 4: Report

```
Pipeline status: [phase name]

  brief.md         [✓ exists | ✗ missing]
  design.md        [✓ exists | ✗ missing]
  design.approved  [✓ exists | ✗ missing]
  plan.md          [✓ exists | ✗ missing]
  build.complete   [✓ exists | ✗ missing]

Next: [next step]
```

## Output

Nothing written to `.pipeline/`. Report is output only.

To reset the pipeline to a specific phase, remove artifacts manually:
- Full reset: `rm -rf .pipeline/`
- Re-open from design: `rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete`
- Re-open from review: `rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete`
- Re-open from plan: `rm .pipeline/plan.md .pipeline/build.complete`
- Re-open from build: `rm .pipeline/build.complete`

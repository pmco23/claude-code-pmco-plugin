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

### Step 2: Check artifacts and ages

For each of the 5 pipeline artifacts, check whether it exists and, if so, read its **file modification time** to compute age from now:

| Artifact | Skill that writes it |
|----------|---------------------|
| `.pipeline/brief.md` | `/brief` |
| `.pipeline/design.md` | `/design` |
| `.pipeline/design.approved` | `/review` |
| `.pipeline/plan.md` | `/plan` |
| `.pipeline/build.complete` | `/build` |

Also check `.pipeline/repomix-pack.json`. If it exists, read the `packedAt` field (ISO timestamp) to compute age from now. Use `packedAt` rather than the file's mtime — `/pack` and `/qa` both write this field explicitly, so it reliably reflects when the pack was created regardless of filesystem timestamps.

**Age format:**

| Duration | Format | Example |
|----------|--------|---------|
| < 1 hour | `Nm old` | `23m old` |
| < 1 day | `Nh Nm old` | `2h 14m old` |
| ≥ 1 day | `Nd Hh old` | `3d 2h old` |

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

  brief.md         [✓ <age> | ✗ missing]
  design.md        [✓ <age> | ✗ missing]
  design.approved  [✓ <age> | ✗ missing]
  plan.md          [✓ <age> | ✗ missing]
  build.complete   [✓ <age> | ✗ missing]
  repomix-pack     [✓ <age> — <N> files, <N> tokens | ⚠ <age> — <N> files, <N> tokens (stale) | ✗ missing]

Next: [next step]
```

**repomix-pack row rules:**
- Age < 1 hour: `✓ <age> — <fileCount> files, <tokensAfter> tokens`
- Age ≥ 1 hour: `⚠ <age> — <fileCount> files, <tokensAfter> tokens (stale — run /pack to refresh)`
- File absent: `✗ missing`
- If `packedAt` is absent or not a valid ISO timestamp: treat as stale and display `⚠ age unknown — run /pack to refresh`
- If `fileCount` or `tokensAfter` are absent from the JSON: omit that field from the row (e.g. `✓ 23m old — 142 files` if only `tokensAfter` is missing)

## Output

Nothing written to `.pipeline/`. Report is output only.

To reset the pipeline to a specific phase, remove artifacts manually:
- Full reset: `rm -rf .pipeline/`
- Re-open from design: `rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete`
- Re-open from review: `rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete`
- Re-open from plan: `rm .pipeline/plan.md .pipeline/build.complete`
- Re-open from build: `rm .pipeline/build.complete`

---
name: status
description: Use at any time to check pipeline state and get next-step guidance. When no pipeline is active, shows available workflow options and paths. No gate — always available.
disable-model-invocation: true
---

# STATUS — Pipeline State Check

## Role

> **Model:** Haiku (`claude-haiku-4-5`). Haiku is sufficient for this task. Sonnet or Opus will also work.

You are reporting the current pipeline phase to the user. Read the `.pipeline/` directory and provide a clear, one-glance summary.

## Process

### Step 1: Find the pipeline directory

Walk up from the current working directory looking for a `.pipeline/` directory. If no `.pipeline/` directory is found, or if `.pipeline/` exists but none of the five pipeline artifacts (`brief.md`, `design.md`, `design.approved`, `plan.md`, `build.complete`) are present, output the **cold-start report** (see Step 4) and stop — do not proceed to Steps 2–3.

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
| Only `brief.md` | Requirements crystallized | Run `/design` |
| `brief.md` + `design.md`, no `design.approved` | Design written, pending review | Run `/review` |
| `design.approved`, no `plan.md` | Design approved | Run `/plan` |
| `plan.md`, no `build.complete` | Plan ready / build in progress | Run `/build` |
| `build.complete` | Build complete | Run `/qa` |

### Step 4: Report

Read `references/report-formats.md` from this skill's base directory. Use the cold-start report if no pipeline artifacts exist, or the pipeline report if artifacts are present. Follow the repomix-pack row rules and next-step prompt instructions from the same reference.

## Output

Nothing written to `.pipeline/`. Report is output only. See `references/report-formats.md` for manual pipeline reset commands.

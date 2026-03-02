# Documentation Cleanup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the completed `docs/plans/` directory, fix three outdated skill reference docs, fix one stale README comment, and deduplicate the walkthrough's reset section.

**Architecture:** Seven targeted file edits and one directory deletion. No code changes. Each task is independent; commit after each.

**Tech Stack:** Markdown, git

---

### Task 1: Delete docs/plans/

**Files:**
- Delete: `docs/plans/` (entire directory — 37 files including the design doc for this plan)

**Step 1: Delete the directory**

```bash
rm -rf docs/plans/
```

**Step 2: Verify it's gone**

```bash
ls docs/
```

Expected: `guides/  skills/` — no `plans/` directory.

**Step 3: Commit**

```bash
git add -A docs/plans/
git commit -m "chore: delete docs/plans/ — all plans completed and recorded in CHANGELOG"
```

---

### Task 2: Fix README.md — stale /git-workflow comment

**Files:**
- Modify: `README.md`

**Context:** The pipeline diagram comment for `/git-workflow` still says "standalone or via /build and /quick". Both `/build` and `/quick` were updated months ago to remove nested git-workflow calls. The comment is wrong.

**Step 1: Read the file**

Open `README.md` and locate the `/git-workflow` line in the Pipeline diagram (around line 12).

**Step 2: Make the edit**

Find:
```
 ├─ /git-workflow             # git discipline — always available, standalone or via /build and /quick
```

Replace with:
```
 ├─ /git-workflow             # git discipline — always available, standalone
```

**Step 3: Verify**

Read `README.md` lines 10-15. Confirm the updated comment and no other unintended changes.

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: fix README pipeline diagram — /git-workflow is standalone only"
```

---

### Task 3: Update docs/skills/review.md — name the strategic-critic agent

**Files:**
- Modify: `docs/skills/review.md`

**Context:** The `strategic-critic` named agent was introduced in a prior release. The skill reference still describes its model as "Opus (strategic critique)" without naming the agent.

**Step 1: Read the file**

Open `docs/skills/review.md` and locate the `**Models:**` frontmatter line.

**Step 2: Make the edit**

Find:
```
**Models:** Opus (strategic critique) + Codex via Codex MCP (code-grounded critique)
```

Replace with:
```
**Models:** `strategic-critic` agent (Opus) + Codex via Codex MCP (code-grounded critique)
```

**Step 3: Verify**

Read `docs/skills/review.md`. Confirm the Models line and no other unintended changes.

**Step 4: Commit**

```bash
git add docs/skills/review.md
git commit -m "docs: name strategic-critic agent in /review reference"
```

---

### Task 4: Update docs/skills/build.md — name the task-builder agent

**Files:**
- Modify: `docs/skills/build.md`

**Context:** The `task-builder` named agent was introduced in a prior release. The skill reference still describes builders as "Sonnet (builders)" without naming the agent.

**Step 1: Read the file**

Open `docs/skills/build.md` and locate the `**Models:**` frontmatter line.

**Step 2: Make the edit**

Find:
```
**Models:** Opus (lead) + Sonnet (builders)
```

Replace with:
```
**Models:** Opus (lead) + `task-builder` agent (Sonnet, per task group)
```

**Step 3: Verify**

Read `docs/skills/build.md`. Confirm the Models line and no other unintended changes.

**Step 4: Commit**

```bash
git add docs/skills/build.md
git commit -m "docs: name task-builder agent in /build reference"
```

---

### Task 5: Update docs/skills/drift-check.md — name the drift-verifier agent

**Files:**
- Modify: `docs/skills/drift-check.md`

**Context:** The `drift-verifier` named agent was introduced in a prior release. The skill reference still describes agent 1 as "Sonnet (agent 1)" without naming the agent.

**Step 1: Read the file**

Open `docs/skills/drift-check.md` and locate the `**Models:**` frontmatter line.

**Step 2: Make the edit**

Find:
```
**Models:** Sonnet (agent 1) + Codex via Codex MCP (agent 2) + Opus (lead)
```

Replace with:
```
**Models:** `drift-verifier` agent (Sonnet) + Codex via Codex MCP + Opus (lead)
```

**Step 3: Verify**

Read `docs/skills/drift-check.md`. Confirm the Models line and no other unintended changes.

**Step 4: Commit**

```bash
git add docs/skills/drift-check.md
git commit -m "docs: name drift-verifier agent in /drift-check reference"
```

---

### Task 6: Update docs/guides/walkthrough.md — deduplicate reset section

**Files:**
- Modify: `docs/guides/walkthrough.md`

**Context:** The walkthrough has a 3-case reset bash block. `workflows.md` has the complete 5-case version. The walkthrough's version is a partial duplicate — incomplete and divergent. Replace it with a one-line reference to `workflows.md`.

The `.pipeline/` directory reference above the reset block (artifact names, gitignore note) stays — that content is not in `workflows.md`.

**Step 1: Read the file**

Open `docs/guides/walkthrough.md` and locate the "To reset the pipeline" section (around line 25).

**Step 2: Make the edit**

Find this entire block:
```markdown
**To reset the pipeline** (start over from a specific phase):

```bash
# Reset everything — start fresh from /brief
rm -rf .pipeline/

# Re-open from design phase (keep brief, redo design forward)
rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete

# Re-open from review phase (keep design, redo /review forward)
rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete
```
```

Replace with:
```markdown
See [Workflows → Resetting to a prior phase](workflows.md#resetting-to-a-prior-phase) for reset commands.
```

**Step 3: Verify**

Read `docs/guides/walkthrough.md` in full. Confirm:
- The reset bash block is gone
- The new one-line reference is in its place
- The `.pipeline/` directory tree and gitignore note above it are untouched
- The End-to-End Walkthrough, Mode Flag Guide, and Language Support Matrix below are untouched

**Step 4: Commit**

```bash
git add docs/guides/walkthrough.md
git commit -m "docs: replace walkthrough reset section with link to workflows.md"
```

---

### Task 7: Remove stale plan reference from docs/guides/agents-vs-skills.md

**Files:**
- Modify: `docs/guides/agents-vs-skills.md`

**Context:** The last line of `agents-vs-skills.md` links to `docs/plans/2026-03-01-agents-vs-skills-design.md` — a file that no longer exists after Task 1.

**Step 1: Read the file**

Open `docs/guides/agents-vs-skills.md` and locate line 165 (the last line).

**Step 2: Make the edit**

Find:
```
For the full design discussion that produced this document, see `docs/plans/2026-03-01-agents-vs-skills-design.md`.
```

Delete this line entirely (including any trailing blank line above it).

**Step 3: Verify**

Read the last 5 lines of `docs/guides/agents-vs-skills.md`. Confirm the stale reference is gone and the document ends cleanly.

**Step 4: Commit**

```bash
git add docs/guides/agents-vs-skills.md
git commit -m "docs: remove stale plan file reference from agents-vs-skills.md"
```
